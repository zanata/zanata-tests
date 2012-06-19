#!/usr/bin/env perl
# Ensure it runs on RHEL5
use 5.008_008;
use strict;
use Getopt::Std;
use Pod::Usage;
use File::Spec;
use Cwd;
use XML::LibXML;
use XML::LibXSLT;

sub HELP_MESSAGE{
    print <<END
    $0 - Convert CTest result to JUnit XML outout
    Usage:
	$0 [-h]
	$0 [-x xsltFile] [-o output.xml] <testDir>
    Options:
	-h: Show this help.
	-x xsltFile: xslt file for conversion.
	-o output.xml: Result is stored in output xml. Dump to stdout if this is not specified.
	testDir: The directory of test. Such as '.'
END
}

my $currDir=getcwd;
my ($volume,$scriptDir,$file) = File::Spec->splitpath( $0 );

my %optH={};
getopt("hx:o:", \%optH);
my $xsltFilename;
if (exists $optH{'x'}){
    $xsltFilename=abs_path($optH{'x'});
}else{
    $xsltFilename="$scriptDir/CTest2JUnit.xsl";
}

my $testDir=$ARGV[0];
unless($testDir){
    HELP_MESSAGE;
    exit(-1);
}

open(my $tagFile, "<", "$testDir/Testing/TAG")
    or die "cannot open " . "$testDir/Testing/TAG" . " : $!";

my @lines=<$tagFile>;
my $ctestXmlDir=$lines[0];
chomp $ctestXmlDir;
my $ctestXmlFilename="$testDir/Testing/$ctestXmlDir/Test.xml";

my $parser = XML::LibXML->new();
my $xslt = XML::LibXSLT->new();

my $source = $parser->parse_file($ctestXmlFilename);
my $style_doc = $parser->parse_file($xsltFilename);
my $stylesheet = $xslt->parse_stylesheet($style_doc);
my $results = $stylesheet->transform($source);

if (exists $optH{'o'}){
    my $outputXmlFilename=Cwd::abs_path($optH{'o'});
    open(my $outputXmlFile, ">", $outputXmlFilename)
	or die "cannot open $outputXmlFilename: $!";
    print $outputXmlFile $stylesheet->output_string($results);
    print "Output saved to $outputXmlFilename\n";
}else{
    print $stylesheet->output_string($results);
}
