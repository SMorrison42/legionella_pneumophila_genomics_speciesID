#!/usr/bin/perl
use strict;
use warnings;

use Cwd;
use Getopt::Long;
use File::Basename;
#use Data::Dumper qw(Dumper);
use Pod::Usage qw (pod2usage);

my $mash_module = "Mash/2.0";

my $program_name = "Legionella Species ID Tool - Mash";

my $param_string = join (" ", @ARGV);

#  Fastq files to analyze
my $fastq1;
my $fastq2;


##  FASTA INPUT FUNCTIONALITY NOT SUPPORTED ON PORTAL
#  Fasta file to analyze.  All contigs in file are assumed to be same
#  species.  Incompatible with --fastqR1 and --fastqR2
my $fasta;

#  Replace with absolute path to mash sketch
my $mash_sketch = "/db/MASH_Legionella_master_sketch_2018-02-12_100k.msh";

## NOT SUPPORTED ON PORTAL
#  Save a concatenated version of fastq files.
# my $save_intermediate = '';

#  Maximum Mash dist to match a species
#		Note: 	Internal testing of Mash db shows the lowest Mash distance
#				obtained from a species mismatch is 0.06598.  Within
#				species matches can range up to 0.12299 (Legionella pneumophila)
#				so this distance represents a conservative definition of species
#				identification in the Legionella genus.		
my $max_dist = 0.05;

#  How many other results to display (including the best hit).  "0" shows only
#  best hit and eliminates results table entirely.  "-1" shows all results.
my $display = 5;

#  Display minimal report information.
my $quiet;

#  Display "help" and terminate;
my $help;

#  Threads to spawn
my $nthreads = 4;

#  Minimum number of times kmer must appear in fastq files to be included in sketch
my $min_copies;

GetOptions (	'fastq1:s' 			=> 	\$fastq1,
				'fastq2:s'			=>	\$fastq2,
				'fasta:s'			=>	\$fasta,
				'mash_sketch:s'		=>	\$mash_sketch,
# 				'save_intermediate'	=> 	\$save_intermediate,
				'max_dist:f'		=>	\$max_dist,
				'display:i'			=>	\$display,
				'quiet'				=>	\$quiet,
				'help'				=>	\$help,
				'nthreads:i'		=> 	\$nthreads,
				'min_copies:i'		=>	\$min_copies
															
			);
			
ValidateOptions ($fastq1, $fastq2, $fasta, $mash_sketch, $max_dist, $display, $quiet, $help, $nthreads, $min_copies);

#Print report field sizes for printf
my %field_lengths = (	"match_species_short"	=>	"20",
						"match_id"				=>	"20",
						"mash_dist"				=>	"8",
						"p-value"				=>	"5",
						"kmer_match_long"		=>	"15"
					);

my $start_time = GetTimeString();

my $result;
my $est_size;
my $est_coverage;

if (defined $fastq1 && defined $fastq2){
	#  Min Kmer copies overridden
	if (defined $min_copies) {
		my $cmd_string =  "cat $fastq1 $fastq2 | mash dist -r -p $nthreads -m $min_copies $mash_sketch -\r\n";
		$result = `$cmd_string`;
	}
	
	#  Find correct kmer copy number
	else {	
		#Est genome size and coverage are directed to STDERR, so capture that
		my $cmd_string =  "cat $fastq1 $fastq2 | mash dist -r -p $nthreads $mash_sketch - 2>&1 1>/dev/null";
		my $est_result = `$cmd_string`;
		
		if ($est_result =~ m/^WARNING: /m) {
			HandleMashWarning ($est_result);
		}
				
		$est_result =~ m/^Estimated genome size:\s+(.*)\nEstimated coverage:\s+(.*)\n/i;
		$est_size = $1;
		$est_coverage = $2;
		
# 		print "$est_result\r\n$est_size\t$est_coverage\r\n\r\n";
		
		#  Use 1/3 coverage as target for minimum kmer copies
		$min_copies = $est_coverage/3;
		#  Round up
		$min_copies = int ($min_copies + 0.5);
		if ($min_copies < 2) {
			$min_copies = 2;
		}
		
# 		print "$min_copies\r\n\r\n";		

		$cmd_string =  "cat $fastq1 $fastq2 | mash dist -r -m $min_copies -p $nthreads $mash_sketch - 2>&1";#/dev/null";
		$result = `$cmd_string`;
		if ($result =~ m/^WARNING: /m) {
			HandleMashWarning ($result);
		}
#  		print $result;							
	}
}
else {
	my $cmd_string = "mash dist -p $nthreads $mash_sketch $fasta";
	$result = `$cmd_string`;
	if ($result =~ m/^WARNING: /m) {
		HandleMashWarning ($result);
	}			
}

