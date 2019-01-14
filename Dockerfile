FROM ubuntu:16.04

RUN apt-get update && apt-get install -y \
    build-essential \
    gcc-multilib \
    g++-multilib \
    git \
    m4 \
    scons \
    zlib1g \
    zlib1g-dev \
    libprotobuf-dev \
    protobuf-compiler \
    libprotoc-dev \
    libgoogle-perftools-dev \
    python-dev \
    python \
    python-yaml \
    wget \
    libpci3 \
    libelf1 \
    libelf-dev \
    vim \
    cmake \
    cmake-qt-gui \
    libboost-program-options-dev \
    gfortran \
    openssl \
    libssl-dev \
    libboost-filesystem-dev \
    libboost-system-dev \
    libboost-dev \
    libgflags-dev \
    libgoogle-glog-dev

ARG rocm_ver=1.6.0

# Get files needed for gem5, and apply patches
RUN git clone --single-branch --branch agutierr/master-gcn3-staging https://gem5.googlesource.com/amd/gem5

RUN git clone --single-branch https://github.com/ROCm-Developer-Tools/HIP/
RUN git clone --single-branch https://github.com/ROCmSoftwarePlatform/hipBLAS/
RUN git clone --single-branch https://github.com/ROCmSoftwarePlatform/rocBLAS/
RUN git clone --single-branch https://github.com/ROCmSoftwarePlatform/MIOpenGEMM/
RUN git clone --single-branch https://github.com/ROCmSoftwarePlatform/MIOpen/
RUN git clone --single-branch https://github.com/RadeonOpenCompute/rocm-cmake/


# Get and apply patches to various repos
COPY patch /patch

RUN git -C /gem5/ apply /patch/gpusyscall.patch
RUN git -C /HIP/ checkout 0e3d824e && git -C /HIP/ apply /patch/hip.patch
RUN git -C /hipBLAS/ checkout ee57787e && git -C /hipBLAS/ apply /patch/hipBLAS.patch
RUN git -C /rocBLAS/ checkout cbff4b4e && git -C /rocBLAS/ apply /patch/rocBLAS.patch
RUN git -C /MIOpenGEMM/ checkout 9547fb9e
RUN git -C /MIOpen/ checkout a9949e30 && git -C /MIOpen/ apply /patch/miopen.patch

# Install default ROCm programs
RUN wget -qO- repo.radeon.com/rocm/archive/apt_${rocm_ver}.tar.bz2 \
    | tar -xjv \
    && cd apt_${rocm_ver}/debian/pool/main/ \
    && dpkg -i h/hsakmt-roct-dev/* \
    && dpkg -i h/hsa-ext-rocr-dev/* \
    && dpkg -i h/hsa-rocr-dev/* \
    && dpkg -i r/rocm-utils/* \
    && dpkg -i h/hcc/* \
    && dpkg -i r/rocm-opencl/* \
    && dpkg -i r/rocm-opencl-dev/*

ENV ROCM_PATH /opt/rocm
ENV HCC_HOME ${ROCM_PATH}/hcc
ENV HSA_PATH ${ROCM_PATH}/hsa
ENV HIP_PLATFORM hcc
ENV PATH ${ROCM_PATH}/bin:${PATH}

# Create build dirs for machine learning ROCm installs
RUN mkdir -p /HIP/build && \
    mkdir -p /rocBLAS/build && \
    mkdir -p /hipBLAS/build && \
    mkdir -p /rocm-cmake/build && \
    mkdir -p /MIOpenGEMM/build && \
    mkdir -p /MIOpen/build

# Do the builds
WORKDIR /HIP/build
RUN cmake .. && make -j9 && make install

WORKDIR /rocBLAS/build
RUN CXX=/opt/rocm/bin/hcc cmake -DCMAKE_CXX_FLAGS="--amdgpu-target=gfx801" .. && \
    make -j9 && make install

WORKDIR /hipBLAS/build
RUN CXX=/opt/rocm/bin/hcc cmake -DCMAKE_CXX_FLAGS="--amdgpu-target=gfx801" .. && \
    make -j9 && make install

WORKDIR /rocm-cmake/build
RUN cmake .. && cmake --build . --target install

WORKDIR /MIOpenGEMM/build
RUN cmake .. && make miopengemm && make install

WORKDIR /MIOpen/build
RUN CXX=/opt/rocm/hcc/bin/hcc cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=/opt/rocm -DMIOPEN_BACKEND=HIP -DCMAKE_PREFIX_PATH="/opt/rocm/hip;/opt/rocm/hcc;/opt/rocm/rocdl;/opt/rocm/miopengemm;/opt/rocm/hsa" -DMIOPEN_CACHE_DIR=/sim/.cache/miopen -DMIOPEN_AMDGCN_ASSEMBLER_PATH=/opt/rocm/opencl/bin -DCMAKE_CXX_FLAGS="-isystem /usr/include/x86_64-linux-gnu" .. && \
    make -j9 && make install

WORKDIR /
CMD cd gem5 && scons -j9 build/GCN3_X86/gem5.opt
