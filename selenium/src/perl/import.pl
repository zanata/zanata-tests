#!/usr/bin/env perl
# Import the sample projects
# Ensure it runs on RHEL5

use constant FLIES_PYTHON_CLIENT_EXE => "flies";
use constant FLIES_MAVEN_CLIENT_EXE => "mvn";
use constant PUBLICAN_EXE => "publican";
use 5.008_008;
use strict "vars";
use Getopt::Std;
use Pod::Usage;
use File::Path qw(make_path remove_tree);
sub VERSION_MESSAGE {
    my $fh = shift;
    print $fh "flies import script 0.1.0 \n";
}

sub HELP_MESSAGE{
    my $fh = shift;
    print $fh "Usage: $0 [-p] [-a action]\n";
    print $fh "Options: p: Use flies python client.\n";
    print $fh "         a: Perform only that action.\n";
}

# opt map
my %opts=();
getopts("pa:", \%opts);
my $action=$opts{'a'};

# Get script location
my ($scriptDir)= ($0 =~ m|(.*)/|);
require "${scriptDir}/manage_variable.pl";

my $fliesPythonClient="";
my $fliesMavenClient="";
if ($opts{'p'}){
    $fliesPythonClient=find_program(FLIES_PYTHON_CLIENT_EXE);
    die "&FLIES_PYTHON_CLIENT_EXE not found in PATH" unless $fliesPythonClient;
}else{
    $fliesMavenClient=find_program(FLIES_MAVEN_CLIENT_EXE);
    die "&FLIES_MAVEN_CLIENT_EXE not found in PATH" unless $fliesMavenClient;
}

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
	#print "enval=|${enval}| valret=|${valret}|\n";
    }
    $ENV{$envar}=${valret};
    #print "var=$envar valret=|${valret}|\n";
}
close IN;
$ENV{FLIES_URL} = $fliesUrl if $fliesUrl;
print "FLIES_URL=|$ENV{FLIES_URL}|\n";

my $publicanCmd= find_program(PUBLICAN_EXE);


# has_project <proj_id> <cachefile>
sub has_project{
    my ($proj_id, $cachefile) = @_;
    my $_ret="";
    if ($fliesPythonClient){
	$_ret=`$fliesPythonClient list | grep -e "Id:\s*${proj_id}"`
    }else{
    }
    if ($_ret){
	return 1;
    }
    return 0;
}

my $apikey="";
unless (is_current_apikey_valid("apikey.admin")){
    system("./get_apikey.sh");
}
open(KEYFILE, "apikey.admin");
$apikey=<KEYFILE>;
close(KEYFILE);

make_path($ENV{'SAMPLE_PROJ_DIR'});
unlink $ENV{'FILES_PUBLICAN_LOG'};

my @publicanProjects=split /\s/, $ENV{'PUBLICAN_PROJECTS'};
foreach my $pProj (@publicanProjects){
    print "Processing project ${pProj}:".$ENV{"${pProj}_NAME"}. "\n";
    if (has_project(${pProj},"tmp0.html")){
	unless ($action){
	    print "  Flies already has this project, skip importing.\n";
	    next;
	}
	print "  Flies has this project, start ${action}.\n";
    }

    my $clone_action="";
    my $update_action="";
    if ($ENV{"${pProj}_REPO_TYPE"} eq "git"){
	$clone_action="git clone";
	$update_action="git pull";
    }elsif($ENV{"${pProj}_REPO_TYPE"} eq "svn"){
	$clone_action="svn co";
	$update_action="svn up";
    }

    # Clone or update
    my $proj_dir="$ENV{'SAMPLE_PROJ_DIR'}/$pProj";
    unless( $action){
UPDATE_SRC:
	if (-d ${proj_dir}){
	    print "    ${proj_dir} exists, updating.\n";
	    system("cd ${proj_dir}; $update_action");
	}else{
	    print "    ${proj_dir} does not exist, clone now.\n";
	    system("$clone_action ". $ENV{"${pProj}_URL"} . " ${proj_dir}");
	}
    }

    # Remove brand
    unless( $action){
REMOVE_BRAND:
	if system('grep -e "brand:.*" publican.cfg'){
	    print "    Removing brand.\n"
	    system('mv publican.cfg publican.cfg.orig');
	    system("sed -e 's/brand:.*//' publican.cfg.orig > publican.cfg");
	}

    }

    if [ ! -d "pot" ]; then
    echo "    pot does not exist, update_pot now!"
    ${PUBLICAN_CMD} update_pot >> ${FLIES_PUBLICAN_LOG}
    touch pot
    fi

    if [ "publican.cfg" -nt "pot" ]; then
    echo "    "publican.cfg" is newer than "pot", update_pot needed."
    ${PUBLICAN_CMD} update_pot >> ${FLIES_PUBLICAN_LOG}
    fi

    ${PUBLICAN_CMD}  update_po --langs="${LANGS}" >> ${FLIES_PUBLICAN_LOG}

    _proj_name=$(eval echo \$${pProj}_NAME)
_proj_desc=$(eval echo \$${pProj}_DESC)
    fi


}

