#!/usr/bin/python
#argparseTest.py

import argparse
import sys
import math

# ArgumentParser params:
#   prog=None:                  support
#   usage=None:                 support
#   description=None:           support
#   epilog=None:                support
#   version=None:               support
#   parents=[]                  maybe?
#   formatter_class=<class "argparse.HelpFormatter">:
#                               maybe?
#   prefix_chars="-":           support
#   fromfile_prefix_chars=None: support
#   argument_default=None:      support
#   allow_abbrev=True:          maybe?
#   conflict_handler="error":   maybe?
#   add_help=True:              support

print "Start of argparseTest"

# prog test
print "ArgumentParser prog test"
parser = argparse.ArgumentParser(prog='myprogram')
parser.print_help()

parser = argparse.ArgumentParser(prog='myprogram')
parser.add_argument('--foo', help='foo of the %(prog)s program')
parser.print_help()

# usage test
print "ArgumentParser usage test"
parser = argparse.ArgumentParser(prog='PROG')
parser.add_argument('--foo', nargs='?', help='foo help')
parser.add_argument('bar', nargs='+', help='bar help')
parser.print_help()

parser = argparse.ArgumentParser(prog='PROG', usage='%(prog)s [options]')
parser.add_argument('--foo', nargs='?', help='foo help')
parser.add_argument('bar', nargs='+', help='bar help')
parser.print_help()

# description test
print "ArgumentParser description test"
parser = argparse.ArgumentParser(description='A foo that bars')
parser.print_help()

# epilog test
print "ArgumentParser epilog test"
parser = argparse.ArgumentParser(description='A foo that bars',
        epilog="And that's how you'd foo a bar")
parser.print_help()

# version test
# Which do we support?

# prefix_chars test
print "ArgumentParser prefix_chars test"
parser = argparse.ArgumentParser(prog='PROG', prefix_chars='-+')
parser.add_argument('+f')
parser.add_argument('++bar')
print parser.parse_args('+f X ++bar Y'.split())

# fromfile_prefix_chars test
print "ArgumentParser fromfile_prefix_chars test"
with open('args.txt', 'w') as fp:
    fp.write('-f\nbar')
parser = argparse.ArgumentParser(fromfile_prefix_chars='@')
parser.add_argument('-f')
print parser.parse_args(['-f', 'foo', '@args.txt'])

# argument_default test
print "ArgumentParser argument_default test"
parser = argparse.ArgumentParser(argument_default=argparse.SUPPRESS)
parser.add_argument('--foo')
parser.add_argument('bar', nargs='?')
print parser.parse_args(['--foo', '1', 'BAR'])
print parser.parse_args([])

# add_help test
parser = argparse.ArgumentParser(prog='PROG', add_help=False)
parser.add_argument('--foo', help='foo help')
parser.print_help()

# ArgumentParser.add_argument params:
#   name or flags:  support
#   action:         support
#   nargs:          support
#   const:          support
#   default:        support
#   type:           maybe?
#   choices:        maybe?
#   required:       support
#   help:           support
#   metavar:        maybe?
#   dest:           maybe?

# name or flags test
print "add_argument name or flags test"
parser = argparse.ArgumentParser(prog='PROG')
parser.add_argument('-f', '--foo')
parser.add_argument('bar')
print parser.parse_args(['BAR'])
print parser.parse_args(['BAR', '--foo', 'FOO'])
try:
    print "HERE I AM"
    parser.parse_args(['--foo', 'FOO'])
    print "HERE I AM2"
except BaseException as exc:
    print "%r" % exc

# action test
print "add_argument action test"
parser = argparse.ArgumentParser()
parser.add_argument('--foo')
print parser.parse_args('--foo 1'.split())

parser = argparse.ArgumentParser()
parser.add_argument('--foo', action='store_const', const=42)
print parser.parse_args(['--foo'])

parser = argparse.ArgumentParser()
parser.add_argument('--foo', action='store_true')
parser.add_argument('--bar', action='store_false')
parser.add_argument('--baz', action='store_false')
print parser.parse_args('--foo --bar'.split())

parser = argparse.ArgumentParser()
parser.add_argument('--foo', action='append')
print parser.parse_args('--foo 1 --foo 2'.split())

parser = argparse.ArgumentParser()
parser.add_argument('--str', dest='types', action='append_const', const=str)
parser.add_argument('--int', dest='types', action='append_const', const=int)
print parser.parse_args('--str --int'.split())

parser = argparse.ArgumentParser()
parser.add_argument('--verbose', '-v', action='count')
print parser.parse_args(['-vvv'])

parser = argparse.ArgumentParser(prog='PROG')
parser.add_argument('--version', action='version', version='%(prog)s 2.0')
try:
    print parser.parse_args(['--version'])
except BaseException as exc:
    print "%r" % exc

# nargs test
print "add_argument nargs test"
parser = argparse.ArgumentParser()
parser.add_argument('--foo', nargs=2)
parser.add_argument('bar', nargs=1)
print parser.parse_args('c --foo a b'.split())