# print $result;
my $parsed_result = ParseResult($result);

WriteReport ($parsed_result, $fastq1, $fastq2, $fasta, $mash_sketch, $max_dist, $display, $quiet, $est_size, $est_coverage, $min_copies);


			
sub ValidateOptions {
	my $fastq1 = shift;
	my $fastq2 = shift;
	my $fasta = shift;
	my $mash_sketch = shift,
# 	my $save_intermediate = shift;
	my $max_dist = shift;
	my $display = shift;
	my $quiet = shift;
	my $help = shift;
	my $nthreads = shift;
	my $min_copies = shift;

	#  If --help was called, dump Usage info.	
	if (defined $help) {
		pod2usage(	-verbose	=>	2	);
	}

	#  Check that search files are specified correctly.
	unless ( (defined ($fastq1) && defined ($fastq2)) || defined ($fasta)) {
		print "Either two fastq files or 1 fasta file must be provided to conduct search.\r\n\r\n";
		pod2usage(	-verbose	=>	0	);;
	}
	if ( (defined ($fastq1) || defined ($fastq2)) && defined ($fasta)) {
		print "Either two fastq files or 1 fasta file must be provided to conduct search.\r\n\r\n";
		pod2usage(	-verbose	=>	0	);
	}

	
#  Disabled because "r" permission not available on instrument share		
# 	#  Check that search files exist
# 	if (defined $fastq1) {
# 		unless (TestFile ($fastq1, "r")) {
# 			pod2usage(	-verbose	=>	0	);
# 		}
# 	}			
# 	if (defined $fastq2) {
# 		unless (TestFile ($fastq2, "r")) {
# 			pod2usage(	-verbose	=>	0	);
# 		}
# 	}
# 	if (defined $fasta) {
# 		unless (TestFile ($fasta, "r")) {
# 			pod2usage(	-verbose	=>	0	);
# 		}
# 	}		

		
	#  Check that Mash sketch exists
	unless (TestFile ($mash_sketch, "r")) {
		pod2usage(	-verbose	=>	0	);
	}
	
	if ($nthreads < 1) {
		print "Invalid number of threads specified\r\n\r\n";
		pod2usage(	-verbose	=>	0	);
	}
	if (defined $min_copies) {
		if ($min_copies < 1) {
			print "Minimum kmer copies must be one or greater\r\n";
			pod2usage(	-verbose	=>	0	);
		}
		
	}
	
}	


sub TestFile {
	my $file = shift;
	my $permissions_code = shift;
	$permissions_code = lc $permissions_code;
	
	unless (-e $file) {
		print "$file Does not exist\r\n";
		return 0;
	}
	
	# In case multiple permissions are specified
	my @requested_permissions = split ('', $permissions_code);
	foreach my $permission (@requested_permissions) {
		# Check requested permission is actually a thing
		unless (($permission eq "r") || ($permission eq "w") || ($permission eq "x") ) {
			print "Invalid permission type \"$permission\" requested for file $file\r\n\r\n";
			return 0;
		}
		
		#Check permission - sadly it doesn't look like I can use a variable
		if ( $permission eq "r") {
			unless (-r $file) {
				print "\"$permission\" permission not available for $file\r\n\r\n";
				return 0;				
			}
		}
		elsif ( $permission eq "w") {
			unless (-w $file) {
				print "\"$permission\" permission not available for $file\r\n\r\n";
				return 0;
			}
		}
		elsif ( $permission eq "x") {
			unless (-x $file) {
				print "\"$permission\" permission not available for $file\r\n\r\n";
				return 0;
			}
		}				
	}
	return 1;
}

