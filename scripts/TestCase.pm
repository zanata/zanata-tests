#!/usr/bin/env perl

package TestCase;
use strict;
use IPC::Run 'run';
use utf8;
binmode STDOUT, ":encoding(UTF-8)";

sub new{
    my ($id)=@_;
    my $self={};
    my $self->{id}=$id;
    my $self->{steps}=[];
    my $self->{children}={};
    bless $self;
    return $self;
}

sub add_step{
    my ($self,$desc, $cmd, $expectedList)=@_;
    my $step={};
    $step->{desc}=$desc;
    $step->{cmd}=$cmd;
    $step->{expected}=$expected;
    push @{$self->{steps}}, $step;
}

sub get_child{
    my ($self,$tag)=@_;
    return $self->{children}->{$tag};
}

sub set_child{
    my ($self,$tag,$text)=@_;
    if (defined $self->{children}->{$tag}){
	$self->{children}->{$tag}.= ";$text";
    }else{
	$self->{children}->{$tag}=$text;
    }
}

sub print{
    my $self=shift;
    print "testcase $self->{id}:\n";
    while(my ($k, $v)=each(%{$self->{children}})){
	print "\t$k=$v\n";
    }
    for(my $i=0;$i< @{$self->{steps}}; $i++){
	my $step=$self->{steps}[$i];
	print " " . $i+1 . ". " . $step->{desc}. "\n";
	print "    ". $step->{cmd} ."\n";
	print "    ". $step->{expected} ."\n";
    }
    print "\n";
}

sub execute{
    my $self=shift;
    for(my $i=0;$i< @{$self->{steps}}; $i++){
	my $step=$self->{steps}[$i];
	print " " . $i+1 . ". " . $step->{desc};
	run_step $step;
    }
}

sub execute_step{
    my $step=shift;
    my @cmd=qw( eval $step->{cmd} );
    my ($in, $out, $err);
    run \@cmd, \$in, \$out, \$err; 

    system("eval",$step->{cmd}")==0
	    or die "Failed command" . $step->{cmd} . "\n$?\n";

}

1;
