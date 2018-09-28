FROM ubuntu:16.04

RUN apt-get update && apt-get install -y \
    build-essential \
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
    python


WORKDIR /tmp
RUN git clone https://gem5.googlesource.com/amd/gem5 -b agutierr/master-gcn3-staging \
    && cd gem5 \
    && git status \
    && scons -j4 ./build/GCN3_X86/gem5.opt

CMD ["ls"]
