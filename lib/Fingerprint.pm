package Fingerprint;
use strict;
use warnings;
use Exporter;
use Image::Magick;
use List::Util qw[min max sum];
use Bio::Phylo::Util::Logger;
use base 'Exporter';

our @EXPORT_OK = qw(make_fingerprint);

# assuming 16-bit color depth
our $DEPTH = 65535;

my $log = Bio::Phylo::Util::Logger->new;

sub make_fingerprint {
	my %args = @_;
	my $file = $args{'file'};
	my $resolution = $args{'resolution'};
	
	# read image
	my $img = Image::Magick->new;
	$img->Read( $file );
	$log->info("read image $file");
	
	# get dimensions
	my $width  = $img->Get('columns');
	my $height = $img->Get('rows');	
	$log->info("width: $width height: $height");
	
	# find out which side is longest
	my $longest = $width > $height ? $width : $height;
	$log->info("longest axis is $longest pixels");
	
	# compute the increments in coordinates based on the resolution
	my $incr = $longest / $resolution;
	$log->info("will use increments of $longest/$resolution=$incr pixels");
	
	# we start in the middle column because of the lateral symmetry
	my $x_start = int( $width / 2 );
	$log->info("will assume lateral axis at x=$x_start");
	
	
	# will hold the "fingerprint" of the image. we will make a histogram of color
	# intensities along 1/2 of the x-axis (averaged in both directions opposite the
	# lateral axis) and the full length along the y-axis for the three colors that
	# comprise one pixel in an RGB image.
	my %record = (
		'horiz' => { 'red' => [], 'green' => [], 'blue' => [] },
		'vert'  => { 'red' => [], 'green' => [], 'blue' => [] },
	);
			
	# we have as many samples as $resolution
	my $xsample = 0;
	
	# jump columns in increments
	for ( my $x = $x_start + $incr; $x <= $x_start + $longest / 2; $x += $incr ) {		
		my $xprev = $x_start;
		my $yprev = 0;
		
		# jump rows in increments
		my $ysample = 0;
		for ( my $y = $incr; $y <= $longest; $y += $incr ) {
			my ( $xcoord, $ycoord ) = ( int $x, int $y );
			
			# compute average rgb over area
			my ( @r, @g, @b );
			for my $i ( $xprev .. $xcoord ) {
				for my $j ( $yprev .. $ycoord ) {
				
					# forward pixel
					my @pixel = $img->GetPixel( 
						'x' => $i, 
						'y' => $j,
						'normalize' => 0,
					);
					push @r, ( ( $pixel[0] || 0 ) / $DEPTH );
					push @g, ( ( $pixel[1] || 0 ) / $DEPTH );
					push @b, ( ( $pixel[2] || 0 ) / $DEPTH );
					
					# mirrored pixel
					my $mirror = $x_start - ( $i - $x_start );
					@pixel = $img->GetPixel( 
						'x' => $mirror, 
						'y' => $j,
						'normalize' => 0,							
					);
					push @r, ( ( $pixel[0] || 0 ) / $DEPTH );
					push @g, ( ( $pixel[1] || 0 ) / $DEPTH );
					push @b, ( ( $pixel[2] || 0 ) / $DEPTH );
				}
			}
			
			# calculate the averages
			my %pixel = (
				'red'   => sum(@r)/scalar(@r),
				'green' => sum(@g)/scalar(@g),
				'blue'  => sum(@b)/scalar(@b),
			);
			my %index = (
				'vert'  => $ysample,
				'horiz' => $xsample,
			);
			
			# store the sample				
			for my $axis ( keys %index ) {
				for my $color ( keys %pixel ) {
					my $index = $index{$axis};
					if ( not $record{$axis}->{$color}->[$index] ) {
						$record{$axis}->{$color}->[$index] = [];
					}
					push @{ $record{$axis}->{$color}->[$index] }, $pixel{$color};
				}
			}
			
			# cache next starting point for the area
			$xprev = $xcoord;
			$yprev = $ycoord;			
			$ysample++;
		}
		
		# increment the column sample counter
		$xsample++;	
	}
	
	# create the normalized fingerprint
	return normalize(%record, 'resolution' => $resolution );
}

sub normalize {
	my %record = @_;
	my $resolution = $record{'resolution'};
	my @row;
	for my $axis ( qw(vert horiz) ) {
		for my $color ( qw(red green blue) ) {
			my @values = map { ($_*2) - 1 } map { sum(@$_) / scalar(@$_) } @{ $record{$axis}->{$color} };
			
			# pad to make up for rounding errors
			while ( $axis eq 'horiz' and scalar(@values) < $resolution / 2 ) {
				push @values, 1;
			}				
			while ( $axis eq 'vert' and scalar(@values) < $resolution ) {
				push @values, 1;
			}				
			$log->info("collected ".scalar(@values)." $color samples along $axis axis");			
			push @row, @values;
		}
	}
	return @row;	
}