sub GetTimeString {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime();
	
	my @mon_array = qw (January February March April May June July August September October November December);
	
	my $mon_str = $mon_array[$mon];
	my $mon_num = $mon + 1; #Month returned in 0-11 range
	$year += 1900; #Year returned in years since 1900
	
	#Pad with zeros
# 	$mon = sprintf "%02s", $mon;
# 	$mday = sprintf "%02s", $mday;
	$hour = sprintf "%02s", $hour;
	$min = sprintf "%02s", $min;
	$sec = sprintf "%02s", $sec;
	
	my $ymd = "$year$mon$mday";
	my $mdy = "$mon_str $mday, $year";	
	my $hms = "$hour:$min:$sec";
	my $time_string = "$mdy at $hms GMT";
	return $time_string;
}
sub ParseResult {
	my $result = shift;
	my @lines = split ("\n", $result);
	my $results;
	foreach my $line (@lines) {
		if ($line =~ m/^Estimated/) {
			next;
		}
		my $fields = ParseCols($line);
		push (@$results, $fields);
	}
	
	my @sorted = sort {($a -> {"mash_dist"}) <=> ($b -> {"mash_dist"})} @$results;
	my $best = $sorted[0];
	return \@sorted;
}

sub ParseCols {
	my $line = shift;
	my $fields;
	
	my @cols = split ("\t", $line);
	my $basename = basename($cols[0]);
 	$basename =~ s/\s/_/g;	
	$basename =~ m/([^-]+)-(.+)/;
	my $match_species = $1;
	my $match_id = $2;
	$match_id =~ s/\.fas*$//;
	

	$fields -> {"match_species"} = $match_species;
	$fields -> {"match_species"} =~ s/_/ /g;
		
	$fields -> {"match_id"} = $match_id;
	
	my $match_species_short = ShortName($match_species);
	$fields -> {"match_species_short"} = $match_species_short;
	
	my $match_id_short = $match_species_short . " " . $match_id;
	$fields -> {"match_id_short"} = $match_id_short;
			
	$fields -> {"search_id"} = $cols[1];
	
	my $mash_distance = sprintf "%.6f", $cols[2];
	$fields -> {"mash_dist"} = $mash_distance;
	
	my $p_value = sprintf "%.3f", $cols[3];
	$fields -> {"p-value"} = $p_value;
	
	$fields -> {"kmer_match_long"} = $cols[4];
	
	$cols[4] =~ m/(\d+)\/(\d+)/;
	$fields -> {"kmer_match_short"} = $1;
	
	return $fields;
}
sub ShortName {
	my $long_name = shift;
	
	if ($long_name =~ m/Legionella_subs_pascullei/i) {
		$long_name = "Legionella_pneumophila";
	}
	
	$long_name =~ s/_/ /g;
	$long_name =~ m/^(.)[^ ]+ (.*)/;
	my $short_name = $1 . ". " . $2;
	
	if (length $short_name >  $field_lengths{"match_species_short"}) {
		$short_name = substr ($short_name, 0,  $field_lengths{"match_species_short"});
	}
	return $short_name;
}

