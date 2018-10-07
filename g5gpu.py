#!/usr/bin/env python3

import os
import sys
import argparse
import subprocess
import shlex
from enum import Enum

class Command(Enum):
    build = 0
    start = 1
    hipify = 2
    hipcc = 3
    run = 4
    stop = 5

    def __str__(self):
        return self.name

def parseArgs():
    parser = argparse.ArgumentParser(description='Run programs using gem5')
    subparsers = parser.add_subparsers(help='types of command', dest='command')

    start_parser = subparsers.add_parser('start')
    # No args for start, simply starts container
    stop_parser = subparsers.add_parser('stop')

    build_parser = subparsers.add_parser('build')
    build_parser.add_argument('program',
                              choices=['docker', 'gem5', 'deps'])
    # No args for build, builds gem5 in docker

    hipify_parser = subparsers.add_parser('hipify')
    # arg1: cu file to be hipified, arg2: name of output?

    hipcc_parser = subparsers.add_parser('hipcc')
    # arg1: cpp file to be build with hipcc, arg2: name of output?
    hipcc_parser.add_argument('file',
                              type=str,
                              help=".cpp file to compile")

    run_parser = subparsers.add_parser('run')
    run_parser.add_argument('file',
                            type=str,
                            help=".out file to run on gem5")
    # arg is out file to be ran in gem5

    return parser.parse_args()

def build(p):
    if p == 'docker':
        cmd = ["docker", "build", "-t", "gem5", "."]
        ret = subprocess.run(cmd, check=True)
        start()
    elif p == 'deps':
        with open('cmd/deps.txt', 'r') as f:
            lines = filter(None, (line.rstrip() for line in f))
            for line in lines:
                if line[0] == '#':
                    continue
                ret = subprocess.run(shlex.split(line), check=True)
    elif p == 'gem5':
        cmd = ["docker", "exec", "-w", "/sim/gem5", "py_g5_docker",
               "scons", "-j4", "/sim/gem5/build/GCN3_X86/gem5.opt"]
        ret = subprocess.run(cmd, check=True)

def start():
    # docker run -it -v $(pwd):/sim/ gem5
    cmd = ["docker", "run", "--name", "py_g5_docker", "-it", "-d",  "-v"+os.getcwd()+":/sim/", "gem5"]
    ret = subprocess.run(cmd, check=True)

def stop():
    cmd = ["docker", "stop", "py_g5_docker"]
    ret = subprocess.run(cmd, check=True)

    cmd = ["docker", "rm", "py_g5_docker"]
    ret = subprocess.run(cmd, check=True)

def hipcc(f):
    fname = os.path.splitext(f)[0]

    cmd = ["docker", "exec", "py_g5_docker", "hipcc", "/sim/"+f, "-o", "/sim/"+fname+".out", "--amdgpu-target=gfx801"]
    ret = subprocess.run(cmd, check=True)

def run(f):
    cmd = ["docker", "exec", "py_g5_docker", "/sim/gem5/build/GCN3_X86/gem5.opt", "/sim/gem5/configs/example/apu_se.py",
           "-n2", "-c/sim/"+f]
    ret = subprocess.run(cmd, check=True)


def main():
    pargs = parseArgs()

    print('Your command was {}'.format(pargs.command))

    try:
        cmd = Command[pargs.command]
    except:
        sys.exit("Invalid argument")

    if cmd == Command.build:
        build(pargs.program)
    if cmd == Command.start:
        start()
    if cmd == Command.stop:
        stop()
    if cmd == Command.hipcc:
        hipcc(pargs.file)
    if cmd == Command.run:
        run(pargs.file)


if __name__ == '__main__':
    main()
