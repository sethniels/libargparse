#!/bin/bash
#argparseTest.sh

cd `dirname $0`
argparse="../src/bash/argparse.sh"
. ${argparse}

echo "Start of argparseTest"

# prog test
echo "ArgumentParser prog test"
ArgumentParser parser --prog="myprogram"
print_help parser

ArgumentParser parser --prog='myprogram'
add_argument parser '--foo' --help='foo of the %(prog) program'
print_help parser

# usage test
echo "ArgumentParser usage test"
ArgumentParser parser --prog='PROG'
add_argument parser '--foo' --nargs='?' --help='foo help'
add_argument parser 'bar' --nargs='+' --help='bar help'
print_help parser
echo "Test terminated"; exit 1

. ${argparse} ArgumentParser --prog='PROG' --usage='%(prog)s [options]'
. ${argparse} add_argument '--foo', --nargs='?' --help='foo help'
. ${argparse} add_argument 'bar', --nargs='+' --help='bar help'
. ${argparse} print_help

# description test
echo "ArgumentParser description test"
. ${argparse} ArgumentParser --description='A foo that bars'
. ${argparse} print_help

# epilog test
echo "ArgumentParser epilog test"
. ${argparse} ArgumentParser --description='A foo that bars' --epilog="And that's how you'd foo a bar"
. ${argparse} print_help

# version test
# Which do we support?

