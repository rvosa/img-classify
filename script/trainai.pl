#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use AI::FANN ':all';
use Bio::Phylo::Util::Logger ':levels';

# process command line arguments
my $verbosity = WARN;
my $epochs  = 50000;
my $target  = 0.0001;
my $datadir = 'data/traindata';
my $outfile = 'data/ai/butterbeetle.ann';
GetOptions(
	'verbose+'  => \$verbosity,
	'datadir=s' => \$datadir,
	'epochs=i'  => \$epochs,
	'target=f'  => \$target,
	'outfile=s' => \$outfile,
);

# instantiate helper objects
my $log = Bio::Phylo::Util::Logger->new(
	'-level' => $verbosity,
	'-class' => 'main',
);

# read the data files
my @interdigitated;
my $neurons;
$log->info("going to read traindata from $datadir");
opendir my $dh, $datadir or die $!;
while( my $entry = readdir $dh ) {
	if ( $entry =~ /\.tsv$/ ) {
	
		# read the table
		$log->info("going to read $datadir/$entry");
		open my $fh, '<', "$datadir/$entry" or die $!;
		my @header;
		LINE: while(<$fh>) {
			chomp;
			my @fields = split /\t/, $_;
			if ( not @header ) {
				@header = @fields;
				next LINE;
			}
			
			# first cell
			my $file = shift @fields;
			
			# last cell
			my $categ = pop @fields;
			
			# see AI::FANN docs for datastructure
			push @interdigitated, \@fields, [ $categ ];
			$neurons = scalar @fields; # +1 in hidden layer
			$log->info("read fingerprint for $file ($categ)");
		}
	}
}

# create the training data struct
my $train = AI::FANN::TrainData->new(@interdigitated);

# create the AI
my $ann = AI::FANN->new_standard( $neurons, $neurons + 1, 1 );
$ann->hidden_activation_function(FANN_SIGMOID_SYMMETRIC);
$ann->output_activation_function(FANN_SIGMOID_SYMMETRIC);

# train the AI
$ann->train_on_data( $train, $epochs, $epochs / 100, $target );

# save the result
$ann->save($outfile);