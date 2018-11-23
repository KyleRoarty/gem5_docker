## gem5 in docker
### What does it do?
The main branch sets up the ROCm environment up to HIP using .deb files available on repo.radeon.com/rocm/archive.

The machine learning branch sets up the ROCm environment up to HCC. The user then needs to build the remaining packages to allow machine learning programs to run. 

### Build
Clone the repo using `git clone --recursive https://github.com/KyleRoarty/gem5_docker.git`\
Apply the patches in the `patch` directory to the submodule with the same name\
Build the docker image by running `docker build --build-arg rocm_ver=<version> -t gem5 .` creating a docker image "gem5".\
This downloads the archive version specified in the build command (or 1.6.0 by default) from repo.radeon.com/rocm/archive, and installs:\
**Master**
* hsakmt-roct-dev
* hsa-ext-rocr-dev
* hsa-rocr-dev
* rocm-utils
* hcc
* hip_base
* hip_hcc
* hip_samples

**Machine Learning**
* hsakmt-roct-dev
* hsa-ext-rocr-dev
* hsa-rocr-dev
* rocm-utils
* hcc

These are installed to /opt/rocm, and environment variables used in ROCm (ROCM_PATH, HCC_HOME, HSA_PATH, HIP_PLATFORM) are set.

Start a container:\
`docker run --name <container_name> -it -d -v/gem5/parent/dir:/sim/ gem5`\
Mapping the parent directory of gem5 to /sim/ in the docker container

**Machine Learning**\
Build the remaining dependencies manually. The commands to do so are found in cmd/deps.txt


Build gem5 in the docker container:\ 
`docker exec -w/sim/gem5 <container_name> scons -jN /sim/gem5/build/GCN3_X86/gem5.opt`

To run something in gem5:\
`docker exec <container_name> /sim/gem5/build/GCN3_X86/gem5.opt /sim/gem5/configs/example/apu_se.py -n2 -c<command> --options="<command options>"`  

### Something isn't working?
* A program may be missing a dependency run `docker exec <container_name> apt-get install -y <package>`
