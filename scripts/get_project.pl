#!/usr/bin/env perl
# Ensure it runs on RHEL5
use 5.008_008;
use strict;
use Getopt::Std;
use Pod::Usage;
use File::Spec;
use LWP::Simple;
use Cwd;
use Archive::Tar;

my $currDir=getcwd;
my $update=0;

if ($ARGV[0] eq "-u"){
    $update=1;
    shift;
}

sub print_usage{
    print <<END
$0 - Download project
Usage: $0 [-u] proj ver scm url
Options:
    -u: Update mode
    proj: Project Id
    ver:  Project Version
    scm:  Project repoitory type. (Valid values: git, svn, tar)
    url:  Download/Clone URL of the project
END
}

die print_usage unless(@ARGV);

my ($proj, $ver, $scm, $url)=@ARGV;

my $projDir=$proj;
my $projVerDir=File::Spec->catfile($proj, $ver);

sub update_project{
    chdir($projVerDir) or die "Cannot change dir to $projVerDir: $!";

    if ($scm eq "git"){
	system(qq{git pull})
    }elsif($scm eq "svn"){
	system(qq{svn co})
    }elsif($scm eq "tar"){
	my $tarball=File::Spec->catfile('..', "$proj-$ver.$scm");
	#system(qq{wget -c -o $tarball $url});
    }
    chdir(File::Spec->catfile('..' , '..'));
}

sub clone_project{
    mkdir $proj unless ( -d $proj);
    chdir($proj) or die "Cannot change dir to $proj: $!";

    if ($scm eq "git"){
	system(qq{git clone $url $ver});
	unless ($ver eq "master"){
	    chdir($ver);
	    system(qq{git checkout origin/$ver --track -b $ver});
	    chdir('..');
	}
    }elsif($scm eq "svn"){
	system(qq{svn co $url $ver})
    }elsif($scm eq "tar"){
	my $tarball="$proj-$ver.$scm";
	#system(qq{wget -c -o $tarball $url});
	#mirror($url, $tarball);
	my $tar=Archive::Tar->new($tarball);
	$tar->extract();
	my @props=['name', 'prefix'];
	my $tarHRef=$tar->list_files( \@props);
	while(my ($key,$value)=each %$tarHRef){
	    print "key=$key value=$value\n";
	}
    }
    chdir('..');
}

###########################################################
# Main program
#
if ($update){
    ## Update mode
    if( -d $projVerDir){
	print "    ${projVerDir} exists. Updating...\n";
	update_project;
    }
}else{
    ## Clone mode
    unless( -d $projVerDir){
	print "    ${projVerDir} does not exist, Cloning.\n";
	clone_project;
    }
}

