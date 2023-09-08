#!/bin/bash

set -e

git submodule init
git submodule update

ARCH=`arch`

if [ "$ARCH" == "aarch64" ]; then
    ARCH=arm64;
fi

PLATFORM=`uname`
PLATFORM=${PLATFORM,,}

if [ "$PLATFORM" == "darwin" ]; then
    SOSUFFIX=dylib;
else
    SOSUFFIX=so;
fi;

BUILDDIR="_build_${PLATFORM}_${ARCH}_makefiles_debug"

pushd Sources/CAVDECC/avdecc
echo "Build directory is $BUILDDIR"
#rm -rf $BUILDDIR
bash gen_cmake.sh -arch ${ARCH} -debug -build-c

cp ../../../info.json.in info.json
pushd $BUILDDIR
make -j13
popd

zip --symlinks -r ../../../avdecc.artifactbundle.zip info.json include \
    $BUILDDIR/src/controller/libla_avdecc_controller_cxx*.${SOSUFFIX}* \
    $BUILDDIR/src/bindings/c/libla_avdecc_c*.${SOSUFFIX}* \
    $BUILDDIR/src/libla_avdecc_cxx*.${SOSUFFIX}*

