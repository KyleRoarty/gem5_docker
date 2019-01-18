#!/bin/bash

cd /tests

hipcc square.cpp -o square.out --amdgpu-target=gfx801
if [ $? -ne 0 ]; then
    exit 1
fi

cd /gem5

scons -j$(nproc) build/GCN3_X86/gem5.opt --ignore-style
if [ $? -ne 0 ]; then
    exit 1
fi

build/GCN3_X86/gem5.opt configs/example/apu_se.py -n2 --benchmark-root=/tests -csquare.out
if [ $? -ne 0 ] && [ $? -ne 134 ]; then
    exit 1
fi

exit 0
