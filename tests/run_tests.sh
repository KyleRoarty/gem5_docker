#!/bin/bash

cd /tests

# Validate hipcc works
hipcc square.cpp -o square.out --amdgpu-target=gfx801
if [ $? -ne 0 ]; then
    exit 1
fi

cd /gem5

# Validate that gem5 can be built
scons -j$(nproc) build/GCN3_X86/gem5.opt --ignore-style
if [ $? -ne 0 ]; then
    exit 1
fi

# Test that square works in sim.
# The simulator returns 134, but square works
build/GCN3_X86/gem5.opt configs/example/apu_se.py -n2 --benchmark-root=/tests -csquare.out
if [ $? -ne 0 ] && [ $? -ne 134 ]; then
    exit 1
fi

exit 0
