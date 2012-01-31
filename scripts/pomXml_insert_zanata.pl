#!/usr/bin/env perl
# Usage: $0 <pom.xml.in> <pom.xml> [Var1=Value1 [Var2=Vale2] ...]

# Ensure it runs on RHEL5
use 5.008_008;
use strict;
use Getopt::Std;
use Pod::Usage;
use XML::Simple;
use Data::Dumper;
use File::Basename;
use File::Copy;

my $modified=0;
my $scriptDir=dirname($0);

# Subroutines
sub print_usage {
    die <<END
Usage: $0 [-p] <pom.xml.in> <pom.xml> <projName> [Var1=Value1 [Var2=Vale2] ...]
    Insert zanata data existing pom.xml

Options:
    -p: Insert pluginRepositories
    pom.xml.in: Input pom.xml
    pom.xml: Output pom.xml
END
}

sub trim {
    $_[0]=~s/^\s+//;
    $_[0]=~s/\s+$//;
}

sub unquote {
    if ( $_[0]=~m/^\'/ ){
	if ( $_[0]=~m/\'$/ ){
	    $_[0]=~ s/^\'//;
	    $_[0]=~ s/\'$//;
	}
    }elsif ( $_[0] =~ /^\"/ ){
	if ( $_[0] =~ /\"$/ ){
	    $_[0]=~ s/^\"//;
	    $_[0]=~ s/\"$//;
	}
    }
}

sub expand_string {
    trim($_[0]);
    unquote($_[0]);
}


# Add sub tag to a tag
# $_[0]: working tag
# $_[1]: subtag
# $_[2]: content
sub tag_add_subtag{
    #warn "_[0] is |$_[0]|";
    unless(defined $_[0]){
	$_[0]=> {};
    }
    unless(defined $_[0]{$_[1]}){
	$_[0]{$_[1]}=> [];
    }
    my $subTagA=\@{$_[0]{$_[1]}};
    push(@{$subTagA}, $_[2]);
}

if (scalar(@ARGV)<2){
    print_usage;
}

my $insertPluginRepository=0;

if ($ARGV[0] eq "-p"){
    $insertPluginRepository=1;
    shift;
}

my $pom_xml_in=$ARGV[0];
shift;

my $pom_xml=$ARGV[0];
shift;

if ( -e $pom_xml_in and ($pom_xml eq $pom_xml_in)){
    # Backup the old file.
    unless ( -e $pom_xml_in . ".orig"){
	$pom_xml_in= $pom_xml_in . ".orig" ;
	copy( $pom_xml, $pom_xml_in ) or die "Copy failed: $!";
    }
}

my $projName;
unless($ARGV[0] =~ m/=/){
    # Project name
    $projName=$ARGV[0];
    shift;
}

# Read vars from test.cfg
my $testCfg="$scriptDir/../test.cfg";
my %varH;
open(my $IN_FILE, "<$testCfg") or die "Cannot open $testCfg";
while (my $line=<$IN_FILE>){
    next if $line =~ m/^\s*$/;
    next if $line =~  m/^\s*#/;

    chomp($line);
    my ($var, $val)=split(/=/,$line,2);
    expand_string($var);
    expand_string($val);
    $varH{$var}=$val;
}
close($IN_FILE);
# print "varH=" . Dumper(%varH) . "\n";

# Override with environment value

if ( $ENV{'MVN_CLIENT_VER'} ne "" ){
    $varH{'MVN_CLIENT_VER'}=$ENV{'MVN_CLIENT_VER'};
}

my $buildConfig={};

# fill in from configure file
my $BASE_DIR="";
if ( defined $projName){
    my %cfgToPomKeys=(
	"BASE_DIR" => "baseDir"
	, "SRC_DIR" => "srcDir"
	, "TRANS_DIR" => "transDir"
	, "ENABLE_MODULES" => "enableModules"
	, "SKIP" => "skip"
	, "PROJECT_CONFIG" => "projectConfig"
	, "INCLUDES" => "includes"
	, "EXCLUDES" => "excludes"
    );

    foreach my $cfg ( keys %cfgToPomKeys){
	my $keyName=$projName . "_" . $cfg;
	if ( defined  $varH{$keyName}){
	    if ( $cfg eq "BASE_DIR"){
		$BASE_DIR=$varH{ $keyName};
	    }elsif ( $cfg =~ m{_DIR$}){
		tag_add_subtag($buildConfig,  $cfgToPomKeys{$cfg}, ($BASE_DIR) ? "$BASE_DIR/$varH{$keyName}": "$varH{$keyName}");
	    }elsif ( $cfg =~ m{ENABLE_} or $cfg eq 'SKIP'){
		if ($varH{$keyName} and ($varH{$keyName} !~ m/[Ff]alse/)){
		    tag_add_subtag($buildConfig,  $cfgToPomKeys{$cfg}, 'true');
		}else{
		    tag_add_subtag($buildConfig,  $cfgToPomKeys{$cfg}, 'false');
		}
	    }else{
		tag_add_subtag($buildConfig,  $cfgToPomKeys{$cfg}, $varH{$keyName});
	    }
	}
    }
}

