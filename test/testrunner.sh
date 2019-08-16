#!/bin/bash
#testrunner.sh

#pushd `dirname $0`
#
## python argparse.ArgumentParser prog test
#python myprogram.py --help
#pushd ..
#python test/myprogram.py --help
#popd
#
#popd

./test/argparseTest.py > argparseTest_py.out
./test/argparseTest.sh > argparseTest_sh.out

if diff -q argparseTest_py.out argparseTest_sh.out; then
    echo "Successful test"
else
    vimdiff argparseTest_py.out argparseTest_sh.out
    echo "Unsuccessful test"
fi

