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
generate_pom_xml.pl <original pom.xml> <pom.xml> [projName] [Var1=Value1 [Var2=Vale2] ...]
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

if (scalar(@ARGV)<2){
    print_usage;
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


my %configH;

# fill in from configure file
my $BASE_DIR=".";
if ( defined $projName){
    my %cfgToPomKeys=(
	"BASE_DIR" => "baseDir"
	, "SRC_DIR" => "srcDir"
	, "TRANS_DIR" => "transDir"
	, "ENABLE_MODULES" => "enableModules"
	, "SKIP" => "skip"
	, "PROJECT_CONFIG" => "projectConfig"
    );

    foreach my $cfg ( keys %cfgToPomKeys){
	my $keyName=$projName . "_" . $cfg;
	if ( defined  $varH{$keyName}){
	    if ( $cfg eq "BASE_DIR"){
		$BASE_DIR=$varH{ $keyName};
	    }elsif ( $cfg eq "SRC_DIR"){
		$configH{$cfgToPomKeys{$cfg}}="$BASE_DIR/$varH{$keyName}";
	    }elsif ( $cfg eq "TRANS_DIR"){
		$configH{$cfgToPomKeys{$cfg}}="$BASE_DIR/$varH{$keyName}";
	    }elsif ( $cfg eq "ENABLE_MODULES"){
		if ($varH{$keyName} and ($varH{$keyName} !~ m/[Ff]alse/)){
		    $configH{$cfgToPomKeys{$cfg}}="true";
		}else{
		    $configH{$cfgToPomKeys{$cfg}}="false";
		}
	    }elsif ( $cfg eq "SKIP"){
		if ($varH{$keyName} and ($varH{$keyName} !~ m/[Ff]alse/)){
		    $configH{$cfgToPomKeys{$cfg}}="true";
		}else{
		    $configH{$cfgToPomKeys{$cfg}}="false";
		}
	    }else{
		$configH{$cfgToPomKeys{$cfg}}="$varH{$keyName}";
	    }
	}
    }
}

# Read var and corresponding value from command line
foreach my $varStr (@ARGV){
    my ($var, $val)=split(/=/,$varStr,2);
    $configH{$var}=$val;
}

if (keys( %configH ) == 0){
    $configH{'srcDir'} = '${zanata.srcDir}';
    $configH{'transDir'} = '${zanata.transDir}';
}

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
my $pluginA= \@{$data->{project}->[0]->{build}->[0]->{plugins}->[0]->{plugin}};
#print "pluginA=" . Dumper @{$pluginA} . "\n";

foreach my $plugin (@{$pluginA}){
    #print "plugin=" . Dumper($plugin) . "\n";
    #print "groupId=$plugin->{groupId}\n";
    if ($plugin->{groupId} eq  "org.zanata") {
	$hasZanata=1;
	last;
    }
}

if ($hasZanata == 0){
    # Insert zanata plugin
    my $zanataPlugin={(
	"groupId" => 'org.zanata'
	, "artifactId" =>  'zanata-maven-plugin'
	, "version" => $varH{'MVN_CLIENT_VER'}
	, "configuration" => { %configH }
   )};

   $modified=1;
   push(@{$pluginA}, $zanataPlugin);
}


# insert Zanata pluginRepositories if not exists
my $hasZanataPluginRepositories=0;

if (not defined $data->{project}->[0]->{pluginRepositories}){
    $data->{project}->[0]->{pluginRepositories}=[];
}
if (not defined $data->{project}->[0]->{pluginRepositories}->[0]->{pluginRepository}){
    $data->{project}->[0]->{pluginRepositories}->[0]->{pluginRepository}=[];
}

my $pluginRepos= \$data->{project}->[0]->{pluginRepositories}->[0]->{pluginRepository};

# Force to convert to array
if (ref(${$pluginRepos}) ne 'ARRAY'){
    ${$pluginRepos}= [ ${$pluginRepos} ];
}

foreach my $repo (@{${$pluginRepos}}){
    # print "repo=" . Dumper($repo) . "\n";
    # print "id=$repo->{id}\n";
    if ($repo->{id} =~ m/zanata/) {
	$hasZanataPluginRepositories=1;
	last;
    }
}

if ($hasZanataPluginRepositories==0){
    # Insert zanata plugin repositories
    my @zanataRepos=split(/;/,$varH{'ZANATA_MVN_REPOS'});

    foreach my $zRepoStr (@zanataRepos){
	my $zRepo={(
		'id' => $varH{"$zRepoStr" . "_ID"}
		, 'name' => $varH{"$zRepoStr" . "_NAME"}
		, 'url'=> $varH{"$zRepoStr" . "_URL"}
		, 'releases' => {
		    'enabled' => 'true'
		}
		,  'snapshots' => {
		    'enabled' => 'true'
		}
	)};
        $modified=1;
	push(@{${$pluginRepos}}, $zRepo);
    }
}

my $xml=$xs->XMLout($data
   , NoSort => 1
   , KeepRoot => 1
   , OutputFile=> $pom_xml
   , XMLDecl => 1
) or die "Cannot open $pom_xml";

system "touch $pom_xml.stamp";

