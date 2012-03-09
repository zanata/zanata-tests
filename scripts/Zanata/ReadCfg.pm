#!/usr/bin/env perl
# Package that reads Zanata configure file.
# Note this modules neither read zanata.ini nor zanata.xml
#
package Zanata::ReadCfg;

sub trim {
    $_[0]=~s/^\s+//;
    $_[0]=~s/\s+$//;
}

sub unquote {
    if ( $_[0]=~m/^\'/ ){
	if ( $_[0]=~m/\'$/ ){
	    $_[0]=~ s/^\'//;
	    $_[0]=~ s/\'$//;
	}
    }elsif ( $_[0] =~ /^\"/ ){
	if ( $_[0] =~ /\"$/ ){
	    $_[0]=~ s/^\"//;
	    $_[0]=~ s/\"$//;
	}
    }
}

sub expand_string {
    trim($_[0]);
    unquote($_[0]);
}


## hash_merge( templateHash_ref, supplementalHash_ref, mode )
sub hash_merge{
    my ($templateHash_ref, $supplementalHash_ref, $mode)=@_;
    # mode 0: supplemental override when value of corresponding key is empty
    # mode 1: supplemental override when
    if ($mode eq ""){
	$mode=0;
    }

    for my $key (keys %$templateHash_ref){
	if ($mode==0 and $templateHash_ref->{$key} ne ""){
	    next;
	}
	$templateHash_ref->{$key}=$supplementalHash_ref->{$key};
    }
}


## $hash_ref = read_file( inFile, isEnvOverride)
#
sub read_file{
    my ($inF, $isEnvOverride)=@_;
    if ( @_  < 2){
	$isEnvOverride=0;
    }
    my $varH_ref={};
    open(my $IN_FILE, "<$inF") or die "Cannot open $inF";
    while (my $line=<$IN_FILE>){
	next if $line =~ m/^\s*$/;
        next if $line =~  m/^\s*#/;
        chomp($line);
	my ($var, $val)=split(/=/,$line,2);
	expand_string($var);
	expand_string($val);
	if ($isEnvOverride and $ENV{$var} ne "" ){
	    # Env override mode
	    $varH_ref->{$var}=$ENV{$var};
	}else{
	    $varH_ref->{$var}=$val;
	}
    }
    close($IN_FILE);
    return $varH_ref;
}

1;
