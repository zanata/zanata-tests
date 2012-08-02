#!/usr/bin/env perl
# Ensure it runs on RHEL5
use 5.008_008;
use strict;
use Archive::Extract;
use URI;
use Getopt::Std;
use Pod::Usage;
use File::Copy;
use File::Path;
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

my $uri = URI->new($url);
my $tarball;
if ($scm eq "tar"){
    my $uriPath=$uri->path;
    my ($volume,$directories,$file) = File::Spec->splitpath( $uri->path );
    $tarball= $file;
}
print "tarball=$tarball\n";

sub extract_tarball{
    my ($tarball) =@_;
    my $ae=Archive::Extract->new(archive=>$tarball);
    print "ae->type=" . $ae->type . "\n";
    my $verTmpDir="${ver}-tmp";
    mkdir $verTmpDir;
    chdir $verTmpDir;
    $ae->extract();

    ## Determine whether the archive extract to current dir.
    my $extractInCurrent=0;
    my $topDir='';
    my @fileList=@{$ae->files};
    foreach my $p (@fileList){
	my ($v,$d,$f) = File::Spec->splitpath( $p );
	#print "p=$p d=$d f=$f topDir=$topDir extractInCurrent=$extractInCurrent\n";
	if ($d){
	    if ($topDir){
		if ($d =~ m!^$topDir!){
		}else{
		    $topDir='';
		    $extractInCurrent=1;
		    last;
		}
	    }else{
		$topDir=$d;
	    }
	}else{
	    $topDir='';
	    $extractInCurrent=1;
	    last;
	}
    }

    if ($extractInCurrent){
	# Extract in current directory
	chdir '..';
	move($verTmpDir, $ver)
    }else{
	# Files extracted to subdirectory
	die "Cannot rename $topDir to $ver" unless move($topDir,
	    "../$ver");
	chdir '..';
	rmtree($verTmpDir);
    }
}

sub touch_stamp_file{
    my $stampFile=File::Spec->catfile($ver, "." . $scm);
    open my $sF , ">", $stampFile;
    close $sF;
}

sub update_project_tar{
    system(qq{wget -c -O $tarball $url});
    extract_tarball($tarball);
    touch_stamp_file;
}

sub update_project{
    chdir($projVerDir) or die "Cannot change dir to $projVerDir: $!";

    if ($scm eq "git"){
	system(qq{git pull})
    }elsif($scm eq "svn"){
	system(qq{svn co})
    }elsif($scm eq "tar"){
	update_project_tar;
    }
    chdir($currDir);
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
	    update_project_tar;
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

