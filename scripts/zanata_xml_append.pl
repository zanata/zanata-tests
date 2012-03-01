#!/usr/bin/env perl
# Usage: $0 <pom.xml.in> <pom.xml> [Var1=Value1 [Var2=Vale2] ...]

# Ensure it runs on RHEL5
use 5.008_008;
use strict;
use Getopt::Std;
use Pod::Usage;
use XML::LibXML;
use Data::Dumper;
use File::Basename;
use File::Copy;
use File::Slurp;

my $modified=0;
my $scriptDir=dirname($0);

# Subroutines
sub print_usage {
    die <<END
    Usage:
        $0 -h
        $0 [ -c <content_file> ] <input.xml> <parent_xpath> <tagName>
        $0 [ -x <content.xml>] <input.xml> <parent_xpath>
    Append an element to a parent node of an XML file.

    Options:
    -h: Display this help.
    -c content_file: Content text between a tag
    -x content.xml: XML file to be append as sub elements.
END
}


## Parse arguments
my %opts;
getopts("ec:x:", \%opts);
my $contentFile="";
my $contentXml="";


if ($opts{'h'}){
    print_usage;
    exit 0;
}

if ($opts{'x'}){
    $contentXml=$opts{'x'};
}

if ($opts{'c'}){
    $contentFile=$opts{'c'};
}

if (scalar(@ARGV)<2){
    print_usage;
    exit -1;
}

my $inputXml=$ARGV[0];
my $parentXpath=$ARGV[1];
my $tagName=$ARGV[2];

## Read xml
my $parser = XML::LibXML->new;
my $doc = $parser->parse_file("$inputXml");
my $root = $doc->getDocumentElement();

## Generate new element
my $new_element;
if ($opts{'x'}){
    my $subDoc = $parser->parse_file("$contentXml");
    $new_element = $subDoc->getDocumentElement();
}else{
    $new_element= $doc->createElement($tagName);
    if ($opts{'c'}){
	my $content= read_file($contentFile);
	$new_element->appendText($content);
    }
}

## Find the parent node
my @nodes=$root->findnodes($parentXpath);

## Append to all the parent node.
foreach my $node (@nodes){
    $node->appendChild($new_element);
}
print $root->toString();

#$root->appendChild($new_element);
#print $root->toString(1);

