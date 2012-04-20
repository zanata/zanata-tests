#!/usr/bin/env perl
# Ensure it runs on RHEL5
use 5.008_008;
use strict;
use Archive::Tar;
use Getopt::Std;
use Pod::Usage;
use File::Spec;
use Cwd;

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
my $stampFile=File::Spec->catfile($proj, $ver, "." . $scm);

sub update_project{
    chdir($projVerDir) or die "Cannot change dir to $projVerDir: $!";

    if ($scm eq "git"){
	system(qq{git pull})
    }elsif($scm eq "svn"){
	system(qq{svn co})
    }elsif($scm eq "tar"){
	my $tarball=File::Spec->catfile('..', "$proj-$ver.$scm");
	system(qq{wget -c -O $tarball $url});
    }
    chdir(File::Spec->catfile('..' , '..'));
}

sub clone_project{
    mkdir $proj unless ( -d $proj);
    chdir($proj) or die "Cannot change dir to $proj: $!";
    unless(-d $ver){
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
	    system(qq{wget -c -O $tarball $url});
	    my $tar=Archive::Tar->new($tarball);
	    my @fileL=$tar->list_files();
	    my $f=$fileL[0];

	    print "f=$f\n";
	    if ($f =~ m|/$|){
		# Extract in subdirectory
		$tar->extract();
		die "Cannot rename $f to $ver" unless rename($f, $ver);
	    }else{
		# Extract in current directory
		mkdir $ver;
		chdir $ver;
		$tar->extract();
		chdir '..';
	    }
	    my $stampFile=File::Spec->catfile($ver, "." . $scm);
	    open my $sF , ">", $stampFile;
	    close $sF;
	}
    }
    chdir('..');
}

###########################################################
# Main program
#
if ($update){
    ## Update mode
    if( -e $stampFile){
	print "    ${projVerDir} exists. Updating...\n";
	update_project;
	exit 0;
    }
}else{
    ## Clone mode
    unless( -e $stampFile){
	print "    ${projVerDir} is not ready, Cloning.\n";
	clone_project;
    }else{
	print "    ${projVerDir} is ready.\n";
    }
}

