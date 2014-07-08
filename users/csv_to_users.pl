#!/usr/bin/env perl

use strict;
use utf8;
use Test::WWW::Selenium;
use lib "../perl" ;
use Zanata::User qw(sign_in_static);

sub assert_environment_variable{
    my ($envName)=@_;
    die "Please specify environment $envName" unless ($ENV{$envName});
}

assert_environment_variable("ZANATA_URL");

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
    $userRef->{'url'}=$zanataUrl;
    print $userRef->to_yaml(). "\n";
    $userRef->create_user($sel);
}

assert_environment_variable("ZANATA_ADMIN_USERNAME");
assert_environment_variable("ZANATA_ADMIN_PASSWORD");

### Admin sign in
sign_in_static($sel, $zanataUrl, $ENV{ZANATA_ADMIN_USERNAME}, 
    $ENV{ZANATA_ADMIN_PASSWORD}, 3
);

for my $username (sort (keys %$userHRef)){
    my $userRef=$userHRef->{$username};
    $userRef->enabled_by_admin($sel,5);
    $userRef->set_lang_membership_by_coordinator($sel,5);
}

