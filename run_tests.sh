#!/bin/bash

cd /gem5
scons -j9 build/GCN3_X86/gem5.opt --ignore-style
