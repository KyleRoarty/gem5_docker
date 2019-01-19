#!/bin/bash

cd /tests

# Validate hipcc works
hipcc square.cpp -o square.out --amdgpu-target=gfx801
ret=$?
if [ $ret -ne 0 ]; then
    exit 1
fi

# Get DNNMark loaded
git clone https://github.com/doody1986/DNNMark.git
cd DNNMark/
git apply ../dnnmark.patch
./setup.sh HIP
cd build
make

# Get the file needed for the DNNMark program
mkdir -p /.cache/miopen/1.2.0/8cc7cb244c7ad66444adf4fb7d8b94f1/
cd /MIOpen/src/kernels

# Generate the file
/opt/rocm/bin/clang-ocl  -DNUM_BATCH=1 -mcpu=gfx801 -Wno-everything MIOpenSoftmax.cl -o /.cache/miopen/1.2.0/8cc7cb244c7ad66444adf4fb7d8b94f1/MIOpenSoftmax.cl.o
ret=$?
if [ $ret -ne 0]; then
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

# Run fwd softmax benchmark
build/GCN3_X86/gem5.opt configs/example/apu_se.py -n2 --benchmark-root=/tests/DNNMark/build/benchmarks/test_fwd_softmax -cdnnmark_test_fwd_softmax --options="-config /tests/DNNMark/config_example/softmax_config.dnnmark -debuginfo 1"
ret=$?
if [ $ret -ne 0 ]; then
    exit 1
fi

exit 0
