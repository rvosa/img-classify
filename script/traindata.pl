#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Fingerprint 'make_fingerprint';
use Bio::Phylo::Util::Logger ':levels';

# process command line arguments
my $verbosity = WARN;
my $resolution = 50;
my $dir;
my $category;
GetOptions(
	'category=i'   => \$category,
	'resolution=i' => \$resolution,
	'dir=s'        => \$dir,
	'verbose+'     => \$verbosity,
);

# instantiate helper objects
my $log = Bio::Phylo::Util::Logger->new(
	'-level' => $verbosity,
	'-class' => [ 'main', 'Fingerprint' ],
);

# print the header
print "image\t";
for my $axis ( qw(vert horiz) ) {
	for my $color ( qw(red green blue) ) {
		my $max = $axis eq 'horiz' ? $resolution / 2 : $resolution;
		for my $i ( 1 .. $max ) {
			print "${axis}.${color}.${i}\t";	
		}
	}
}
print "category\n";

# start reading the images
$log->info("going to read images from $dir");
opendir my $dh, $dir or die $!;
while( my $entry = readdir $dh ) {

	# only read png files created by splitter.pl
	if ( $entry =~ /(\d+,\d+)\.png/ ) {
		my $nucleus = $1;
		my @row = ( $nucleus );
		
		# read image
		my $img = Image::Magick->new;
		push @row, make_fingerprint( 
			'file'       => $dir . '/' . $entry,
			'resolution' => $resolution,
		);
		$log->info("created fingerprint for $entry");
		
		push @row, $category;
		print join("\t", @row), "\n";
	}	
}

