#!/usr/bin/env perl
# Usage: $0 <pom.xml.in> <pom.xml> [Var1=Value1 [Var2=Vale2] ...]

# Ensure it runs on RHEL5
use 5.008_008;
use strict;
use Getopt::Std;
use Pod::Usage;

my $currDir=`pwd`;
chomp $currDir;
my $update=0;

sub print_usage {
    die <<END
generate_pom_xml.pl <pom.xml.in> <pom.xml> [Var1=Value1 [Var2=Vale2] ...]
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
open(my $IN_FILE, "<$pom_xml_in") or die "Cannot open $pom_xml_in";
my $buf="";
while (my $line=<$IN_FILE>){
    $buf=$buf . $line;
}
close($IN_FILE);

foreach my $varStr (@ARGV){
    my ($var, $val)=split(/=/,$varStr,2);
    my $searchStr='@'. $var . '@';
    $buf =~ s($searchStr)($val)g;
}

open(my $OUT_FILE, ">$pom_xml") or die "Cannot open $pom_xml";

print $OUT_FILE "$buf";
close($OUT_FILE);

