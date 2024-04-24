AVDECCSwift
===========

AVDECCSwift is an async Swift wrapper around the L-Acoustics [AVDECC library](https://github.com/L-Acoustics/avdecc).

Note: currently this uses the C bindings for AVDECC, which results in some unnecessary copies and some slight impedence mismatches. As Swift's C++ interoperability improves to support virtual member functions and bridging blocks to `std::function`, we will migrate this wrapper to use the native C++ library. This may result in some source-breaking changes to API consumers.

Note: the size of the artifact bundle now requires Git Large FIle Storage. Make sure [`git-lfs`](https://docs.github.com/en/repositories/working-with-files/managing-large-files/installing-git-large-file-storage) is installed.

