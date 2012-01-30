#!/bin/bash
# Restore the original file
#
function print_usage(){
cat <<END
$0 - Restore the original files from SCM or backup file
Usage: $0 [-s SCM] [-t] file [file2 [file3...] ]
Options:
    -s SVM: Restore the original file from SCM like git or svn
    -t: Test whether files in SCM Return 0 if the all files are in scm, 1 otherwise.
    file: File to restore
END
}

SCM=
testOnly=0;
dirty=0;

while getopts "s:t" opt; do
    case $opt in
	s)
	    SCM=$OPTARG
	    ;;
	t)
	    testOnly=1
	    ;;
	*)
	    ;;
    esac
done
shift $((OPTIND-1));

file=$1

if [ -z $file ];then
    print_usage
    exit -1
fi

for f in $@;do
    fileDir=`dirname $f`
    basename=`basename $f`
    pushd $fileDir
    case $SCM in
	git)
	    if [ $testOnly -eq 0 ];then
		git checkout "$basename"
	    else
		ret=`git ls-files "$basename"`
		if [ -z "$ret" ];then
		    echo "$basename is not in $SCM" > /dev/stderr
		    dirty=1;
		fi
	    fi
	    ;;
	svn)
	    if [ $testOnly -eq 0 ];then
		svn revert "$basename"
	    else
		if svn list "$basename"; then
		    echo "$basename is not in $SCM" > /dev/stderr
		    dirty=1;
		fi
	    fi
	    ;;
	*)
	    if [ -r "$basename.orig" ];then
		mv "$basename.orig" "$basename"
	    fi
	    ;;
    esac
    popd
done
exit $dirty

