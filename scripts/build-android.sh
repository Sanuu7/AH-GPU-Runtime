#!/usr/bin/env bash
set -euo pipefail
runtime_root=$(cd "$(dirname "$0")/.." && pwd)
runtime_sdk=${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/.local/share/android-toolchain/android-sdk}}
runtime_ndk=${ANDROID_NDK_HOME:-$runtime_sdk/ndk/27.2.12479018}
if [[ ! -f "$runtime_ndk/build/cmake/android.toolchain.cmake" ]]; then
    echo 'Install Android NDK 27.2.12479018 or set ANDROID_NDK_HOME.' >&2
    exit 1
fi
runtime_cmake=${CMAKE:-cmake}
runtime_strip=$(find "$runtime_ndk/toolchains/llvm/prebuilt" -path '*/bin/llvm-strip' -print -quit)
for runtime_abi in arm64-v8a x86_64; do
    "$runtime_cmake" -S "$runtime_root" -B "$runtime_root/build/$runtime_abi" -G Ninja \
        -DCMAKE_TOOLCHAIN_FILE="$runtime_ndk/build/cmake/android.toolchain.cmake" \
        -DANDROID_ABI="$runtime_abi" -DANDROID_PLATFORM=android-26 \
        -DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON -DCMAKE_BUILD_TYPE=Release \
        -DFETCHCONTENT_BASE_DIR="$runtime_root/.cache/$runtime_abi"
    "$runtime_cmake" --build "$runtime_root/build/$runtime_abi" --target ggml-vulkan --parallel "${BUILD_JOBS:-2}"
    runtime_library=$(find "$runtime_root/build/$runtime_abi" -name libggml-vulkan.so -print -quit)
    mkdir -p "$runtime_root/build/stripped/$runtime_abi"
    "$runtime_strip" --strip-unneeded -o "$runtime_root/build/stripped/$runtime_abi/libggml-vulkan.so" "$runtime_library"
done
python3 "$runtime_root/scripts/package.py"
