#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Image::Magick;
use List::Util 'sum';
use Bio::Phylo::Util::Logger ':levels';

# will have deep recursions 
no warnings 'recursion';

# process command line arguments
my $threshold = 0.7;
my $fuzzyness = 100; # pixels
my $verbosity = WARN;
my $infile;
GetOptions(
	'threshold=f' => \$threshold,
	'fuzzyness=i' => \$fuzzyness,
	'verbose+'    => \$verbosity,
	'infile=s'    => \$infile,
);

# instantiate helper objects
my $log = Bio::Phylo::Util::Logger->new(
	'-level' => $verbosity,
	'-class' => 'main',
);
my $img = Image::Magick->new;
my %seen;
my %area;

# read the image
$log->info("going to read image '$infile'");
my $msg = $img->Read($infile);
$log->warn($msg) if $msg;

# get width and height
my $width  = $img->Get('columns');
my $height = $img->Get('rows');
$log->info("width: $width height: $height");

# iterate over all pixels
for my $x ( 0 .. $width ) {
	for my $y ( 0 .. $height ) {
		my $nucleus = "$x,$y";
		recurse( 'x' => $x, 'y' => $y, 'nucleus' => $nucleus );
		if ( $area{$nucleus} ) {
			my $size = scalar @{ $area{$nucleus} };
			if ( $size > $fuzzyness ) {
				$log->info("found area of $size pixels around nucleus $nucleus");
			}
		}
	}
}

# write large areas
for my $nucleus ( grep { scalar @{ $area{$_} } > $fuzzyness } keys %area ) {
	my ($min_x) = sort { $a <=> $b } map { [ split(/,/, $_) ]->[0] } @{ $area{$nucleus} };
	my ($max_x) = sort { $b <=> $a } map { [ split(/,/, $_) ]->[0] } @{ $area{$nucleus} };	
	my ($min_y) = sort { $a <=> $b } map { [ split(/,/, $_) ]->[1] } @{ $area{$nucleus} };	
	my ($max_y) = sort { $b <=> $a } map { [ split(/,/, $_) ]->[1] } @{ $area{$nucleus} };
	
	# compute new area
	my $new_width  = $max_x - $min_x;
	my $new_height = $max_y - $min_y;
	$log->info("going to write $nucleus to ${new_width}x${new_height} file");
	
	# create new image, set dimensions, make white background
	my $new_img = Image::Magick->new( 'size' => "${new_width}x${new_height}" );
	$msg = $new_img->Read('xc:white');	
	$log->warn($msg) if $msg;
	$log->info("instantiated new image");
	
	# assign pixels
	for my $x ( 0 .. $new_width ) {
		for my $y ( 0 .. $new_height ) {
			my $loc = ( $x + $min_x ) . ',' . ( $y + $min_y );
			if ( $seen{$loc} ) {
				$msg = $new_img->SetPixel( 'x' => $x, 'y' => $y, 'color' => $seen{$loc} );
				$log->warn($msg) if $msg;
			}
		}
	}
	$log->info("assigned new pixels");
	
	# write image
	$msg = $new_img->Write("${nucleus}.png");
	$log->warn($msg) if $msg;
	$log->info("wrote image ${nucleus}.png");
}

sub recurse {
	my %args = @_;
	
	# get sub args
	my $nucleus   = delete $args{nucleus};
	my ( $x, $y ) = @args{qw(x y)};
	
	# sample the focal pixel
	my @pixel = $img->GetPixel(%args);
	
	# if pixel is darker than threshold and not yet seen...
	if ( sum(@pixel)/scalar(@pixel) < $threshold && ! $seen{"$x,$y"} ) {
		$log->debug("$x,$y");

		# store the pixel
		$seen{"$x,$y"} = \@pixel;
		
		# initialize area around current nucleus
		$area{$nucleus} = [] if not $area{$nucleus};
		
		# store id of the focal pixel
		push @{ $area{$nucleus} }, "$x,$y";
		
		# start growing the area
		if ( $x > 0 ) {
			recurse( 'x' => $x - 1, 'y' => $y, 'nucleus' => $nucleus );
		}
		if ( $y > 0 ) {
			recurse( 'x' => $x, 'y' => $y - 1, 'nucleus' => $nucleus );		
		}
		if ( $x < $width ) {
			recurse( 'x' => $x + 1, 'y' => $y, 'nucleus' => $nucleus );		
		}
		if ( $y < $height ) {
			recurse( 'x' => $x, 'y' => $y + 1, 'nucleus' => $nucleus );		
		}
	}
}
