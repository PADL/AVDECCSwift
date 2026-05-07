#!/bin/bash

set -e

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
    SOSUFFIX=so
    CONFIG=release
    BUILDCFLAGS="-fblocks"
fi

# for macOS, build release as otherwise artifact bundle exceeds non-LFS GH size
BUILDDIR="_build_${PLATFORM}_${ARCH}_makefiles_${CONFIG}"

pushd Sources/CxxAVDECC/avdecc
echo "Build directory is $BUILDDIR with flags $BUILDFLAGS"
rm -rf $BUILDDIR
./gen_cmake.sh ${ARCHS} \
    -a "-DCMAKE_C_COMPILER=${CLANGDIR}/usr/bin/clang" \
    -a "-DCMAKE_C_FLAGS=${BUILDCFLAGS}" \
    -a "-DCMAKE_CXX_COMPILER=${CLANGDIR}/usr/bin/clang++" \
    -a "-DCMAKE_CXX_FLAGS=${BUILDCFLAGS}" \
    -a "-DCMAKE_SHARED_LINKER_FLAGS=${BUILDLDFLAGS_SHARED}" \
    -a "-DCMAKE_STATIC_LINKER_FLAGS=" \
    -a "-DBUILD_AVDECC_INTERFACE_PCAP_DYNAMIC_LINKING=OFF" \
    -a "-DENABLE_AVDECC_FEATURE_JSON=OFF" \
    -a "-DBUILD_AVDECC_LIB_STATIC_RT_SHARED=FALSE" \
    -a "-DINSTALL_AVDECC_LIB_STATIC=FALSE" \
    -a "-DBUILD_AVDECC_CONTROLLER=TRUE" \
    -a "-DBUILD_AVDECC_EXAMPLES=FALSE" \
    -a "-DBUILD_AVDECC_TESTS=FALSE" \
    -c "Unix Makefiles" \
    "-${CONFIG}"

cp ../../../info.json.in info.json
pushd $BUILDDIR
make -j9
popd

# Stage la_avdecc + nih headers under one tree so the artifact bundle ships
# both. la_avdecc public headers `#include <la/networkInterfaceHelper/...>`
# from the nih external; without those in the bundle, consumers' clang
# importer can't parse the la_avdecc headers when they pull in CxxAVDECC.
cp -r externals/nih/include/la/networkInterfaceHelper include/la/

# C bindings (la_avdecc_c) intentionally not built/shipped — Swift talks to
# la_avdecc directly via Swift 6 C++ interop in the CxxAVDECC target, so we
# only need the C++ library and the controller library.
zip -d ../../../avdecc.artifactbundle.zip '*.dSYM*' 2>/dev/null || true
zip --symlinks -r ../../../avdecc.artifactbundle.zip info.json include \
    $BUILDDIR/src/controller/libla_avdecc_controller_cxx* \
    $BUILDDIR/src/libla_avdecc_cxx* \
    -x '*.dSYM*'

# Remove the staged nih headers so the la_avdecc submodule stays clean.
rm -rf include/la/networkInterfaceHelper
