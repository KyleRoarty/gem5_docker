#!/bin/bash

cd /tests

# Validate hipcc works
hipcc square.cpp -o /tmp/square.out --amdgpu-target=gfx801
ret=$?
if [ $ret -ne 0 ]; then
    exit 1
fi

cd /tmp2
# Get DNNMark and build
git clone https://github.com/doody1986/DNNMark.git
apt-get update && apt-get install -y --no-install-recommends libgflags-dev libgoogle-glog-dev
cd DNNMark/
git checkout 4c0497b
git apply /tests/dnnmark.patch
./setup.sh HIP
cd build
make -j$(nproc)

ls -la /

# Get the file needed for the DNNMark fwd_softmax
# fwd_softmax requires a softmax file placed in the directory made below
# If the program is ran without the file in that directory, it will error out
mkdir -p /.cache/miopen/1.2.0/8cc7cb244c7ad66444adf4fb7d8b94f1/
cd /MIOpen/src/kernels

# Generate the file, placing it in the required directory
/opt/rocm/bin/clang-ocl  -DNUM_BATCH=1 -mcpu=gfx801 -Wno-everything \
    MIOpenSoftmax.cl \
    -o /.cache/miopen/1.2.0/8cc7cb244c7ad66444adf4fb7d8b94f1/MIOpenSoftmax.cl.o
ret=$?
if [ $ret -ne 0 ]; then
    exit 1
fi

cd /gem5

## Validate that gem5 can be built
#scons -j$(nproc) build/GCN3_X86/gem5.opt --ignore-style
#ret=$?
#if [ $ret -ne 0 ]; then
#    exit 1
#fi

# Test that square works in gem5.
build/GCN3_X86/gem5.opt configs/example/apu_se.py \
                        -n2 \
                        --benchmark-root=/tmp -csquare.out
ret=$?
if [ $ret -ne 0 ]; then
    exit 1
fi

ls /tmp2/DNNMark

build/GCN3_X86/gem5.opt configs/example/apu_se.py \
            -n2 \
            --benchmark-root=/tmp2/DNNMark/build/benchmarks/test_fwd_softmax \
            -cdnnmark_test_fwd_softmax \
            --options="-config /tmp2/DNNMark/config_example/softmax_config.dnnmark -debuginfo 1"
ret=$?
if [ $ret -ne 0 ]; then
    exit 1
fi

exit 0
