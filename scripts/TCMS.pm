#!/usr/bin/env perl

package TCMS;
use strict;
use File::Slurp qw(read_file);
use XML::Twig;
use HTML::Entities;
## Needed to ensure XML::XPath is listed as a dependency.
use XML::XPath;
use XML::Twig::XPath;
use Cwd;
use utf8;
binmode STDOUT, ":encoding(UTF-8)";
use lib ".";
use TestCase;

sub new{
    my $file=shift;
    my $self={};
    my $self->{testCase}=[];
    my $content=read_file($file);

    my $twig=XML::Twig->new(
	pretty_print=>'indented'
    );
    $twig->parse($content);
    $twig->purge;

    bless $self;
    return $self;
}

sub load_file{
    my ($self, $file, $inputFilter, $outputer)=@_;
    my $content=read_file($file);

    my $twig=XML::Twig->new(
	pretty_print=>'indented'
    );
    $twig->parse($content);
    $twig->purge;
    
    foreach my $elt ($twig->getElementsByTagName('testcase')){
	while(my ($k, $v)=each(%{$self->{atts}})){
	    print "\t$k=$v\n";
	}

	for my $e ($elt->atts){

	}

	my $testCase=TestCase::new($elt->atts);
	for my $e ($elt->children()){
	    next unless $elt->is_elt;
	    my $text=$e->trimmed_text();
	    #print "text=$text\n";
	    if ( $format eq 'asciidoc'){
		$text=to_asciidoc($e);
	    }
	    $testCase->set_child($e->tag, $text);
	}
	push @{$self->{testCase}}, $testCase ;
    }


}

sub to_asciidoc_parsed{
    my $elt=shift;
    return "" unless ($elt->is_elt);
    my @children = $elt->cut_children();
    my $text="";
    my $counter=0;
    foreach my $child (@children){
	if ($child->is_elt){
	    ## Skip if no text inside
	    unless ($child->text){
		if ($child->tag eq "br"){
		    $text .= "\n";
		}else{
		    next;
		}
	    }

	    if ($child->tag eq "strong"){
		$text .= " *" . to_asciidoc_parsed($child) . "* ";
	    }elsif ($child->tag eq "em"){
		$text .= " _". to_asciidoc_parsed($child) . "_ ";
	    }elsif ($child->tag eq "p"){
		$text .= "\n". to_asciidoc_parsed($child) . "\n\n";
	    }elsif ($child->tag eq "br"){
		$text .= "+ \n";
	    }elsif ($child->tag eq "li"){
		if ($elt->tag eq "ol"){
		    $counter++;
		    $text .= "\n " . $counter . ". " . to_asciidoc_parsed($child);
		}else{
		    $text .= "\n * " . to_asciidoc_parsed($child);
		}
	    }elsif ($child->tag eq "ol"){
		$text .= "\n" . to_asciidoc_parsed($child) . "\n";;
	    }elsif ($child->tag eq "ul"){
		$text .= "\n" . to_asciidoc_parsed($child) . "\n";;
	    }elsif ($child->tag eq "h2"){
		$text .= "\n=== " . to_asciidoc_parsed($child) . "\n";
	    }elsif ($child->tag eq "h3"){
		$text .= "\n==== " . to_asciidoc_parsed($child) . "\n";
	    }elsif ($child->tag eq "h4"){
		$text .= "\n===== " . to_asciidoc_parsed($child) . "\n";
	    }elsif ($child->tag eq "table"){
		$text .= "\n|==================" . to_asciidoc_parsed($child)
		       . "\n-------------------"
		       . "\n|==================\n";
	    }elsif ($child->tag eq "tr"){
		$text .= "\n-------------------\n" . to_asciidoc_parsed($child);
	    }elsif ($child->tag eq "td"){
		$text .= "|" . to_asciidoc_parsed($child);
	    }elsif ($child->tag eq "tbody"){
		$text .=  to_asciidoc_parsed($child);
	    }elsif ($child->tag eq "div"){
		$text .= "\n" . to_asciidoc_parsed($child);
	    }elsif ($child->tag eq "span"){
		$text .= "\n" . to_asciidoc_parsed($child);
	    }elsif ($child->tag eq "pre"){
		$text .= "\n" . to_asciidoc_parsed($child);
	    }elsif ($child->tag eq "tt"){
		$text .= "+" . to_asciidoc_parsed($child).  "+";
	    }elsif ($child->tag eq "code"){
		$text .= "`" . to_asciidoc_parsed($child).  "`";
	    }elsif ($child->tag eq "pre"){
		$text .= "\n[literal]\n"
		. to_asciidoc_parsed($child) . "\n\n";
	    }elsif ($child->tag eq "a"){
		$text .= " " . $child->att('href') . "[" . to_asciidoc_parsed($child) . "] "
	    }else{
		$text .= "<" . $child->tag . ">" . to_asciidoc_parsed($child) ;
	    }
	}else{
	    $text .= $child->text;
	}
    }
    return $text;
}

sub to_asciidoc{
    my $elt=shift;
    if ($elt->tag eq "#PCDATA"){
	return "";
    }
    my $sTwig=XML::Twig->new();
    my $text=$elt->text;

    ## Escape the entities recognize by XML::Twig
    $text=~s |#gt;|#!gt;|g;
    $text=~s |&gt;|##gt;|g;
    $text=~s |#lt;|#!lt;|g;
    $text=~s |&lt;|##lt;|g;
    $text=~s |#amp;|#!amp;|g;
    $text=~s |&amp;|##amp;|g;
    $text=decode_entities($text);
    $text=~s |##gt;|&gt;|g;
    $text=~s |#!gt;|#gt;|g;
    $text=~s |##lt;|&lt;|g;
    $text=~s |#!lt;|#lt;|g;
    $text=~s |##amp;|&amp;|g;
    $text=~s |#!amp;|#amp;|g;

    #print "<" . $elt->tag . ">". $text . "</" . $elt->tag . ">\n";
    $sTwig->parse("<" . $elt->tag . ">". $text . "</" . $elt->tag . ">");
    return to_asciidoc_parsed($sTwig->root);
}

sub get_test_cases{
    my $self=shift;
    my $format=shift;
    my $twig=$self->{twig};
    my @testCases;
    foreach my $elt ($twig->getElementsByTagName('testcase')){
	my $testCase=TestCase::new($elt->atts);
	for my $e ($elt->children()){
	    next unless $elt->is_elt;
	    my $text=$e->trimmed_text();
	    #print "text=$text\n";
	    if ( $format eq 'asciidoc'){
		$text=to_asciidoc($e);
	    }
	    $testCase->set_child($e->tag, $text);
	}
	push @testCases, $testCase ;
    }
    return \@testCases;
}

sub print{
    my $self=shift;
    $self->{twig}->print;
}

1;
