#!/bin/bash

#cd /tests
#
## Validate hipcc works
#hipcc square.cpp -o square.out --amdgpu-target=gfx801
#ret=$?
#if [ $ret -ne 0 ]; then
#    exit 1
#fi
#
## Test that square works in gem5.
#build/GCN3_X86/gem5.opt configs/example/apu_se.py -n2 --benchmark-root=/tests -csquare.out
#ret=$?
#if [ $ret -ne 0 ]; then
#    exit 1
#fi
#exit 0
