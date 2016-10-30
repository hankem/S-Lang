#!/bin/sh

ROOT="`pwd`/../../.."
SLSHROOT="$ROOT/slsh"
export SLSH_CONF_DIR="$SLSHROOT/etc"
export SLSH_PATH="$SLSHROOT/lib:$ROOT/modules"
export SLANG_MODULE_PATH="$ROOT/modules/${ARCH}objs"
export LD_LIBRARY_PATH="$ROOT/src/${ARCH}elfobjs"
export DYLD_LIBRARY_PATH="$ROOT/src/${ARCH}elfobjs"

run_test_pgm="$SLSHROOT/${ARCH}objs/slsh_exe -n -g"
#run_test_pgm="$SLSHROOT/${ARCH}objs/slsh_exe -n -g $SLSHROOT/scripts/sldb"
runprefix="$SLTEST_RUN_PREFIX"
#runprefix="valgrind --tool=memcheck --leak-check=yes --error-limit=no --num-callers=25"
#runprefix="gdb --args"


########################################################################

if [ $# -eq 0 ]
then
    echo "Usage: $0 test1.sl test2.sl ..."
    exit 64
fi

echo
echo "Running slsh lib tests:"
echo

n_failed=0
tests_failed=""
for testxxx in $@
do
    $runprefix $run_test_pgm $testxxx

    if [ $? -ne 0 ]
    then
	n_failed=`expr $n_failed + 1`
	tests_failed="$tests_failed $testxxx"
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