# Read var and corresponding value from command line
foreach my $varStr (@ARGV){
    my ($var, $val)=split(/=/,$varStr,2);
    tag_add_subtag($buildConfig,  $var, $val);
}

if (keys(%$buildConfig) <= 0){
    tag_add_subtag($buildConfig, 'srcDir', '${zanata.srcDir}');
    tag_add_subtag($buildConfig, 'transDir', '${zanata.transDir}');
}

#print "buildConfig=$buildConfig content=" . Dumper($buildConfig) . "\n";

# Create XML object
my $xs=new XML::Simple;
my $data= $xs->XMLin($pom_xml_in
    , ForceArray => 1
    , ForceContent => 1
    , KeepRoot => 1
    , KeyAttr => []
    );

# insert Zanata plugin if not exists
my $hasZanata=0;
my $pluginS= \$data->{project}->[0]->{build}->[0]->{plugins}->[0];
my $pluginA=\@{${$pluginS}->{plugin}};
#print "pluginA=" . Dumper @{$pluginA} . "\n";

foreach my $plugin (@{$pluginA}){
    #print "plugin=" . Dumper($plugin) . "\n";
    if ($plugin->{groupId}->[0]->{content} eq  "org.zanata") {
	$hasZanata=1;
	last;
    }
}

if ($hasZanata == 0){
    # Insert zanata plugin
    my $zanataPlugin={};
    tag_add_subtag($zanataPlugin, 'groupId', 'org.zanata');
    tag_add_subtag($zanataPlugin, 'artifactId', 'zanata-maven-plugin');
    tag_add_subtag($zanataPlugin, 'version', $varH{'MVN_CLIENT_VER'});
    tag_add_subtag($zanataPlugin, 'configuration', $buildConfig);
    $modified=1;

    tag_add_subtag(${$pluginS}, 'plugin', $zanataPlugin);
}
#print Dumper(${$pluginS});

if ($insertPluginRepository){
   # insert Zanata pluginRepositories if not exists
    my $hasZanataPluginRepositories=0;

    unless(defined $data->{project}->[0]->{pluginRepositories}){
	$data->{project}->[0]->{pluginRepositories}=[];
    }

    unless(defined $data->{project}->[0]->{pluginRepositories}->[0]->{pluginRepository}){
	$data->{project}->[0]->{pluginRepositories}->[0]->{pluginRepository}=[];
    }

    my $pluginRepoS= \$data->{project}->[0]->{pluginRepositories}->[0];
    my $pluginRepoA= \@{${$pluginRepoS}->{pluginRepository}};

    foreach my $repo (@{$pluginRepoA}){
	#print "repo=" . Dumper($repo) . "\n";
	if ($repo->{id}->[0]->{content} =~ m/zanata/) {
	    $hasZanataPluginRepositories=1;
	    last;
	}
    }

    if ($hasZanataPluginRepositories==0){
	# Insert zanata plugin repositories
	my @zanataRepos=split(/;/,$varH{'ZANATA_MVN_REPOS'});
	my $enableTag={};
	tag_add_subtag($enableTag, 'enabled', 'true');

	foreach my $zRepoStr (@zanataRepos){
	    my $zRepo={};
	    tag_add_subtag($zRepo, 'id', $varH{"$zRepoStr" . "_ID"});
	    tag_add_subtag($zRepo, 'name', $varH{"$zRepoStr" . "_NAME"});
	    tag_add_subtag($zRepo, 'url', $varH{"$zRepoStr" . "_URL"});
	    tag_add_subtag($zRepo, 'releases', $enableTag);
	    tag_add_subtag($zRepo, 'snapshots', $enableTag);
	    $modified=1;
	    tag_add_subtag(${$pluginRepoS}, 'pluginRepository', $zRepo);
	}
    }
}

open my $fh, ">", "$pom_xml" or die "open($pom_xml): $!";

my $xml=$xs->XMLout($data
   , NoSort => 1
   , KeepRoot => 1
   , OutputFile=> $fh
   , XMLDecl => 1
) or die "Cannot open $pom_xml";

#print $fh, "$xml";
close($fh);

system "touch $pom_xml.stamp";