# prefix_chars test
echo "ArgumentParser prefix_chars test"
. ${argparse} ArgumentParser --prog='PROG' --prefix_chars='-+'
. ${argparse} add_argument '+f'
. ${argparse} add_argument '++bar'
echo parser.parse_args('+f X ++bar Y'.split()

# fromfile_prefix_chars test
echo "ArgumentParser fromfile_prefix_chars test"
with open('args.txt', 'w') as fp:
    fp.write('-f\nbar'
. ${argparse} ArgumentParser --fromfile_prefix_chars='@'
. ${argparse} add_argument '-f'
echo parser.parse_args(['-f', 'foo', '@args.txt']

# argument_default test
echo "ArgumentParser argument_default test"
. ${argparse} ArgumentParser argument_default=argparse.SUPPRESS
. ${argparse} add_argument '--foo'
. ${argparse} add_argument 'bar', --nargs='?'
echo parser.parse_args(['--foo', '1', 'BAR']
echo parser.parse_args([]

# add_help test
. ${argparse} ArgumentParser --prog='PROG' add_help=False
. ${argparse} add_argument '--foo', --help='foo help'
. ${argparse} print_help

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
echo "add_argument name or flags test"
. ${argparse} ArgumentParser --prog='PROG'
. ${argparse} add_argument '-f', '--foo'
. ${argparse} add_argument 'bar'
echo parser.parse_args(['BAR']
echo parser.parse_args(['BAR', '--foo', 'FOO']
try:
    echo "HERE I AM"
    parser.parse_args(['--foo', 'FOO']
    echo "HERE I AM2"
except BaseException as exc:
    echo "%r" % exc

# action test
echo "add_argument action test"
. ${argparse} ArgumentParser 
. ${argparse} add_argument '--foo'
echo parser.parse_args('--foo 1'.split()

. ${argparse} ArgumentParser 
. ${argparse} add_argument '--foo', --action='store_const' const=42
echo parser.parse_args(['--foo']

. ${argparse} ArgumentParser 
. ${argparse} add_argument '--foo', --action='store_true'
. ${argparse} add_argument '--bar', --action='store_false'
. ${argparse} add_argument '--baz', --action='store_false'
echo parser.parse_args('--foo --bar'.split()

. ${argparse} ArgumentParser 
. ${argparse} add_argument '--foo', --action='append'
echo parser.parse_args('--foo 1 --foo 2'.split()

. ${argparse} ArgumentParser 
. ${argparse} add_argument '--str', --dest='types', action='append_const' const=str
. ${argparse} add_argument '--int', --dest='types', action='append_const' const=int
echo parser.parse_args('--str --int'.split()

. ${argparse} ArgumentParser 
. ${argparse} add_argument '--verbose', '-v', --action='count'
echo parser.parse_args(['-vvv']

. ${argparse} ArgumentParser --prog='PROG'
. ${argparse} add_argument '--version', --action='version' --version='%(prog)s 2.0'
try:
    echo parser.parse_args(['--version']
except BaseException as exc:
    echo "%r" % exc

# nargs test
echo "add_argument nargs test"
. ${argparse} ArgumentParser 
. ${argparse} add_argument '--foo', nargs=2
. ${argparse} add_argument 'bar', nargs=1
echo parser.parse_args('c --foo a b'.split()

. ${argparse} ArgumentParser 
. ${argparse} add_argument '--foo', --nargs='?', --const='c' default='d'
. ${argparse} add_argument 'bar', --nargs='?' --default='d'
echo parser.parse_args(['XX', '--foo', 'YY']
echo parser.parse_args(['XX', '--foo']
echo parser.parse_args([]

. ${argparse} ArgumentParser 
with open('input.txt', 'w') as fout:
    fout.write("this is input.txt\n"
. ${argparse} add_argument 'infile', --nargs='?' type=argparse.FileType('r'),
        default=sys.stdin
. ${argparse} add_argument 'outfile', --nargs='?' type=argparse.FileType('w'),
        default=sys.stdout
echo parser.parse_args(['input.txt', 'output.txt']
echo parser.parse_args([]

. ${argparse} ArgumentParser 
. ${argparse} add_argument '--foo', --nargs='*'
. ${argparse} add_argument '--bar', --nargs='*'
. ${argparse} add_argument 'baz', --nargs='*'
echo parser.parse_args('a b --foo x y --bar 1 2'.split()

. ${argparse} ArgumentParser --prog='PROG'
. ${argparse} add_argument 'foo', --nargs='+'
echo parser.parse_args(['a', 'b']
try:
    echo parser.parse_args([]
except BaseException as exc:
    echo "%r" % exc

. ${argparse} ArgumentParser --prog='PROG'
. ${argparse} add_argument '--foo'
. ${argparse} add_argument 'command'
. ${argparse} add_argument 'args', nargs=argparse.REMAINDER
echo(parser.parse_args('--foo B cmd --arg1 XX ZZ'.split())

# const test
echo "add_argument const test"

# default test
echo "add_argument default test"
. ${argparse} ArgumentParser 
. ${argparse} add_argument '--foo', default=42
echo parser.parse_args(['--foo', '2']
echo parser.parse_args([]

. ${argparse} ArgumentParser 
. ${argparse} add_argument '--length', --default='10' type=int
. ${argparse} add_argument '--width', default=10.5, type=int
echo parser.parse_args(

. ${argparse} ArgumentParser 
. ${argparse} add_argument 'foo', --nargs='?' default=42
echo parser.parse_args(['a']
echo parser.parse_args([]

. ${argparse} ArgumentParser 
. ${argparse} add_argument '--foo', default=argparse.SUPPRESS
echo parser.parse_args([]
echo parser.parse_args(['--foo', '1']

# type test
echo "add_argument type test"
with open('temp.txt', 'w') as fout:
    fout.write('This is temp.txt');
. ${argparse} ArgumentParser 
. ${argparse} add_argument 'foo', type=int
. ${argparse} add_argument 'bar', type=open
echo parser.parse_args('2 temp.txt'.split()

. ${argparse} ArgumentParser 
. ${argparse} add_argument 'bar', type=argparse.FileType('w')
echo parser.parse_args(['out.txt']

def perfect_square(string):
    value = int(string
    sqrt = math.sqrt(value
    if sqrt != int(sqrt):
        msg = "%r is not a perfect square" % string
        raise argparse.ArgumentTypeError(msg
    return value

. ${argparse} ArgumentParser --prog='PROG'
. ${argparse} add_argument 'foo', type=perfect_square
echo parser.parse_args(['9']
try:
    echo parser.parse_args(['7']
except BaseException as exc:
    echo "%r" % exc

. ${argparse} ArgumentParser --prog='PROG'
. ${argparse} add_argument 'foo', type=int, choices=range(5, 10)
echo parser.parse_args(['7']
try:
    echo parser.parse_args(['11']
except BaseException as exc:
    echo "%r" % exc

# choices test
echo "add_argument choices test"
. ${argparse} ArgumentParser --prog='game.py'
. ${argparse} add_argument 'move', choices=['rock', 'paper', 'scissors']
echo parser.parse_args(['rock']
try:
    echo parser.parse_args(['fire']
except BaseException as exc:
    echo "%r" % exc

. ${argparse} ArgumentParser --prog='doors.py'
. ${argparse} add_argument 'door', type=int, choices=range(1, 4)
echo(parser.parse_args(['3'])
try:
    echo parser.parse_args(['4']
except BaseException as exc:
    echo "%r" % exc

# required test
echo "add_argument required test"
. ${argparse} ArgumentParser 
. ${argparse} add_argument '--foo', required=True
echo parser.parse_args(['--foo', 'BAR']
try:
    echo parser.parse_args([]
except BaseException as exc:
    echo "%r" % exc

# help test
echo "add_argument help test"
. ${argparse} ArgumentParser --prog='frobble'
. ${argparse} add_argument '--foo', --action='store_true'
 --help='foo the bars before frobbling'
. ${argparse} add_argument 'bar', --nargs='+'
 --help='one of the bars to be frobbled'
try:
    echo parser.parse_args(['-h']
except BaseException as exc:
    echo "%r" % exc

. ${argparse} ArgumentParser --prog='frobble'
. ${argparse} add_argument 'bar', --nargs='?' type=int, default=42,
 --help='the bar to %(prog)s (default: %(default)s)'
. ${argparse} print_help

. ${argparse} ArgumentParser --prog='frobble'
. ${argparse} add_argument '--foo', help=argparse.SUPPRESS
. ${argparse} print_help

echo "End of argparseTest"

