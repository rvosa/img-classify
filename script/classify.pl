#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use AI::FANN ':all';
use Fingerprint 'make_fingerprint';
use Bio::Phylo::Util::Logger ':levels';

# process command line arguments
my $verbosity  = WARN;
my $resolution = 50;
my $dir;
my $ai;
GetOptions(
	'verbose+'     => \$verbosity,
	'dir=s'        => \$dir,
	'ai=s'         => \$ai,
	'resolution=i' => \$resolution,
);

# instantiate helper objects
my $log = Bio::Phylo::Util::Logger->new(
	'-level' => $verbosity,
	'-class' => 'main',
);
$log->info("going to instantiate AI from file $ai");
my $ann = AI::FANN->new_from_file($ai);

# read from the directory
$log->info("going to classify images in dir $dir");
opendir my $dh, $dir or die $!;
while( my $entry = readdir $dh ) {
	if ( $entry =~ /.png$/ ) {
		$log->debug("going to classify $entry");
		
		# analyse the input file
		my @fingerprint = make_fingerprint(
			'file'       => "$dir/$entry",
			'resolution' => $resolution,
		);
		$log->debug("made fingerprint of file");
		
		# do the classification
		my $result = $ann->run(\@fingerprint)->[0];
		if ( $result < 0 ) {
			$log->info("*** $entry is a beetle");
		}
		else {
			$log->info("*** $entry is a butterfly");
		}
	}
}