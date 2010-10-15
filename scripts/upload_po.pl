#!/usr/bin/env perl
# Import the sample project

use constant FLIES_PYTHON_CLIENT_EXE => "flies";
use constant FLIES_MAVEN_CLIENT_EXE => "mvn";
use constant PUBLICAN_EXE => "publican";

# Ensure it runs on RHEL5
use 5.008_008;

use strict;
# Get script location
my ($scriptDir)= ($0 =~ m|(.*)/|);
my ($myCmd)= ($0 =~ m|/([^/]*)$|);
require "${scriptDir}/manage_variable.pl";
my $currDir=`pwd`;
chomp $currDir;
my $logFile="${currDir}/${myCmd}.log";

my ($projDir, $proj, $version)=@ARGV;
chdir($projDir);
my @poFiles=<po/*.po>;
foreach my $poFile (@poFiles){
    print "         Uploading $poFile\n"
    system("${fliesPythonClient} publican push ${poFile} --project ${proj} --project-version ${version} >> ${logFile}");
}
chdir($currDir);

