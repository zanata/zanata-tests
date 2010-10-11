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

# Get script location
my ($scriptDir)= ($0 =~ m|(.*)/|);
my ($myCmd)= ($0 =~ m|/([^/]*)$|);
require "${scriptDir}/manage_variable.pl";
my $currDir=`pwd`;
chomp $currDir;
my $logFile="${currDir}/${myCmd}.log";

# opt map
my %opts=();
getopts("pa:", \%opts);
my $action=$opts{'a'};

sub VERSION_MESSAGE {
    my $fh = shift;
    print $fh "flies import script 0.1.0 \n";
}

sub HELP_MESSAGE{
    my $fh = shift;
    print $fh "Usage: $myCmd [-p] [-a action]\n";
    print $fh "Options: p: Use flies python client.\n";
    print $fh "         a: Perform only that action.\n";
}

my $fliesPythonClient="";
my $fliesMavenClient="";
if ($opts{'p'}){
    $fliesPythonClient=find_program(FLIES_PYTHON_CLIENT_EXE);
    die "&FLIES_PYTHON_CLIENT_EXE not found in PATH" unless $fliesPythonClient;
    chomp $fliesPythonClient;
}else{
    $fliesMavenClient=find_program(FLIES_MAVEN_CLIENT_EXE);
    die "&FLIES_MAVEN_CLIENT_EXE not found in PATH" unless $fliesMavenClient;
    chomp $fliesMavenClient;
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
my $errCode=0;

sub getSource{
    my ($proj, $ver) =@_;

    my $clone_action="";
    my $update_action="";
    if ($ENV{"${proj}_REPO_TYPE"} eq "git"){
	$clone_action="git clone";
	$update_action="git pull";
    }elsif($ENV{"${proj}_REPO_TYPE"} eq "svn"){
	$clone_action="svn co";
	$update_action="svn up";
    }

    # Download src
    my $slug=$ENV{"$proj"};
    my $projDir="$ENV{'SAMPLE_PROJ_DIR'}/$slug";

    if (-d ${projDir}){
	print "    ${projDir} exists, updating.\n";
	system("cd ${projDir}; $update_action");
    }else{
	print "    ${projDir} does not exist, clone now.\n";
	my $url=$ENV{"${proj}_URL"};
	$url=~ s/%\{ver\}/${ver}/g;
	print "url=${url}\n";
	system("$clone_action $url ${projDir}");
    }

    # Update pot
    unless( $action){
	chdir($projDir);
	# Remove brand
	if (system("grep -e 'brand:.*' publican.cfg")==0){
	    print "    Removing brand.\n";
	    system("mv publican.cfg publican.cfg.orig");
	    system("sed -e 's/brand:.*//' publican.cfg.orig > publican.cfg");
	}
	print "publicanCmd=${publicanCmd}\n";

	unless(-d "pot"){
	    print "    pot does not exist, update_pot now!\n";
	    system("${publicanCmd} update_pot >> ${logFile}");
	    system("touch pot");
	}

	if ((stat('publican.cfg'))[9] > (stat('pot'))[9]){
	    print "    publican.cfg is newer than pot, update_pot needed.\n";
	    system("${publicanCmd} update_pot >> ${logFile}");
	}

	system("$publicanCmd update_po --langs=\"$ENV{'LANGS'}\" >> ${logFile}");
	chdir($currDir);
    }

}

foreach my $pProj (@publicanProjects){
    my $slug=$ENV{"${pProj}"};
    print "Processing project ${slug}:".$ENV{"${pProj}_NAME"}. "\n";
    if (has_project(${pProj},"tmp0.html")){
	unless ($action){
	    print "  Flies already has this project, skip importing.\n";
	    next;
	}
	print "  Flies has this project, start ${action}.\n";
    }else{
	print "  Flies does not have this project, start importing.\n";
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

    my $projName=$ENV{"${pProj}_NAME"};
    my $projDesc=$ENV{"${pProj}_DESC"};

    # Create project
    unless($action){
create_project:
	print "   Creating project ${projName}\n";
	if ($fliesPythonClient){
	    #Python client
	    system("${fliesPythonClient} project create \"${slug}\" --name \"${projName}\" --description \"${projDesc}\" >> ${logFile}");
	}
	unless ( $? == 0){
	    print "Error occurs, skip following steps!\n";
	    next;
	}
    }

    # Create version
    unless($action){
create_version:
	my @vers=split /\s/, $ENV{"${pProj}_VERSION"};
	foreach my $ver (@vers){
	    print "   Creating ${projName} version $ver\n";
	    if ($fliesPythonClient){
		#Python client
		system("${fliesPythonClient} iteration create $ver --project \"${slug}\" --name \"Ver ${ver}\" --description \"Version ${ver}\" >> ${logFile}");
	    }

	    if ( $? == 0){
		getSource($pProj, $ver);
	    }else{
		print "Error occurs, skip following steps!\n";
		next;
	    }

	}


    }

}

