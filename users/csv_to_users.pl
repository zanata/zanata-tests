#!/usr/bin/env perl

use strict;
use utf8;
use Test::WWW::Selenium;
use lib "../perl" ;
use Zanata::User qw(to_string);

die "Please specify environment ZANATA_URL\n" unless ($ENV{'ZANATA_URL'});
my $zanataUrl=$ENV{'ZANATA_URL'};
my $csvFile="UserModeling.csv";

my %defaultSeleniumAttrH = (
    host 		=> "localhost"
    , port              => 4444
    , browser           => "*firefox"
    , browser_url       => undef
    , default_names     => 1,
    , error_callback    => undef
);

sub selenium_init{
    my $attrHRef  = @_ > 0 ? shift : {};
    my %seleniumAttrH = %defaultSeleniumAttrH;

    for my $prop (keys %$attrHRef) { #
	$seleniumAttrH{$prop} = $attrHRef->{$prop};
    }
    return Test::WWW::Selenium->new( %seleniumAttrH);
}

my $sel=selenium_init({browser_url=> "$zanataUrl"});

my $userHRef=Zanata::User->new_from_csv($csvFile);
for my $username (sort (keys %$userHRef)){
    my $userRef=$userHRef->{$username};
    print $userRef->to_string(). "\n";
    $userRef->create_user($sel, $zanataUrl);
    exit 1;
}

