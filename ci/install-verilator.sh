#!/bin/bash
set -e
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

if [ -z ${NUM_JOBS} ]; then
    NUM_JOBS=1
fi

VERILATOR_VERSION="5.020"

# Check if system Verilator is available and matches the required version
if command -v verilator &> /dev/null; then
    SYSTEM_VER=$(verilator --version | grep -oP '[0-9]+\.[0-9]+' | head -1)
    if [ "$SYSTEM_VER" = "$VERILATOR_VERSION" ]; then
        echo "Using system Verilator $SYSTEM_VER"
        if [ -z "$VERILATOR_ROOT" ]; then
            export VERILATOR_ROOT=$(dirname $(dirname $(which verilator)))
        fi
        exit 0
    else
        echo "System Verilator version $SYSTEM_VER found, required $VERILATOR_VERSION"
    fi
fi

# Install from source if VERILATOR_ROOT is set and not already installed
if [ -n "$VERILATOR_ROOT" ] && [ ! -e "$VERILATOR_ROOT/bin/verilator" ]; then
    echo "Installing Verilator $VERILATOR_VERSION from source"
    mkdir -p $ROOT/tmp
    cd $ROOT/tmp
    rm -f verilator*.tar.gz
    wget -O verilator-${VERILATOR_VERSION}.tar.gz \
        https://github.com/verilator/verilator/archive/refs/tags/v${VERILATOR_VERSION}.tar.gz
    tar xzf verilator-${VERILATOR_VERSION}.tar.gz
    rm -f verilator-${VERILATOR_VERSION}.tar.gz
    cd verilator-${VERILATOR_VERSION}
    mkdir -p $VERILATOR_ROOT
    autoconf && ./configure --prefix="$VERILATOR_ROOT" && make -j${NUM_JOBS}
    make install
    make test
else
    echo "Using Verilator from cached directory or system."
fi
