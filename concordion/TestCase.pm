#!/usr/bin/env perl

package TestCase;
use strict;
use XML::Twig;
## Needed to ensure XML::XPath is listed as a dependency.
use XML::XPath;
use XML::Twig::XPath;
use Cwd;
use utf8;
binmode STDOUT, ":encoding(UTF-8)";

sub new{
    my $hshRef= shift;

    my $self={};
    $self->{atts}={};

    if (defined $hshRef){
	while(my ($prop, $value)=each %$hshRef){
	    $self->{atts}->{$prop}=$value;
	}
    }
    bless $self;
    return $self;
}

sub set_child{
    my ($self,$tag,$text)=@_;
    if (defined $self->{children}->{$tag}){
	$self->{children}->{$tag}.= ",$text";
    }else{
	$self->{children}->{$tag}=$text;
    }
}

sub print{
    my $self=shift;
    print "testcases:";
    while(my ($k, $v)=each(%{$self->{atts}})){
	print " $k=$v";
    }
    print "\n";
    while(my ($k, $v)=each(%{$self->{children}})){
	print "\t$k=$v\n";
    }
    print "\n";
}

1;
