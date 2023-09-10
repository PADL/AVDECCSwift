#!/bin/bash

ARCH=`arch`

if [ "$ARCH" == "aarch64" ]; then
    ARCH=arm64;
elif [ "$ARCH" == "x86_64" ]; then
    ARCH=x64;
fi

PLATFORM=`uname`

if [ "$PLATFORM" == "Linux" ]; then
    PLATFORM=linux;
elif [ "$PLATFORM" == "Darwin" ]; then
    PLATFORM=mac;
fi

BUILDDIR="_build_${PLATFORM}_${ARCH}_makefiles_debug"
ARTIFACTS=.build/artifacts/avdeccswift/avdecc/$BUILDDIR/src

LD_LIBRARY_PATH=$ARTIFCATS:$ARTIFACTS/bindings/c:$ARTIFACTS/controller:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH

lldb .build/debug/$1

