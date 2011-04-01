#!/bin/sh
# http404_check.sh
if [ -z ${ZANATA_URL} ];then
    source ./test.cfg
fi
export ZANATA_URL
export PRIVILEGE_TEST_ROOT
export HTTP404_CHECK_RESULT
export HTTP404_CHECK_RESULT_XML
perl http404_check.perl

