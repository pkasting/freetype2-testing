#!/bin/bash
set -euxo pipefail

# Copyright 2019, 2021 by
# Armin Hasitzka, Ben Wagner.
#
# This file is part of the FreeType project, and may only be used, modified,
# and distributed under the terms of the FreeType project license,
# LICENSE.TXT.  By continuing to use, modify, or distribute this file you
# indicate that you have read the license and understand and accept it
# fully.

dir="${PWD}"
cd $( dirname $( readlink -f "${0}" ) ) # go to `/fuzzing/scripts/build'

path_to_src=$( readlink -f "../../../external/llvm-project" )
path_to_build="${path_to_src}/build"

if [[ "${#}" == "0" || "${1}" != "--no-init" ]]; then

    git submodule update --init --depth 1 "${path_to_src}"

    cd "${path_to_src}"

    git clean -dfqx
    git reset --hard
    git rev-parse HEAD

    mkdir "${path_to_build}" && cd "${path_to_build}"

    case ${SANITIZER} in
      address) LLVM_SANITIZER="Address" ;;
      undefined) LLVM_SANITIZER="Undefined" ;;
      memory) LLVM_SANITIZER="MemoryWithOrigins" ;;
      *) LLVM_SANITIZER="" ;;
    esac

    env | sort
    cmake \
      -GNinja ../llvm \
      -DCMAKE_BUILD_TYPE=Release \
      -DLLVM_ENABLE_PROJECTS="libcxx;libcxxabi" \
      -DCMAKE_C_COMPILER=${CC} \
      -DCMAKE_CXX_COMPILER=${CXX} \
      -DLLVM_USE_SANITIZER="${LLVM_SANITIZER}" \
      -DLIBCXX_ENABLE_SHARED=OFF \
      -DLIBCXXABI_ENABLE_SHARED=OFF
fi

if [[ -f "${path_to_build}/build.ninja" ]]; then
    cd "${path_to_build}"
    cmake --build . -- cxx cxxabi
fi

cd "${dir}"
