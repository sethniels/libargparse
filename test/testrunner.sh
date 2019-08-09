#!/bin/bash
#testrunner.sh

pushd `dirname $0`

# python argparse.ArgumentParser prog test
python myprogram.py --help
pushd ..
python test/myprogram.py --help
popd

popd

