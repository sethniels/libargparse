# A test program to demonstrate that the program name does not change with the
# directory it is run from
import argparse
parser = argparse.ArgumentParser()
parser.add_argument('--foo', help='foo help')
args = parser.parse_args()

