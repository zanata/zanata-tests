#!/usr/bin/env perl
# Usage: $0 [-p] <-s SCM> <pom.xml> [varablePrefix]

# Ensure it runs on RHEL5
use 5.008_008;
use strict;
use File::Basename;
use Getopt::Std;
use Pod::Usage;
use Data::Dumper;

my $modified=0;
my $scriptDir=dirname($0);

# Subroutines
sub print_usage {
    die <<END
Usage: $0 [-p] <-s SCM> <pom.xml> <varablePrefix>
    Generate a pom.xml for zanata
Options:
    pom.xml: The target xml to be generated.
    varablePrefix: variablePrefix to be used.
    -c: clean mode
    -s: SCM
    -p: Insert pluginRepositories
END
}

## Parse arguments
our($opt_c,$opt_s,$opt_p);
my %opts;
getopts("cps:", \%opts);
my $insertPluginRepository="";
if ($opts{'p'}){
    $insertPluginRepository="-p";
}

#print Dumper($opts);
unless ($opts{'s'}){
    print_usage;
    die "Please specify -s SCM";
}
unless (@ARGV >=2){
    print_usage;
    die "Not enough arguments";
}

my $pomXml=$ARGV[0];
my $varPrefix=$ARGV[1];

my $pomXml_in;

my $restore_file_opts="-s $opts{'s'} $pomXml";

if (system("$scriptDir/restore_file.sh -t $restore_file_opts")==0){
    $pomXml_in=$pomXml;
}else{
    $pomXml_in="$scriptDir/../pom.xml";
}

if ($opts{'c'}){
    # Clean mode
    unlink("$pomXml.stamp");
    system("$scriptDir/restore_file.sh $restore_file_opts");
}else{
    # Normal mode
    my $insert_zanata_opts="$insertPluginRepository $pomXml_in $pomXml $varPrefix";
    unless (system("$scriptDir/pomXml_insert_zanata.pl $insert_zanata_opts")==0){
	die "Failed generate $pomXml from $pomXml_in\n";
    }
    system("touch $pomXml.stamp");
}


