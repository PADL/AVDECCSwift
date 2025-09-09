#!/bin/bash

set -e

#git submodule init
#git submodule update

#pushd Sources/CAVDECC/avdecc
#git submodule init
#git submodule update
#popd

ARCH=`arch`

if [ "$ARCH" == "aarch64" ]; then
    ARCH=arm64
elif [ "$ARCH" == "x86_64" ]; then
    ARCH=x64
fi

PLATFORM=`uname`

if [ "$PLATFORM" == "Linux" ]; then
    PLATFORM=linux
elif [ "$PLATFORM" == "Darwin" ]; then
    PLATFORM=mac
fi

if [ "$PLATFORM" == "mac" ]; then
    export PATH="$(brew --prefix grep)/libexec/gnubin:$(brew --prefix bash)/bin:$PATH"
    ARCHS="-arch x64 -arch arm64"
    CLANGDIR=
    SOSUFFIX=dylib
    ARCH=x64_arm64
    CONFIG=release
    BUILDCFLAGS="-Wno-error=deprecated-declarations -fblocks"
    BUILDLDFLAGS_SHARED=""
    BUILDLDFLAGS_STATIC=""
else
    ARCHS="-arch ${ARCH}"
    CLANGDIR=/opt/swift
    SOSUFFIX=so
    CONFIG=release
    BUILDCFLAGS="-I${CLANGDIR}/usr/lib/swift -fblocks"
    BUILDLDFLAGS_SHARED="-L${CLANGDIR}/usr/lib/swift/${PLATFORM} -Wl,-rpath,${CLANGDIR}/usr/lib/swift/${PLATFORM} -lBlocksRuntime"
    BUILDLDFLAGS_STATIC="-Wl,-L${CLANGDIR}/usr/lib/swift_static/${PLATFORM} -lBlocksRuntime"
fi

# for macOS, build release as otherwise artifact bundle exceeds non-LFS GH size
BUILDDIR="_build_${PLATFORM}_${ARCH}_makefiles_${CONFIG}"

pushd Sources/CAVDECC/avdecc
echo "Build directory is $BUILDDIR with flags $BUILDFLAGS"
rm -rf $BUILDDIR
./gen_cmake.sh ${ARCHS} \
    -a "-DCMAKE_C_COMPILER=${CLANGDIR}/usr/bin/clang" \
    -a "-DCMAKE_C_FLAGS=${BUILDCFLAGS}" \
    -a "-DCMAKE_CXX_COMPILER=${CLANGDIR}/usr/bin/clang++" \
    -a "-DCMAKE_CXX_FLAGS=${BUILDCFLAGS}" \
    -a "-DCMAKE_SHARED_LINKER_FLAGS=${BUILDLDFLAGS_SHARED}" \
    -a "-DCMAKE_STATIC_LINKER_FLAGS=" \
    -a "-DBUILD_AVDECC_INTERFACE_PCAP_DYNAMIC_LINKING=ON" \
    -a "-DENABLE_AVDECC_FEATURE_JSON=OFF" \
    -a "-DBUILD_AVDECC_LIB_STATIC_RT_SHARED=FALSE" \
    -a "-DINSTALL_AVDECC_LIB_STATIC=FALSE" \
    -a "-DBUILD_AVDECC_CONTROLLER=TRUE" \
    -a "-DBUILD_AVDECC_EXAMPLES=FALSE" \
    -a "-DBUILD_AVDECC_TESTS=FALSE" \
    -c "Unix Makefiles" \
    "-${CONFIG}" \
    -build-c

cp ../../../info.json.in info.json
pushd $BUILDDIR
make -j9
popd

zip --symlinks -r ../../../avdecc.artifactbundle.zip info.json include \
    $BUILDDIR/src/controller/libla_avdecc_controller_cxx* \
    $BUILDDIR/src/bindings/c/libla_avdecc_c* \
    $BUILDDIR/src/libla_avdecc_cxx*
