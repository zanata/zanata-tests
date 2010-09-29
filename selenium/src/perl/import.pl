#!/usr/bin/env perl
# Import the sample projects
# Ensure it runs on RHEL5
use 5.008_008;
use strict "vars";
# Get script location
my ($scriptDir)= ($0 =~ m|(.*)/|);
require "${scriptDir}/manage_variable.pl";

my $fliesUrl=set_var_with_env('FLIES_URL');
my $TEST_CONFIG_FILE=set_var_with_env('TEST_CONFIG_FILE','./test.cfg');
print "TEST_CONFIG_FILE=${TEST_CONFIG_FILE}\n";

# Load config file
open IN, "<", "${TEST_CONFIG_FILE}" or die "Test config file ${TEST_CONFIG_FILE} not found!\n";
while ( <IN> ) {
    chomp;
    next if ($_ eq "");
    next if /^#/;
    #print "line=|$_|\n";
    my ($envar,$enval) = split /=/,$_,2;
    my $valret=$enval;
    if ($valret =~ s/^"(.*)"$/$1/ ){
	$valret =~ s/\$\{([^{]*)\}/$ENV{$1}/g ;
	print "enval=|${enval}| valret=|${valret}|\n";
    }
    $ENV{$envar}=${valret};
    print "var=$envar valret=|${valret}|\n";
}
close IN;
$ENV{FLIES_URL} = $fliesUrl if $fliesUrl;
print "BASE_URL=$ENV{BASE_URL}\n";
print "FLIES_PATH=$ENV{FLIES_PATH}\n";
print "FLIES_URL=|$ENV{FLIES_URL}|\n";
print "RESULT_DIR=$ENV{RESULT_DIR}\n";
print "HTTP404_CHECK_RESULT=$ENV{HTTP404_CHECK_RESULT}\n";


