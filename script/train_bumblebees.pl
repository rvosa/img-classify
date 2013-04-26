#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use AI::FANN ':all';
use List::Util qw'min max';
use Bio::Phylo::Util::Logger ':levels';

# process command line arguments
my $species;
my $table;
my $verbosity = WARN;
my $epochs    = 500000; # number of training generations for AI
my $printfreq = 1000;   # when the AI prints its progress during training
my $error     = 0.001;  # the acceptable error threshold for the AI
my $outfile   = 'ai.ann';
GetOptions(
	'verbose+'    => \$verbosity,
	'species=s'   => \$species,
	'table=s'     => \$table,
	'epochs=i'    => \$epochs,
	'printfreq=i' => \$printfreq,
	'error=f'     => \$error,
	'outfile=s'   => \$outfile,	
);

# instantiate helper objects
my $log = Bio::Phylo::Util::Logger->new(
	'-level' => $verbosity,
	'-class' => 'main',
);

# read the species list
my @species;
my %id;
my $outputs;
{
	$log->info("going to read species from $species");
	my $counter = 1;
	open my $fh, '<', $species or die $!;
	while(<$fh>) {
		chomp;
		if ( /\S/ ) {
			push @species, $_;
			$id{$_} = $counter++ if not $id{$_};
		}
	}
	$log->info("will process ".scalar(@species)." records for $counter species");
	$outputs = $counter;
}

# read the table
my @table;
my $inputs;
{

	$log->info("going to read digital phenotypes from $table");
	open my $fh, '<', $table or die $!;
	my $line = 1;
	while(<$fh>) {
		chomp;
		my @record = split /\s+/, $_;
		push @table, \@record;
		if ( not defined $inputs ) {
			$inputs = scalar @record;
		}
		else {
			if ( $inputs != scalar @record ) {
				$log->warn("unexpected number of records at line $line");
			}	
		}
		$line++;
	}
	$log->info("have read ".scalar(@table)." records");
	
	# now normalize that data over each column
	for my $col ( 0 .. $inputs - 1 ) {
		my @normalized = normalize( map { $_->[$col] } @table );
		for my $row ( 0 .. $#normalized ) {
			$table[$row]->[$col] = $normalized[$row];
		}		
	}
	$log->info("have normalized the records between -1 and 1");
}

# create the training data
my @traindata;
my %outofsample;
for my $i ( 0 .. $#species ) {
	my @output;
	my $speciesname = $species[$i];
	for my $j ( 1 .. $outputs ) {
		if ( $j == $id{$speciesname} ) {
			push @output, 1;
		}
		else {
			push @output, -1;
		}
	}
	if ( not $outofsample{$speciesname} ) {
		$outofsample{$speciesname} = $table[$i];
	}
	else {
		push @traindata, $table[$i], \@output;
	}
}
my $train = AI::FANN::TrainData->new(@traindata);

# create the AI
my $ai = AI::FANN->new_standard($inputs,$inputs+1,$outputs);
$ai->hidden_activation_function(FANN_SIGMOID_SYMMETRIC);
$ai->output_activation_function(FANN_SIGMOID_SYMMETRIC);
$ai->train_on_data($train,$epochs,$printfreq,$error);
$ai->save($outfile);
$log->info("saved AI to $outfile");

# now do the test
my ( $correct, $incorrect );
for my $speciesname ( keys %outofsample ) {
	$log->info("testing out-of-sample data for $speciesname");
	my $out = $ai->run($outofsample{$speciesname});
	$log->info("expected classifier: $id{$speciesname}");
	my $i = 1;
	my ($observed) = sort { $b->[0] <=> $a->[0] } map { [ $_ => $i++ ] } @{ $out };
	$log->info("observed: ".$observed->[1]. " (value: ".$observed->[0].")");
	if ( $id{$speciesname} == $observed->[1] ) {
		$correct++;
	}
	else {
		$incorrect++;
	}
}
print "Correct $correct Incorrect $incorrect\n";

sub normalize {
	my @data = @_;
	
	# compute min and max
	my $min = min @data;
	my $max = max @data;
		
	# here we do the scaling and return results
	my $scale = 2 / ( $max - $min );
	return map { ( ( $_ - $min ) * $scale ) - 1 } @data;
}