FROM ubuntu:16.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    findutils \
    file \
    libunwind8 \
    libunwind-dev \
    pkg-config \
    build-essential \
    gcc-multilib \
    g++-multilib \
    git \
    ca-certificates \
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
    cmake \
    openssl \
    libssl-dev \
    libboost-filesystem-dev \
    libboost-system-dev \
    libboost-dev


ARG rocm_ver=1.6.2

# Get files needed for gem5, and apply patches
RUN git clone --single-branch --branch agutierr/master-gcn3-staging https://gem5.googlesource.com/amd/gem5 && chmod 777 /gem5 && \
    git clone --single-branch https://github.com/ROCm-Developer-Tools/HIP/ && \
    git clone --single-branch https://github.com/ROCmSoftwarePlatform/hipBLAS/ && \
    git clone --single-branch https://github.com/ROCmSoftwarePlatform/rocBLAS/ && \
    git clone --single-branch https://github.com/ROCmSoftwarePlatform/MIOpenGEMM/ && \
    git clone --single-branch https://github.com/ROCmSoftwarePlatform/MIOpen/ && \
    git clone --single-branch https://github.com/RadeonOpenCompute/rocm-cmake/ && \
    git clone --single-branch https://github.com/rocmarchive/ROCm-Profiler.git


# Get and apply patches to various repos
COPY patch /patch

RUN git -C /gem5/ apply /patch/gem5.patch && \
    git -C /HIP/ checkout 0e3d824e && git -C /HIP/ apply /patch/hip.patch && \
    git -C /hipBLAS/ checkout ee57787e && git -C /hipBLAS/ apply /patch/hipBLAS.patch && \
    git -C /rocBLAS/ checkout cbff4b4e && git -C /rocBLAS/ apply /patch/rocBLAS.patch && \
    git -C /MIOpenGEMM/ checkout 9547fb9e && \
    git -C /MIOpen/ checkout a9949e30 && git -C /MIOpen/ apply /patch/miopen.patch

# Install default ROCm programs
RUN wget -qO- repo.radeon.com/rocm/archive/apt_${rocm_ver}.tar.bz2 \
    | tar -xjv \
    && cd apt_${rocm_ver}/pool/main/ \
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
ENV HIP_PATH ${ROCM_PATH}/hip
ENV HIP_PLATFORM hcc
ENV PATH ${ROCM_PATH}/bin:${HCC_HOME}/bin:${HSA_PATH}/bin:${HIP_PATH}/bin:${PATH}
ENV HCC_AMDGPU_TARGET gfx801

# Create build dirs for machine learning ROCm installs
RUN mkdir -p /HIP/build && \
    mkdir -p /rocBLAS/build && \
    mkdir -p /hipBLAS/build && \
    mkdir -p /rocm-cmake/build && \
    mkdir -p /MIOpenGEMM/build && \
    mkdir -p /MIOpen/build

# Do the builds
WORKDIR /HIP/build
RUN cmake .. && make -j$(nproc) && make install

WORKDIR /rocBLAS/build
RUN CXX=/opt/rocm/bin/hcc cmake -DCMAKE_CXX_FLAGS="--amdgpu-target=gfx801" .. && \
    make -j$(nproc) && make install && rm -rf *

WORKDIR /hipBLAS/build
RUN CXX=/opt/rocm/bin/hcc cmake -DCMAKE_CXX_FLAGS="--amdgpu-target=gfx801" .. && \
    make -j$(nproc) && make install && rm -rf *

WORKDIR /rocm-cmake/build
RUN cmake .. && cmake --build . --target install && rm -rf *

WORKDIR /MIOpenGEMM/build
RUN cmake .. && make miopengemm && make install && rm -rf *

RUN mkdir -p /.cache/miopen && chmod 777 /.cache/miopen

WORKDIR /MIOpen/build
RUN CXX=/opt/rocm/hcc/bin/hcc cmake \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_INSTALL_PREFIX=/opt/rocm \
    -DMIOPEN_BACKEND=HIP \
    -DCMAKE_PREFIX_PATH="/opt/rocm/hip;/opt/rocm/hcc;/opt/rocm/rocdl;/opt/rocm/miopengemm;/opt/rocm/hsa" \
    -DMIOPEN_CACHE_DIR=/.cache/miopen \
    -DMIOPEN_AMDGCN_ASSEMBLER_PATH=/opt/rocm/opencl/bin \
    -DCMAKE_CXX_FLAGS="-isystem /usr/include/x86_64-linux-gnu" .. && \
    make -j$(nproc) && make install && rm -rf *

# Create performance DB for gfx801. May need personal dbs still
WORKDIR /opt/rocm/miopen/share/miopen/db
RUN ln -s gfx803_64.cd.pdb.txt gfx801_8.cd.pdb.txt && \
    ln -s gfx803_64.cd.pdb.txt gfx801_16.cd.pdb.txt && \
    ln -s gfx803_64.cd.pdb.txt gfx801_32.cd.pdb.txt && \
    ln -s gfx803_64.cd.pdb.txt gfx801_64.cd.pdb.txt

WORKDIR /ROCm-Profiler
RUN dpkg -i package/rocm-profiler_4.0.6036_amd64.deb

WORKDIR /gem5
RUN scons -sQ -j$(nproc) build/GCN3_X86/gem5.opt --ignore-style && \
    mv build/GCN3_X86/gem5.opt /tmp && \
    rm -rf build && mkdir -p build/GCN3_X86 && \
    mv /tmp/gem5.opt build/GCN3_X86/gem5.opt

WORKDIR /

RUN mkdir /tmp2 && chmod 777 /tmp2
COPY tests/ tests/
CMD bash
