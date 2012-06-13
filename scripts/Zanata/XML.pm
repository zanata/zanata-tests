#!/usr/bin/env perl
# XML manipulate Package
#
package Zanata::XML;
use XML::Twig;
use File::Slurp;


## New xml_element from tag_name and content str
sub xml_element_new{
    my ($tagName, $contentStr)= @_;
    my $new_element= XML::Twig::XPath::Elt->new($tagName);
    if ($contentStr){
	$new_element->set_text($contentStr);
    }
    return $new_element;
}

sub xml_element_new_file{
    my ($tagName, $contentFile)= @_;
    return xml_element_new($tagName, File::Slurp::read_file($contentFile));
}

## New xml_element from xml string
sub xml_element_new_xml{
    my ($xmlStr)= @_;
    my $new_element= XML::Twig::XPath::Elt->parse($xmlStr);
    return $new_element;
}

sub xml_element_new_xml_file{
    my ($xmlFile)= @_;
    my $parser= XML::Twig::XPath->new( pretty_print=>'indented');
    my $doc=$parser->parsefile("$xmlFile");
    return $doc->root;
}

## Absolute path (/ppp/qqq) is needed
sub build_xpath{
    my ($twig, $xpath)= @_;
    my @paths=split /\//, $xpath;
    shift @paths;
    my $rootP= shift @paths;

    my $root=$twig->root;
    unless($root){
	my $newElt=XML::Twig::XPath::Elt->new($rootP);
	$twig->set_root($newElt);
	$root=$twig->root;
    }
    my $parent=$root;
    while(my $p=shift @paths){
	my $node=$parent->first_child($p);
	#print "p=$p node=$node \n";
	## Unless child exists
	unless($node){
	    ### Create new element
	    $node=XML::Twig::Elt->new("$p");
	    ### Paste new element as child to parent
	    $node->paste($parent);
	}
	## The new element is set as parent
	$parent=$node;
    }
}

1;
