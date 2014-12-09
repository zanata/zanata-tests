#!/usr/bin/env perl
use FindBin qw($Bin);
use lib "$Bin";

use TestCase;
my $cmd1="echo \"Hi\"";
my $cmd2="echo \"Hi\" | grep \"yo\"";

my $tc=TestCase::new(test);
$tc->add_step("Test minimal create project"
     , $cmd1
     , "Expected"
);

$tc->add_step("Test full create project"
     , $cmd2
     , "Expected"
);

$tc->print;

