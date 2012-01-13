#!/usr/bin/env perl
# Usage: $0 <pom.xml.in> <pom.xml> [Var1=Value1 [Var2=Vale2] ...]

# Ensure it runs on RHEL5
use 5.008_008;
use strict;
use Getopt::Std;
use Pod::Usage;
use XML::Simple;
use Data::Dumper;

my $currDir=`pwd`;
chomp $currDir;
my $update=0;

sub print_usage {
    die <<END
generate_pom_xml.pl <original pom.xml> <pom.xml> [Var1=Value1 [Var2=Vale2] ...]
END
}

if (scalar(@ARGV)<2){
    print_usage;
}
my $pom_xml_in=$ARGV[0];
shift;
my $pom_xml=$ARGV[0];
shift;

my $OUT_FILE;

# Create XML object
my $xml=new XML::Simple;
my $data= $xml->XMLin($pom_xml_in);

# insert Zanata plugin if not exists
my $hasZanata=0;
my $pluginS= $data->{build}->{plugins}->{plugin};
foreach my $plugin (@{$pluginS}){
	if ($plugin->{groupId} ==  "org.zanata") {
	    $hasZanata=1;
	    last;
	}
}

if ($hasZanata==0){
    # Insert zanata plugin
    my $zanataPlugin=(
	"groupId" => "org.zanata"
	, "artifactId" =>  "zanata-maven-plugin",
	, "version" => '1.4.5-SNAPSHOT',
	, "configuration" => {
	    "srcDir" => '${zanata.srcDir}'
	     , "transDir" => '${zanata.transDir}'
	}
   );

   push(@{$pluginS}, $zanataPlugin);

}
print "hasZanata=$hasZanata\n";
print Dumper($pluginS);

#foreach my $tag (keys
#open(my $IN_FILE, "<$pom_xml_in") or die "Cannot open $pom_xml_in";
#my $buf="";
#while (my $line=<$IN_FILE>){
#    $buf=$buf . $line;
#}
#close($IN_FILE);

#foreach my $varStr (@ARGV){
#    my ($var, $val)=split(/=/,$varStr,2);
#    my $searchStr='@'. $var . '@';
#    $buf =~ s($searchStr)($val)g;
#}

#open(my $OUT_FILE, ">$pom_xml") or die "Cannot open $pom_xml";

#print $OUT_FILE "$buf";
#close($OUT_FILE);

