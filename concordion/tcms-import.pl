#!/usr/bin/env perl
# Import test cases from TCMS.

=pod

=head1 NAME

B<tcms-import.pl> - Convert TCMS test cases xml to Concordion

=head1 SYNOPSIS

B<tcms-import.pl> -h | --help

B<tcms-import.pl> [options] tcms-testcases.xml

=head1 DESCRIPTION

This program convert TCMS test cases xml files to
Concordion test cases.

=head1 ARGUMENTS

=over 4

=item tcms-testcases.xml

TCMS test case xml file.

=back

=head1 OPTIONS

=over 4

=item B<-h, --help>:

Print brief help message and exits.

=item B<-o, --output> outputDir:

Test case output directory.

=back

=cut

# Ensure it runs on RHEL5
use 5.008_008;
use strict;
use Getopt::Long;
use Pod::Usage;
## Needed to ensure XML::XPath is listed as a dependency.
use XML::XPath;
use XML::Twig::XPath;
use Cwd;
use lib ".";
use TCMS;
use TestCase;
use utf8;
binmode STDOUT, ":encoding(UTF-8)";

## Parse options
my $help=0;
my $outputDir='.';

GetOptions(
    'help|h' => \$help
    , 'output|o=s' => \$outputDir
) or pod2usage(-1);

### Display help
pod2usage(1) if $help;
pod2usage( {-verbose=>1}) if @ARGV == 0;

my $tcmsFile=shift;

die "Cannot read $tcmsFile $!" unless (-r $tcmsFile);

my $tcms=TCMS::new($tcmsFile);
my @testCases=@{$tcms->get_test_cases('asciidoc')};

unless (-e $outputDir){
    mkdir $outputDir;
}

foreach my $t (@testCases){
    my $summary=$t->{children}->{summary};
    $summary=~ s/[\(.*\)]/\1:/g;
    $summary=~ s/: /:/g;
    my $testCaseFile="$summary.txt";
    $testCaseFile=~ s/\s/_/g;
    $testCaseFile=~ s|/|-|g;

    if (-e $testCaseFile){
	print {*STDERR} "Test case $testCaseFile is already in $outputDir! Skipped.\n";
	next
    }

    open (my $fh,">","$outputDir/$testCaseFile" )
	or die "Cannot open $outputDir/$testCaseFile. $!";
    binmode $fh, ":encoding(UTF-8)";
    print $fh ":email: $t->{att}->{author}\n";
    print $fh ":revdate:\n";
    print $fh "\n";

    ## Print attributes
    print $fh "== attributes:\n";
    while(my ($k,$v)=each(%{$t->{atts}})){
	next if $k = "author";
	print $fh ":$k: $v\n";
    }

    foreach my $p (qw(testplan_reference categoryname component defaulttester)){
	print $fh ":$p: " . $t->{children}->{$p} . "\n";
    }

    ## Risk is also an attribute
    print $fh ":risk: \n";
    print $fh "\n";

    ## Print sections
    foreach my $s (qw(note setup expectedresults breakdown)){
	print $fh "== $s\n";
	print $fh $t->{children}->{$s} . "\n";
	print $fh "\n";
    }
    close $fh;
    print {*STDERR} "Test case $testCaseFile generated.\n";
    next
}
#$tcms->print;
