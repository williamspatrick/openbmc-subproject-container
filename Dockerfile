FROM ubuntu:plucky

# Update and install base dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    lsb-release \
    software-properties-common \
    python3 \
    python3-pip \
    python3-venv \
    ca-certificates \
    pkg-config \
    cmake \
    git \
    && rm -rf /var/lib/apt/lists/*

# Add LLVM repository for clang-21
# Try plucky first, fall back to oracular/noble if needed
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor -o /usr/share/keyrings/llvm-archive-keyring.gpg && \
    (echo "deb [signed-by=/usr/share/keyrings/llvm-archive-keyring.gpg] http://apt.llvm.org/plucky/ llvm-toolchain-plucky-21 main" > /etc/apt/sources.list.d/llvm.list || \
     echo "deb [signed-by=/usr/share/keyrings/llvm-archive-keyring.gpg] http://apt.llvm.org/oracular/ llvm-toolchain-oracular-21 main" > /etc/apt/sources.list.d/llvm.list || \
     echo "deb [signed-by=/usr/share/keyrings/llvm-archive-keyring.gpg] http://apt.llvm.org/noble/ llvm-toolchain-noble-21 main" > /etc/apt/sources.list.d/llvm.list)

# Update package lists with new repositories
RUN apt-get update || true

# Install GCC 15 and G++ 15 (or available version)
RUN apt-get install -y \
    gcc-15 \
    g++-15 \
    || apt-get install -y gcc g++ \
    && rm -rf /var/lib/apt/lists/*

# Install libsystemd development files and other build dependencies
RUN apt-get update && apt-get install -y \
    libsystemd-dev \
    libgtest-dev \
    libgmock-dev \
    && rm -rf /var/lib/apt/lists/*

# Build and install Boost 1.89.0 from source with required libraries
RUN cd /tmp && \
    wget -O boost-1.89.0-cmake.tar.gz https://github.com/boostorg/boost/releases/download/boost-1.89.0/boost-1.89.0-cmake.tar.gz && \
    tar xzf boost-1.89.0-cmake.tar.gz && \
    cd boost-1.89.0 && \
    ./bootstrap.sh --prefix=/usr/local --with-libraries=atomic,context,coroutine,filesystem,process,url && \
    ./b2 -j$(nproc) && \
    ./b2 install --prefix=/usr/local valgrind=on && \
    cd / && \
    rm -rf /tmp/boost-1.89.0-cmake.tar.gz /tmp/boost-1.89.0 && \
    ldconfig

# Set GCC 15 as default if available
RUN (update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-15 150 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-15 150) || true

# Install Clang 21 and related tools (try with version suffix, fall back to unversioned)
RUN apt-get update && apt-get install -y \
    clang-21 \
    clang-format-21 \
    clang-tidy-21 \
    lldb-21 \
    lld-21 \
    || apt-get install -y clang clang-format clang-tidy lldb lld \
    && rm -rf /var/lib/apt/lists/*

# Set Clang as default if versioned binaries exist
RUN (update-alternatives --install /usr/bin/clang clang /usr/bin/clang-21 210 && \
    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-21 210 && \
    update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-21 210 && \
    update-alternatives --install /usr/bin/clang-tidy clang-tidy /usr/bin/clang-tidy-21 210) || true

# Install Python packages via pip
RUN pip3 install --break-system-packages \
    inflection \
    mako \
    pyyaml \
    jsonschema

# Install meson (will be at least 1.10.1 in Ubuntu plucky) and ninja
RUN apt-get update && apt-get install -y ninja-build && rm -rf /var/lib/apt/lists/*
RUN pip3 install --break-system-packages meson

# Verify installations
RUN echo "=== Installed Versions ===" && \
    echo "GCC:" && (gcc --version | head -1 || echo "GCC not found") && \
    echo "G++:" && (g++ --version | head -1 || echo "G++ not found") && \
    echo "Clang:" && (clang --version | head -1 || echo "Clang not found") && \
    echo "Clang-format:" && (clang-format --version || echo "not found") && \
    echo "Clang-tidy:" && (clang-tidy --version || echo "not found") && \
    echo "Meson:" && meson --version && \
    echo "Python:" && python3 --version && \
    pip3 list | grep -E "(inflection|mako|pyyaml)" || true

WORKDIR /workspace