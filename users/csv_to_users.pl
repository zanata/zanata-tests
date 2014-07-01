#!/usr/bin/env perl

use utf8;
use Text::CSV;
my $csv = Text::CSV->new ( { binary => 1  })
    or die "Cannot use CSV: ".Text::CSV->error_diag ();
my $csvFile="UserModeling.csv";

my @headers=();


sub parse_header_row{
    my ($rowARef)=@_;
    my $arrSize=scalar @$rowARef;
    for(my $i=0; $i< $arrSize; $i++){
	if( $rowARef->[$i]){
	    if ($headers[$i]){
		$headers[$i].=" ". $rowARef->[$i];
	    }else{
		$headers[$i]=$rowARef->[$i];
	    }
	}
    }
}

sub parse_user_row{
    my ($rowARef)=@_;
    my $arrSize=scalar @$rowARef;
    my %user;
    for(my $i=0; $i< $arrSize; $i++){
	if( $rowARef->[$i]){
	    $user{$headers[$i]}=$rowARef->[$i];
	    print "$user:". $headers[$i]. "=". $rowARef->[$i] ."\n";
	}
    } 
}

open my $fh, "<:encoding(utf8)", $csvFile or die "$csvFil: $!";

my $index=0;
while ( my $row = $csv->getline( $fh ) ) {
    if ($index >=2){
	parse_user_row($row);
    }else{
	parse_header_row($row);
    }
    $index++;
}
$csv->eof or $csv->error_diag();
close $fh;