sub WriteReport {
	my $parsed_result = shift;
	my $fastq1 = shift;
	my $fastq2 = shift;
	my $fasta = shift;
	my $mash_sketch = shift;
	my $max_dist = shift;
	my $display = shift;
	my $quiet = shift;
	my $est_size = shift;
	my $est_coverage = shift;
	my $min_copies = shift;	
	
	# Do "$quiet" result first so I don't have to test at every stage of output
	if ($quiet) {
		if ($parsed_result -> [0] -> {"mash_dist"} > $max_dist) {
			print "No matches found with distance < $max_dist\r\n";
			return 1;
		}
		else {
			PrintRow ($parsed_result -> [0]);
			return 1;
		}
	}
	else {
		PrintHeader ($fastq1, $fastq2, $fasta, $mash_sketch, $max_dist, $display, $quiet, $est_size, $est_coverage, $min_copies);
		PrintResult ($parsed_result);
		#PrintFooter ();
		return 1;
	}
}
								
	
sub PrintRow {
	my $result = shift;
	print "In silico Legionella Species ID Tool using Illumina MiSeq Paired Reads or Denovo Assemblies\n\n";
	print "In silico application Created By: Jason Caravas\n\n";
	print "Docker Container Developed By: Shatavia Morrison - 20200304\n\n";
	print "This is a NON-CLIA approved test\n\n\n";
	print "Results:\n";
	my $string;
	$string = StringLength ($result -> {"match_species_short"}, $field_lengths{"match_species_short"}, "R");
	print "$string   ";  #3 spaces
	$string = StringLength ($result -> {"match_id"}, $field_lengths{"match_id"}, "R");
	print "$string   ";  #3 spaces	
	$string = StringLength ($result -> {"mash_dist"}, $field_lengths{"mash_dist"}, "L");
	print "$string   ";  #3 spaces 
	$string = StringLength ($result -> {"p-value"}, $field_lengths{"p-value"}, "L");
	print "$string   ";  #3 spaces
	$string =  StringLength ($result -> {"kmer_match_long"}, $field_lengths{"kmer_match_long"}, "L");
	print "$string\r\n";
	return 1;
}

	
sub StringLength {
	my $value = shift;
	my $length = shift;
	my $lrpad = shift;
	

	
	$lrpad = uc $lrpad;
	
	if (length $value == $length) {
		return $value;
	} 	
	elsif (length $value < $length) {
		my $pad = $length - length $value;
		if ($lrpad eq "L") {
			my $fixed_value = " " x $pad;
			$fixed_value .= $value;
			return $fixed_value;
		}
		elsif ($lrpad eq "R") {
			my $fixed_value = " " x $pad;
			$fixed_value = $value . $fixed_value;
			return $fixed_value;
		}			
			
	}
	else {
		my $fixed_value = substr ($value, 0, $length);
		return $fixed_value;
	}
}
sub PrintHeader {
	my $fastq1 = shift;
	my $fastq2 = shift;
	my $fasta = shift;
	my $mash_sketch = shift;
	my $max_dist = shift;
	my $display = shift;
	my $quiet = shift;
	my $est_size = shift;
	my $est_coverage = shift;
	my $min_copies = shift;

	print "$program_name\r\n";
# 	print "Boilerplate usage text\r\n";
	print "Job started at $start_time\r\n";
	if (defined $fasta) {
		my $fasta_basename = basename($fasta);
		print "Fasta input query file:\r\n\t$fasta_basename\r\n";
	}
	else {
		my $fastq1_basename = basename($fastq1);
		my $fastq2_basename = basename($fastq2);				
		print "Fastq input query files:\r\n\t$fastq1_basename\r\n\t$fastq2_basename\r\n";
	}
	
	if (defined  $est_size) {
		print "Genome size estimate: $est_size bp\r\n";
	}
	else {
		print "Genome size estimate: Only available with fastq input\r\n";
	}
	
	if (defined  $est_coverage) {
		print "Genome coverage estimate: $est_coverage\r\n";
	}
	else {
		print "Genome coverage estimate: Only available with fastq input\r\n";
	}
	
	if (defined  $min_copies) {
		print "Minimum kmer copy number to be included in sketch: $min_copies\r\n";
	}
	else {
		print "Minimum kmer copy number to be included in sketch: 1\r\n";
	}
	
	print "\r\n";
	
}
sub PrintResult {
	my $parsed_results = shift;	
	if ($parsed_result -> [0] -> {"mash_dist"} > $max_dist) {
		print "Best species match: No matches found with distance < $max_dist\r\n";
	}
	else {
		print "Best species match: ". $parsed_result -> [0] -> {"match_species"}, "\r\n"; 
	}
	print "\r\n";
	
	if ($display == -1) {
		$display = () = keys %$parsed_results;
	}
	print "Top $display hits:\r\n";
	
	#Print col titles:
	my $string;
	$string = StringLength ("Species", $field_lengths{"match_species_short"}, "R");
	print "$string   ";  #3 spaces
	$string = StringLength ("Identifier", $field_lengths{"match_id"}, "R");
	print "$string   ";  #3 spaces	
	$string = StringLength ("Dist", $field_lengths{"mash_dist"}, "L");
	print "$string   ";  #3 spaces 
	$string = StringLength ("p", $field_lengths{"p-value"}, "L");
	print "$string   ";  #3 spaces
	$string =  StringLength ("Kmer Matches", $field_lengths{"kmer_match_long"}, "L");
	print "$string\r\n";
	$string = "\#" x 80;
	print "$string\r\n";

	for (my $i = 0; $i < $display; $i++) {
		PrintRow($parsed_results -> [$i]);
	}	
	return 1;
}

