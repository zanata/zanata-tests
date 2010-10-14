#!/usr/bin/env perl
# Get variable from a setting file
# And some utilities subroutines

# set_var_with_env(env_name, default_value)
sub set_var_with_env{
    my ($env_name, $default) = @_;
    return ($ENV{$env_name})? $ENV{$env_name}: $default;
}

sub find_program{
    my ($progName) = @_;
    my $_ret=`which ${progName} 2>/dev/null`;
    chomp $_ret;
    die "Error: ${progName} cannot be found is PATH!" unless $_ret;
    return $_ret;
}

sub is_current_apikey_valid(){
    my ($_apikey_file)=@_;
    if ( -e $_apikey_file){
	return 1;
    }
    return 0;
}




1;

