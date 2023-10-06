export GEM_FORGE_TOP=$(pwd)
export CORES=$(nproc --all)
# You can change this to store result to different place.
export GEM_FORGE_RESULT_PATH=$GEM_FORGE_TOP/result
export GEM_FORGE_BENCHMARK_PATH=$GEM_FORGE_TOP/benchmarks

export LLVM_SRC_LIB_PATH=$GEM_FORGE_TOP/llvm/llvm/lib
export LLVM_DEBUG_INSTALL_PATH=$GEM_FORGE_TOP/llvm/install-debug
export LLVM_RELEASE_INSTALL_PATH=$GEM_FORGE_TOP/llvm/install-release
export LIBUNWIND_INC_PATH=$GEM_FORGE_TOP/llvm/libunwind/include

export GEM_FORGE_TRANSFORM_PATH=$GEM_FORGE_TOP/transform
export GEM_FORGE_GEM5_PATH=$GEM_FORGE_TOP/gem5

export PROTOBUF_INSTALL_PATH=$GEM_FORGE_TOP/build

export PATH=$LLVM_RELEASE_INSTALL_PATH/bin:$PROTOBUF_INSTALL_PATH/bin:$PATH
export CPATH=$PROTOBUF_INSTALL_PATH/include
export LIBRARY_PATH=$PROTOBUF_INSTALL_PATH/lib