sub HandleMashWarning {
	my $result = shift;
	$result =~ s/\n/\r\n/g;
	print "Mash dist returned an error:\r\n\r\n";
	print "$result\r\n";
	print "Most errors are the result of very low ";
	print "sequence coverage in the uploaded fastq files (< 1x coverage) ";
	print "or corrupted input files.\r\n\r\n";
	print "If you believe you ecountered this message in error, ";
	print "please contact the OAMD Portal team\r\n";
	
	die;
}

=head1 NAME

Legionella Species Identification Tool - A tool for rapid identification of Legionella species.

=head1 SYNOPSIS

species_id_tool_v2.pl [options]

=head2 Options:

=over 15

=item C<-help>

Display help


=item C<-fasta>

Fasta file to be used as query

=item C<-fastq1>

Fastq file to be used as query

=item C<-fastq2>

Paired end fastq file to be used in query	

=item C<-mash_sketch>

User defined mash database to search

=item C<-max_dist>

Maximum Mash distance to return as a species match
		
=item C<-display>

Display this many detailed results (including best hit)

=item C<-quiet>

Supress all output except information for best match

=item C<-nthreads>

How many threads to run

=item C<-min_copies>

Override minimum kmer count

=back
		
=head1 OPTIONS

=over 15

=item C<-help>

Displays detailed help information

=item C<-fasta>

Specifies the provided fasta file as the query sequence.  
Incompatible with -fastq1/-fastq2.

=item C<-fastq1>
 
Specifies the provided fastq file as the query sequence.  
Incompatible with -fasta.  Can be used in conjunction with -fastq2 for paired end reads.

=item C<-fastq2>
 
Specifies the provided fastq file as paired end mate of a file provided with -fastq1.  
Incompatable with -fasta.

=item C<-mash_sketch>
 
Specifies the provided Mash sketch file as the sequence file to query against.

=item C<-max_dist>
 
The floating point value will be used as the cut-off to determine if 
a match is found in the sketch file or "no match" is returned.  Default value: 0.05.

=item C<-display>
 
Specifies the number of results to display in the report.  
Results are ranked from lowest Mash distance to highest.  
Superceded by -quiet.  Default value: 5.

=item C<-quiet>
 
Suppress all output except for the single lowest distance result.  
Potentially useful for batch mode operations to simplify output parsing.

=item C<-nthreads>
 
Specify the number of CPU threads to devote to Mash analysis.  Default value: 4.

=item C<-min_copies>
 
Suppress minimum kmer occurrence estimation and use the provided integer value as the cutoff.  
Default behavior: Execute Mash once to estimate genome coverage from read files, then re-execute 
Mash using 1/3rd of coverage estimate as the minimum number of occurences of a kmer in query 
fastq files.  this option has no effect if a fasta query is provided. 

=back		
		
=head1 DESCRIPTION

Submitted fasta of fastq sequence(s) are used as aquery against a Mash sketch file 
containing all whole and partial Legionella genus genomes available from public 
sources.  If a genome in the sketch file is less than 0.05 calculated distance
from the submittted unknown genome, the program will report that species as a 
best match.  Additional information about that match and the next best matches is
also provided.

In the case of fastq file submissions, a minimum kmer count of 1/3 estimated 
genome coverage is calculated and submitted to Mash (-m option of Mash).  This
number was empirically determined to give kmer recovery comparable to de novo
assembled fasta files derived from that fastq.   		

=cut

=head1 CAVEATS

This software is intended to provide a best guess as to the identity of an unknown 
Legionella genus sequence file.  While the search database is as complete as current 
knowledge provides, there is very little sequence data available from most 
non-pneumophila Legionella.  As such, testing of tool accuracy on these species 
was necessarily limited.

Furthermore, an estimation of within species diversity for many species was impossible.  
The identification cutoff provided represent what we believe to be a conservative cutoff
to confirm species identity, however we cannot predict that it will always give a 
satisfactory result.  

Lastly, it is important that the user read the match documentation carefully to 
understand the meaning of the Mash distance, the kmer identity, and provided p-value.

=head1 AUTHOR

Jason Caravas


=cut
