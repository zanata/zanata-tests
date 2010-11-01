#!/usr/bin/env perl
# Ensure it runs on RHEL5
use 5.008_008;
use strict;
my $currDir=`pwd`;
chomp $currDir;

my ($projBase, $proj, $scm, $ver)=@ARGV;
my $projDir="$projBase/$proj";
my $switch_action="";

if ($scm eq "git"){
	$switch_action="git checkout $ver";
}elsif($scm eq "svn"){
	$switch_action="";
}

if (${switch_action}){
	print "      Switch to $ver\n";
	system("cd ${projDir};$switch_action");
}else{
	print "      One version, no need to switch.\n";
}

