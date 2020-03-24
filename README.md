## gem5 in docker for machine learning
### What is it?
This builds a docker image that contains gem5, ROCm, and MIOpen (using HIP). It's intended for running machine learning/machine intelligence programs in the APU model in the GCN3 branch of gem5.

The container uses ROCm 1.6.2; This can be overridden when building the docker image.

### How to build/run?
[The dockerhub repo](https://cloud.docker.com/repository/registry-1.docker.io/kroarty/gem5) Will contain an image for this branch soon. Currently it only has the non-ML-enabled image.

From source:
```
docker build [--build-arg rocm_ver=<version>] -t <im_name> .
docker run [--name <container_name>] -it [-d] <im_name> [<command>]
```
If '-d' is specified, the container will run in the background \
If '\<command\>' isn't specified, the container will run a bash shell

### Working applications

The following are a list of applications that have been tested to run in gem5 using this dockerfile. Because the current model in the GPU staging branch is an APU, the majority of these applications are patched to remove unneeded hipMemcpy calls.

Repo | Application | Notes
--- | --- |  ---
[DNNMark](https://github.com/doody1986/DNNMark.git) | dnnmark_test_fwd_softmax | Patch in tests dir, requires pre-generated MIOpen kernels
[DeepBench](https://github.com/baidu-research/DeepBench) | rnn_bench | Requires pre-generated MIOpen kernels, uses rocBLAS
|| conv_bench | Slow. Requires pre-generated MIOpen kernels, uses MIOpenGEMM. WIP patch to use rocBLAS instead
[HIP samples](https://github.com/ROCm-Developer-Tools/HIP) | square | Patch in tests dir
|| bit_extract | In HIP/samples/0_intro. This and all following applications are pre-patched from hip.patch file
|| MatrixTranspose | This and all following applications are in HIP/samples/2_Cookbook
|| hipEvent
|| Profiler
|| shfl | [Requires patch for gem5](https://gem5-review.googlesource.com/c/amd/gem5/+/26443)
|| 2dshfl | [Requires patch for gem5](https://gem5-review.googlesource.com/c/amd/gem5/+/26443)
|| dynamic_shared
|| unroll
|| inline_asm

### Tests

```
export UID
docker-compose -f docker-compose.test.yml [-p <name>] build
docker-compose -f docker-compose.test.yml [-p <name>] up
```

To clean up the container used for tests:
```
docker-compose -f docker-compose.test.yml [-p <name>] down
```

### Misc

* Why ROCm 1.6.2?

It's the most recent of ROCm 1.6.x that successfully runs both sets of tests across the machine learning/intelligence branch and the non-machine learning/intelligence branch.
* Why can't we use ROCm 1.6.0?

It unpacks into a different directory structure than 1.6.1-1.6.4; This can be changed in the dockerfile, line 67. After ${rocm_ver}, add '/debian' and it will build

### ToDo
* Allow building with docker-compose
