#!/usr/bin/env perl
# Get variable from a setting file

# set_var_with_env(env_name, default_value)
sub set_var_with_env{
    my ($env_name, $default) = @_;
    return ($ENV{$env_name})? $ENV{$env_name}: $default;
}

1;

