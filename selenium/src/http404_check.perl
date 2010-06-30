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
       	chomp($ret);
	push(@elapseds, tv_interval($t0));
	push(@names, $url);
        if ( $ret =~ /HTTP\/[0-9].[0-9] 404/){
	    $passed++;
	    $msg="Passed on: $ret";
	}else{
	    $failed++;
	    $msg="Failed on: $url\t$ret";
	    push(@failedURL, "$url\n");
	}
	push(@results, "$msg");
	print "  $msg\n";
	print OUTFILE "  $msg\n";
    }
}

# Print JUnit XML
sub print_junit_xml_header{
    local($failures,$tests,$hostname,$time)=($_[0],$_[1],$_[2],$_[3]);
    local($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=gmtime(time);
    local($timestamp)=sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ", $year+1900, $mon+1, $mday, $hour,$sec);
    print XMLOUTFILE "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n";
    print XMLOUTFILE "<testsuite errors=\"0\" failures=\"0\" hostname=\"$hostname\" name=\"HTTP404 Check\" tests=\"$tests\" time=\"$time\" timestamp=\"$timestamp\">\n";
    print XMLOUTFILE "  <properties>\n";
    print XMLOUTFILE "  </properties>\n";
}

sub print_junit_xml_case{
    local($name,$time,$result)=($_[0],$_[1],$_[2]);
    print XMLOUTFILE "  <testcase classname=\"$name\" name=\"$name\" time=\"$time\" ";
    if ($result =~ /^Passed on:/){
	print XMLOUTFILE "/>\n";
    }else{
	print XMLOUTFILE ">\n";
	local($error_type, $message) = $result =~ m|HTTP/[0-9].[0-9] ([0-9]{3}) (\S*)| ;
	print XMLOUTFILE "    <error message=\"$message\" type=\"$error_type\">$result</error>\n";
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
    local($failures,$tests,$hostname,$out,$err)=(@_);
    local($totaltime)=(0.0);

    foreach $e (@elapseds){
	$totaltime+=$e;
    }

    open(XMLOUTFILE, ">$HTTP404_CHECK_RESULT_XML");
    print_junit_xml_header($failures,$test,$hostname,$totaltime);
    for($i=0; $i< $#names ; ++$i){
	print_junit_xml_case($names[$i],$elapseds[$i],$results[$i]);
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

$total=$failed+$passed;
$summary=sprintf("%.2f",100*$failed/$total)." % failed,\t(".${failed}." out of ".${total}." failed).\n";
print $summary;
print OUTFILE $summary;
close(INFILE);
close(OUTFILE);
if ($failed){
    $errmsg="Failed on following:\n @failedURL";
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

print_junit_xml($failures,$total,$hostname,$outmsg,$errmsg);
print "Done.\n";

if ($failed){
    exit 1;
}
exit 0;

