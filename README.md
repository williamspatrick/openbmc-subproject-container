# OpenBMC Subproject Container

A Docker container development environment for building and testing OpenBMC
subprojects.

## Overview

This repository provides a containerized build environment specifically tailored
for OpenBMC code repositories. It includes all necessary compilers, libraries,
and tools required to build C++ projects assuming they have a well-formed meson
subproject-build process.

## Prerequisites

- Podman or Docker installed
- Git repository containing your OpenBMC subproject

## Usage

### Quick Start

From within your OpenBMC subproject git repository:

```bash
# Build the image and run an interactive shell
/path/to/openbmc-subproject-container/launch

# Or specify a command to run
/path/to/openbmc-subproject-container/launch meson compile
/path/to/openbmc-subproject-container/launch meson test
```

### Commands

The `launch` script supports the following commands:

- `build` - Build the Docker image only
- `run` - Run the container with a specified command
- `both` - Build and then run (default)

### Examples

```bash
# Build the image
./launch build

# Run interactive bash in container
./launch run bash

# Build and compile your project
./launch both meson compile

# Build and run tests
./launch both meson test
```

## Building Subprojects

Inside the container, you can use standard Meson commands:

```bash
# Configure (if not already done)
meson setup builddir

# Compile
meson compile -C builddir

# Run tests
meson test -C builddir

# Install
meson install -C builddir
```
