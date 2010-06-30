#!/usr/bin/env perl
# http404_check.perl <inDir> <outFile> <urlprefix>
use Time::HiRes qw(ualarm gettimeofday tv_interval);
$tmp_file="http404.tmp";

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

$HTTP404_CHECK_RESULT_XML=$ENV{'HTTP404_CHECK_RESULT_XML'};
if ($HTTP404_CHECK_RESULT_XML eq ""){
    die 'Please source test.cfg and make sure it has HTTP404_CHECK_RESULT_XML!'
}

open(OUTFILE, ">$HTTP404_CHECK_RESULT");
$failed=0;
$passed=0;

sub read_line{
    local($line)=($_[0]);
    local($type,$url)=split(' ', $line);
#    print "\tTYPE=$type, URL=$url\n";
    if ($type eq "HTTP404"){
	local($t0) = ([gettimeofday]);
	`curl --silent --show-error --dump-header "$tmp_file" "$FLIES_URL/$url"`;
	local($ret)=`head --lines=1 "$tmp_file"`;
	push(@elapseds, tv_interval($t0));
	push(@names, $url);
	local($status, $desc)= ($ret =~ m|HTTP/[0-9].[0-9] ([0-9]{3}) ([^\r\n]*)|);
	push(@statuses, $status);
	push(@descs, $desc);
        if ( $status eq "404"){
	    $passed++;
	    $msg="Passed on: $url\tHTTP $status";
	}else{
	    $failed++;
	    $msg="Failed on: $url\tHTTP $status $desc";
	    push(@failedURL, "$url");
	}
	print "  $msg\n";
	print OUTFILE "  $msg\n";
    }
}

# Print JUnit XML
sub print_junit_xml_header{
    local($hostname,$totalTime)=(@_);
    local($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=gmtime(time);
    local($timestamp)=sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ", $year+1900, $mon+1, $mday, $hour,$sec);
    print XMLOUTFILE "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n";
    print XMLOUTFILE "<testsuite errors=\"0\" failures=\"$failed\" hostname=\"$hostname\" name=\"HTTP404 Check\" tests=\"$totalTests\" time=\"$totalTime\" timestamp=\"$timestamp\">\n";
#    print XMLOUTFILE "  <properties>\n";
#    print XMLOUTFILE "  </properties>\n";
}

sub print_junit_xml_case{
    local($name,$time,$status,$desc)=(@_);
    print XMLOUTFILE "  <testcase name=\"$name\" time=\"$time\" ";
    if ($status eq "404"){
	print XMLOUTFILE "/>\n";
    }else{
	print XMLOUTFILE ">\n";
	print XMLOUTFILE "    <failure type=\"$status\" message=\"$desc\">HTTP $status $desc</failure>\n";
	print XMLOUTFILE "  </testcase>\n";
    }
}

sub print_junit_xml_footer{
    local($out,$err)=($_[0],$_[1]);
    print XMLOUTFILE "  <system-out>$out</system-out>\n";
    print XMLOUTFILE "  <system-err>$err</system-err>\n";
    print XMLOUTFILE "</testsuite>\n";
}

sub print_junit_xml{
    local($hostname,$out,$err)=(@_);
    local($totalTime)=(0.0);

    foreach $e (@elapseds){
	$totalTime+=$e;
    }

    open(XMLOUTFILE, ">$HTTP404_CHECK_RESULT_XML");
    print_junit_xml_header($hostname,$totalTime);
    for($i=0; $i<= $#names ; ++$i){
	print_junit_xml_case($names[$i],$elapseds[$i],$statuses[$i],$descs[$i]);
    }
    print_junit_xml_footer($out,$err);
    close(XMLOUTFILE);
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

$totalTests=$failed+$passed;
$summary=sprintf("%.2f",100*$failed/$totalTests)." % failed,\t(".${failed}." out of ".${total}." failed).\n";
print $summary;
print OUTFILE $summary;
close(INFILE);
close(OUTFILE);
if ($failed){
    $errmsg="Failed on following:\n";
    foreach $fURL (@failedURL){
	$errmsg=$errmsg."$fURL\n";
    }
    print $errmsg;
    $outmsg="<![CDATA[]]>";
}else{
    $errmsg="<![CDATA[]]>";
    $outmsg="All passed.\n";
    print $outmsg;
}

unlink $tmp_file;

print "Generating XML report...";
($hostname) = $FLIES_URL =~ m|http[s]?://([^/]*)| ;

print_junit_xml($hostname,$outmsg,$errmsg);
print "Done.\n";

if ($failed){
    exit 1;
}
exit 0;

