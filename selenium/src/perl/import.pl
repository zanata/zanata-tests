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
print "FLIES_URL=|$ENV{FLIES_URL}|\n";

my $client=""
# has_project <proj_id> <cachefile>
sub has_project_python{
    my ($proj_id, $cachefile) = @_;
    if ($client eq "python"){
	my $_ret=`$flies_pytho_client list | grep -e "Id:\s*${proj_id}"`
	if ($_ret){
	    return 1;
	}
	return 0;
    }
}

sub is_current_apikey_valid(){
    my ($_apikey_file)=@_;
    if ( -e $_apikey_file){
	return 1;
    }
    return 0;
}


