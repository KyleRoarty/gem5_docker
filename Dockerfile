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
    wget \
    libpci3 \
    libelf1 \
    vim

# Get files needed for gem5, apply patches, build
RUN git clone --single-branch --branch agutierr/master-gcn3-staging https://gem5.googlesource.com/amd/gem5
COPY gem5.patch .
RUN git apply gem5.patch --directory=gem5

ARG rocm_ver=1.6.3
RUN wget -qO- repo.radeon.com/rocm/archive/apt_${rocm_ver}.tar.bz2 \
    | tar -xjv \
    && cd apt_${rocm_ver}/pool/main/ \
    && dpkg -i h/hsakmt-roct-dev/* \
    && dpkg -i h/hsa-ext-rocr-dev/* \
    && dpkg -i h/hsa-rocr-dev/* \
    && dpkg -i r/rocm-utils/* \
    && dpkg -i h/hcc/* \
    && dpkg -i h/hip_base/* \
    && dpkg -i h/hip_hcc/* \
    && dpkg -i h/hip_samples/*

ENV ROCM_PATH /opt/rocm
ENV HCC_HOME ${ROCM_PATH}/hcc
ENV HSA_PATH ${ROCM_PATH}/hsa
ENV HIP_PATH ${ROCM_PATH}/hip
ENV HIP_PLATFORM hcc
ENV PATH ${ROCM_PATH}/bin:${HCC_HOME}/bin:${HSA_PATH}/bin:${HIP_PATH}/bin:${PATH}

COPY tests/ tests/

CMD bash
