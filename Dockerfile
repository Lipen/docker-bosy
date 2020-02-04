FROM swift:xenial as build

# Install dependencies
RUN mv /usr/lib/python2.7/site-packages /usr/lib/python2.7/dist-packages \
 && ln -s dist-packages /usr/lib/python2.7/site-packages\
 && apt-get update \
 && apt-get install --no-install-recommends -y \
    # For BoSy:
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
 && curl -sSL https://get.haskellstack.org | sh \
 && stack setup \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /bosy

# Build required tools
RUN git clone https://github.com/reactive-systems/BoSy . \
 && sed -i 's/\bmake\b/$(MAKE)/g' Makefile \
 && make -j8 required-tools

# Build BoSy
RUN swift build --configuration release -Xcc -O3 -Xcc -DNDEBUG -Xswiftc -Ounchecked --jobs 8 \
 && cp .build/release/BoSy /usr/local/bin

ENTRYPOINT ["/usr/local/bin/BoSy"]
CMD ["--help"]