parser = argparse.ArgumentParser()
parser.add_argument('--foo', nargs='?', const='c', default='d')
parser.add_argument('bar', nargs='?', default='d')
print parser.parse_args(['XX', '--foo', 'YY'])
print parser.parse_args(['XX', '--foo'])
print parser.parse_args([])

parser = argparse.ArgumentParser()
with open('input.txt', 'w') as fout:
    fout.write("this is input.txt\n")
parser.add_argument('infile', nargs='?', type=argparse.FileType('r'),
        default=sys.stdin)
parser.add_argument('outfile', nargs='?', type=argparse.FileType('w'),
        default=sys.stdout)
print parser.parse_args(['input.txt', 'output.txt'])
print parser.parse_args([])

parser = argparse.ArgumentParser()
parser.add_argument('--foo', nargs='*')
parser.add_argument('--bar', nargs='*')
parser.add_argument('baz', nargs='*')
print parser.parse_args('a b --foo x y --bar 1 2'.split())

parser = argparse.ArgumentParser(prog='PROG')
parser.add_argument('foo', nargs='+')
print parser.parse_args(['a', 'b'])
try:
    print parser.parse_args([])
except BaseException as exc:
    print "%r" % exc

parser = argparse.ArgumentParser(prog='PROG')
parser.add_argument('--foo')
parser.add_argument('command')
parser.add_argument('args', nargs=argparse.REMAINDER)
print(parser.parse_args('--foo B cmd --arg1 XX ZZ'.split()))

# const test
print "add_argument const test"

# default test
print "add_argument default test"
parser = argparse.ArgumentParser()
parser.add_argument('--foo', default=42)
print parser.parse_args(['--foo', '2'])
print parser.parse_args([])

parser = argparse.ArgumentParser()
parser.add_argument('--length', default='10', type=int)
parser.add_argument('--width', default=10.5, type=int)
print parser.parse_args()

parser = argparse.ArgumentParser()
parser.add_argument('foo', nargs='?', default=42)
print parser.parse_args(['a'])
print parser.parse_args([])

parser = argparse.ArgumentParser()
parser.add_argument('--foo', default=argparse.SUPPRESS)
print parser.parse_args([])
print parser.parse_args(['--foo', '1'])

# type test
print "add_argument type test"
with open('temp.txt', 'w') as fout:
    fout.write('This is temp.txt');
parser = argparse.ArgumentParser()
parser.add_argument('foo', type=int)
parser.add_argument('bar', type=open)
print parser.parse_args('2 temp.txt'.split())

parser = argparse.ArgumentParser()
parser.add_argument('bar', type=argparse.FileType('w'))
print parser.parse_args(['out.txt'])

def perfect_square(string):
    value = int(string)
    sqrt = math.sqrt(value)
    if sqrt != int(sqrt):
        msg = "%r is not a perfect square" % string
        raise argparse.ArgumentTypeError(msg)
    return value

parser = argparse.ArgumentParser(prog='PROG')
parser.add_argument('foo', type=perfect_square)
print parser.parse_args(['9'])
try:
    print parser.parse_args(['7'])
except BaseException as exc:
    print "%r" % exc

parser = argparse.ArgumentParser(prog='PROG')
parser.add_argument('foo', type=int, choices=range(5, 10))
print parser.parse_args(['7'])
try:
    print parser.parse_args(['11'])
except BaseException as exc:
    print "%r" % exc

# choices test
print "add_argument choices test"
parser = argparse.ArgumentParser(prog='game.py')
parser.add_argument('move', choices=['rock', 'paper', 'scissors'])
print parser.parse_args(['rock'])
try:
    print parser.parse_args(['fire'])
except BaseException as exc:
    print "%r" % exc

parser = argparse.ArgumentParser(prog='doors.py')
parser.add_argument('door', type=int, choices=range(1, 4))
print(parser.parse_args(['3']))
try:
    print parser.parse_args(['4'])
except BaseException as exc:
    print "%r" % exc

# required test
print "add_argument required test"
parser = argparse.ArgumentParser()
parser.add_argument('--foo', required=True)
print parser.parse_args(['--foo', 'BAR'])
try:
    print parser.parse_args([])
except BaseException as exc:
    print "%r" % exc

# help test
print "add_argument help test"
parser = argparse.ArgumentParser(prog='frobble')
parser.add_argument('--foo', action='store_true',
        help='foo the bars before frobbling')
parser.add_argument('bar', nargs='+',
        help='one of the bars to be frobbled')
try:
    print parser.parse_args(['-h'])
except BaseException as exc:
    print "%r" % exc

parser = argparse.ArgumentParser(prog='frobble')
parser.add_argument('bar', nargs='?', type=int, default=42,
        help='the bar to %(prog)s (default: %(default)s)')
parser.print_help()

parser = argparse.ArgumentParser(prog='frobble')
parser.add_argument('--foo', help=argparse.SUPPRESS)
parser.print_help()

print "End of argparseTest"

