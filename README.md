## gem5 in docker for machine learning applications
### What does it do?
Grabs all of the repositories needed to run DNNMark applications on gem5

It uses docker to keep the environment in order

There's a wrapper script (g5gpu.py) that I used for common commands that I needed

### How do I build it?
Clone the repo using `git clone --recursive https://github.com/KyleRoarty/gem5_docker.git`\
Apply the patches in the `patch` directory to the submodule with the same name\
Run `g5gpu.py build docker` to build the docker image. The dockerfile may need to be updated with more apt packages, I forget\
Run `g5gpu.py build deps`. This runs all of the commands in `cmd/deps.txt` which are all of those submodules\
Run `g5gpu.py build gem5` to build gem5, or just build it yourself\

### How do I use it?
`g5gpu.py start` and `g5gpu.py stop` start and stop the docker container (stop removes it, too). The container is named `py_g5_docker`  
The repo directory is bound to `/sim/` in docker  

To run something in gem5: `docker exec py_g5_docker /sim/gem5/build/GCN3_X86/gem5.opt /sim/gem5/configs/example/apu_se.py -n2 -c<command> --options="<command options>"`  

### Something doesn't make sense? // TODOs
I probably installed a program manually in the docker container but failed to add it into the Dockerfile\
I also forgot to add DNNMark to the submodules. So anything involving DNNMark will break  
