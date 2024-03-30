#!/bin/bash

# Test if the produced binary can be run under qemu with a specific CPU and
# specified features turned on/off
# If the needed qemu emulator is not installed, the test returns SKIP (77)
# Ex test name: "portable,aarch64-linux-gnu,cortex-a53,,+neon"
# the cpu_option field uses @ as placeholder for '=' and ~ as placeholder for ','
# so the option "neon=no,vfp=no" should be given as "neon@no~vfp@no"
# The expected_detection field uses ~ as placeholder for ' '
# so "+mmx -avx2" should be given as "+mmx~-avx2"

testname=$(basename $0)
oIFS=$IFS IFS=, testargs=(${testname}) IFS=$oIFS

triplet=${testargs[1]}
host_cpu=${triplet%%-*}
cpu=${testargs[2]}
cpu_option=${testargs[3]//@/=}
cpu_option=${cpu_option//\~/,}
expected_detection=${testargs[4]}
expected_detection=${expected_detection//~/ }

test -z "$QEMU" && {
    >&2 echo \$QEMU not defined - this test only makes sense with QEMU
    exit 1
}

test -z "$QEMU" && {
    >&2 echo \$QEMU not defined - this test only makes sense with QEMU
    exit 1
}

type -t "qemu-$host_cpu" >/dev/null || {
    >&2 echo QEMU for $host_cpu is not installed - skipping portability test for $host_cpu
    exit 77
}

# FIXME: This is a hack for Ubuntu where qemu is not configured with the correct library search path
if type -t lsb_release >/dev/null && [[ "$(lsb_release -is)" == "Ubuntu" ]] ; then
    QEMU_LIBDIR="-L /usr/$triplet"
else
    QEMU_LIBDIR=
fi

set -o errexit
echo TAP version 13
echo 1..4

set -x
# Test 1 check that QEMU supports the named CPU
set +o pipefail
"$QEMU" --cpu help | egrep -q "^\\s+$cpu\$" || {
    echo not ok 1 - QEMU does not support the $cpu CPU
    exit 77
}
echo ok 1 - QEMU does support the $cpu CPU
set -o pipefail


# Test 2 check that QEMU supports the given option for the CPU
version=$("$QEMU" --cpu ${cpu}${cpu_option:+,$cpu_option} $QEMU_LIBDIR ./ugrep --version) || {
    res=$?
    echo res=$res
    case $res in
        1) echo "not ok 2 - QEMU does not support feature '$cpu_option' for $cpu CPU"
           exit 77
           ;;
        *) echo "not ok 2 - Failed to run --version with feature '$cpu_option'"
           exit 1
           ;;
    esac
}
echo "ok 2 - QEMU CPU feature support is ok for '$cpu_option'"


# Test 3 - check that the version output includes the expected detection string  (eg, "+neon")
[[ "$version" =~ "$expected_detection" ]] || {
    echo "not ok 3 - CPU Feature detection - --version output does not contain '$expected_detection'"
    exit 1
}
echo "ok 3 - CPU Feature detection - --version output contains '$expected_detection'"


# Test 4 - check that it doesn't crash when running on the target CPU
"$QEMU" --cpu ${cpu}${cpu_option:+,$cpu_option} $QEMU_LIBDIR ./ugrep portability $0 || {
    echo "not ok 4 - Functional test - Searching does not find the string 'portability'"
    exit 1
}
echo "ok 4 - Functional test - searching finds the string 'portability'"
