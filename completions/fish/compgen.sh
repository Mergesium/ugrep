#!/bin/bash

if test $# != 2 ; then
    2>&1 echo "Usage: $0 <ugrep executable name> <command name>"
    2>&1 echo "Runs the executable to create completions for the named command"
    exit 1
fi

UGREP=$1
CMDNAME=$2

echo "# Autogenerated from $UGREP --help for alias '$CMDNAME'"

# get -t (--file-type=) TYPES arguments
TYPES=$("$UGREP" -tlist 2>&1 | sed -E -e 's/[ ]*([0-9A-Za-z+]+).*/\1/' -e '/FILE/d' -e '/^ /d' | tr '\n' ' ')

# get --encoding=ENCODING arguments
ENCODING=$("$UGREP" --encoding=list 2>&1 | sed -e 's/^.[a-z].*are//' -e '/help/d' -e "s/ '//g" -e "s/',\?/ /g" | tr '\n' ' ')

# generate --help
# short -<opt> to -s <opt>, old -<opt> to -o '<opt>' and long --<opt> to -l <opt> and add -d at the end
# remove cluttering [-e] PATTERN [OPTIONS] [WHAT], ... and ,
# quote short -s '<opt>' when <opt> is not alphanumeric
# keep option line and description's first sentence up to period, remove ` ' from descriptions, remove 4 spaces indent
# append indented description to the option line
# quote -d 'description'
# add -xa 'arguments' to -DACTION and -dACTION
# add -xa 'arguments' to -t,--file-type=TYPES and --encoding=ENCODING
# add -xa 'arguments' to --hexdump
# add -xa 'arguments' to --sort=KEY
# add -xa 'arguments' to --fuzzy=
# add -r to -e, -f, -g, -J, -K, -M, -m, -N, -O
"$UGREP" --help 2>&1 \
    | sed -E -e '/^[ ]{4}-/s/ -([^-])([[ ][^ ]*|,|$)/ -s \1/g' -e $'/^[ ]{4}-/s/ -([^-][^-, ]+)/ -o \'\\1\'/g' -e '/^[ ]{4}-/s/--([-a-z]+)[^ ]*/-l \1/g' -e '/^[ ]{4}-/s/$/ -d/' \
    | sed -E -e '/^[ ]{4}-/s/ \[-e\] PATTERN| \[OPTIONS\]| \[WHAT\]| \.\.\.|,//g' \
    | sed -E -e $'/^[ ]{4}-/s/-s ([^0-9A-Za-z])/-s \'\\1\'/g' \
    | sed -E -e '/^[ ]{4}-/,/^[ ]{12}.*\./!d' -e 's/^([ ]{12}[^.]*)\.( .*)?$/\1/' -e $'/^[ ]{12}/s/[`\']//g' -e 's/^[ ]{4}//' \
    | sed -e :a -e '$!N;s/\n[ ]\{7\}//;ta' -e 'P;D' \
    | sed -e $'s/ -d / -d \'/' -e $'s/$/\'/' \
    | sed -e "s/^-s D -l devices /&-xa 'read skip' /" -e "s/^-s d -l directories /&-xa 'read recurse skip' /" \
    | sed -e "s/^-s t -l file-type /&-xa '$TYPES' /" -e "s/^-l encoding /&-xa '$ENCODING' /" \
    | sed -e "s/^-l hexdump /&-xa '1a 2a 4ah 6ah 8ah 1aC1 2aC1 4ahC1 6ahC1 8ahC1' /" \
    | sed -e "s/^-l sort /&-xa 'name best size changed created used rname rbest rsize rchanged rcreated rused' /" \
    | sed -e "s/^-s Z -l fuzzy /&-xa '1 +1 -1 ~1 +-1 +~1 +-~1 -~1 best1 best+1 best-1 best~1 best+-1 best+~1 best+-~1 best-~1' /" \
    | sed -e "s/^-s [efgJKMmNO]/& -r/"
