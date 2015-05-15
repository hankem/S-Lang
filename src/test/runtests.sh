#!/bin/sh

run_test_pgm="./sltest"
runprefix="$SLTEST_RUN_PREFIX"

########################################################################

if [ $# -eq 0 ]
then
    echo "Usage: $0 TEST_SCRIPTS TEST_SCRIPTS_SLC"
    echo " where TEST_SCRIPTS     = test1.sl test2.sl ..."
    echo "       TEST_SCRIPTS_SLC = test1.slc ..."
    exit 64
fi

echo
echo "Running tests:"
echo

test -d lastrun || mkdir lastrun

n_failed=0
tests_failed=""
for testfile in $@
do
    pass=1

    for utf8mode in "" "-utf8"
    do
	$runprefix $run_test_pgm $utf8mode $testfile || pass=0
    done

    if [ $pass -eq 0 ]
    then
	n_failed=`expr ${n_failed} + 1`
	tests_failed="$tests_failed $testfile"
    else
        touch lastrun/$testfile
    fi
done

echo
if [ $n_failed -eq 0 ]
then
    echo "All tests passed."
else
    echo "$n_failed tests failed: $tests_failed"
fi
echo

exit $n_failed
