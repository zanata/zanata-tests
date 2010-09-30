#!/usr/bin/env perl
# Get variable from a setting file
# And some utilities subroutine

# set_var_with_env(env_name, default_value)
sub set_var_with_env{
    my ($env_name, $default) = @_;
    return ($ENV{$env_name})? $ENV{$env_name}: $default;
}

sub find_program{
    my ($progName) = @_;
    my $_ret=`which ${[progName} 2>/dev/null`
    die "Error: ${progName} cannot be found is PATH!" unless $_ret;
    return $_ret;
}




1;

