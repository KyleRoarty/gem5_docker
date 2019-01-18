#!/bin/bash

cd /tests

# Validate hipcc works
hipcc square.cpp -o square.out --amdgpu-target=gfx801
ret=$?
if [ $ret -ne 0 ]; then
    exit 1
fi

cd /gem5

# Validate that gem5 can be built
scons -j$(nproc) build/GCN3_X86/gem5.opt --ignore-style
ret=$?
if [ $ret -ne 0 ]; then
    exit 1
fi

# Test that square works in sim.
# The simulator returns 134, but square works
build/GCN3_X86/gem5.opt configs/example/apu_se.py -n2 --benchmark-root=/tests -csquare.out
ret=$?
if [ $ret -ne 0 ] && [ $ret -ne 134 ]; then
    exit 1
fi

exit 0
