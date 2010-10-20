#!/usr/bin/env perl
# Ensure it runs on RHEL5
use 5.008_008;
use strict;
my $currDir=`pwd`;
chomp $currDir;

my ($projBase, $proj, $projName, $projDesc, $ver, $scm, $url)=@ARGV;
my $projDir="$projBase/$proj";
my $clone_action="";
my $update_action="";

if ($scm eq "git"){
    $clone_action="git clone";
    $update_action="git pull";
}elsif($scm eq "svn"){
    $clone_action="svn co";
    $update_action="svn up";
}

# Download src
my @vers= split /\s/, $ver;


if (-d ${projDir}){
    print "    ${projDir} exists, updating.\n";
    system("cd ${projDir};$update_action");
}else{
    print "    ${projDir} does not exist, clone now.\n";
    system("$clone_action $url $projDir");
}



