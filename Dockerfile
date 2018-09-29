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

WORKDIR /sim

RUN wget -qO- repo.radeon.com/rocm/archive/apt_1.6.0.tar.bz2 \
    | tar -xjv \
    && cd apt_1.6.0/debian/pool/main/ \
    && dpkg -i h/hsakmt-roct-dev/* \
    && dpkg -i h/hsa-ext-rocr-dev/* \
    && dpkg -i h/hsa-rocr-dev/* \
    && dpkg -i r/rocm-utils/* \
    && dpkg -i h/hcc/* \
    && dpkg -i h/hip_base/* \
    && dpkg -i h/hip_hcc/* \
    && dpkg -i h/hip_samples/*

WORKDIR /sim

RUN git clone https://gem5.googlesource.com/amd/gem5 -b agutierr/master-gcn3-staging \
    && cd gem5 \
    && git status \
    && scons -j4 ./build/GCN3_X86/gem5.opt

ENV ROCM_PATH /opt/rocm
ENV HCC_HOME ${ROCM_PATH}/hcc
ENV HSA_PATH ${ROCM_PATH}/hsa
ENV HIP_PLATFORM hcc
ENV PATH ${ROCM_PATH}/bin:${PATH}

CMD ["ls"]
