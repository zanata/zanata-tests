#!/usr/bin/env perl
# http404_check.perl <inDir> <outFile> <urlprefix>

#if ($#ARGV !=2){
#    print 'Usage: http404_check.perl <inDir> <outFile> <urlprefix>';
#    exit(1);
#}

$FLIES_URL=$ENV{'FLIES_URL'};
if ($FLIES_URL eq ""){
    die 'Please source test.cfg and make sure it has FLIES_URL!'
}

$PRIVILEGE_TEST_ROOT=$ENV{'PRIVILEGE_TEST_ROOT'};
if ($PRIVILEGE_TEST_ROOT eq ""){
    die 'Please source test.cfg and make sure it has PRIVILEGE_TEST_ROOT!'
}

$HTTP404_CHECK_RESULT=$ENV{'HTTP404_CHECK_RESULT'};
if ($HTTP404_CHECK_RESULT eq ""){
    die 'Please source test.cfg and make sure it has HTTP404_CHECK_RESULT!'
}


open(OUTFILE, ">$HTTP404_CHECK_RESULT");
$failed=0;
$passed=0;

sub read_line{
    local($line)=($_[0]);
    local($type,$url)=split(' ', $line);
#    print "\tTYPE=$type, URL=$url\n";
    if ($type eq "HTTP404"){
	local(@ret)=(`curl --silent --dump-header /dev/stdout "$FLIES_URL$url"`);
	if ( $ret[0] =~ m/HTTP\/[0-9].[0-9] 404/){
	    $passed++;
	    $msg="  Passed on: $ret[0]";
        }else{
	    $failed++;
	    $msg="  Failed on: $url\t$ret[0]";
	    push(@failedURL, "$url\n");
	}
	print "$msg";
        print OUTFILE $msg;
    }
}

## Get all cases that have HTTP404 include.
@files=glob("$PRIVILEGE_TEST_ROOT/*.suite");
@failedURL=();
foreach $inf (@files){
     print "Reading $inf\n";
     open(INFILE,$inf);
     @lines=<INFILE>;
     foreach $line (@lines){
         read_line($line);
     }
     close(INFILE);
}

$total=$failed+$passed;
$summary=sprintf("%.2f",100*$failed/$total)." % failed,\t(".${failed}." out of ".${total}." failed).\n";
print $summary;
print OUTFILE $summary;
close(INFILE);
close(OUTFILE);
if ($failed){
    print "Failed on following:\n";
    print @failedURL;
    exit 1;
}
print "All passed.\n";
exit 0;

