FROM swift:xenial

## Fix python
RUN mv /usr/lib/python2.7/site-packages /usr/lib/python2.7/dist-packages &&\
    ln -s dist-packages /usr/lib/python2.7/site-packages

## Install BoSy dependencies
RUN apt-get update &&\
    apt-get install --no-install-recommends -y \
        # For BoSy and its Tools:
        bison \
        build-essential \
        clang \
        cmake \
        curl \
        flex \
        gcc \
        git \
        libantlr3c-dev \
        libbdd-dev \
        libboost-program-options-dev \
        libicu-dev \
        libreadline-dev \
        mercurial \
        unzip \
        vim-common \
        wget \
        zlib1g-dev \
        # For Haskell stack:
        ca-certificates \
        libgmp-dev \
    &&\
    curl -sSL https://get.haskellstack.org | sh &&\
    rm -rf /var/lib/apt/lists/*

WORKDIR /bosy-git
RUN \
    # Clone BoSy
    git clone https://github.com/reactive-systems/BoSy . &&\
    # Replace 'make' with '$(MAKE)' to allow '-j' option for recursive make calls
    sed -i 's/\bmake\b/$(MAKE)/g' Makefile

## Build Tools
RUN \
    # Build all tools required by BoSy
    # Note: some required tool calls 'stack setup',
    #  which uses the apt to initialize Haskell stack, so:
    #     1. update apt indices
    #     2. build necessary tool
    #     3. clear stack setup
    #     4. clear apt cache
    apt-get update &&\
    make -j8 required-tools &&\
    rm -rf ~/.stack &&\
    rm -rf /var/lib/apt/lists/* &&\
    # Create links for all tools executables
    find $(realpath Tools) -maxdepth 1 -type f -executable -exec ln -sv {} /usr/local/bin \; &&\
    # Remove all Tools sources
    make clean-source-tools

## Build BoSy
RUN \
    # Remove all relative paths ('./Tools/') to tool binaries
    find Sources Tests -type f -name "*.swift" -exec sed -i 's/.\/Tools\///g' {} + &&\
    # Build BoSy
    swift build --configuration release -Xcc -O3 -Xcc -DNDEBUG -Xswiftc -Ounchecked --jobs 8 &&\
    # Copy built binaries to /usr/local/bin
    find .build/release/ -maxdepth 1 -type f -executable -exec cp -v {} /usr/local/bin \; &&\
    # Remove swift build files
    swift package reset &&\
    rm -rf /tmp/org.llvm.clang.0
