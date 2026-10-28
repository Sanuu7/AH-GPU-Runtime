# AH GPU Runtime

This is the optional Vulkan backend for [AndroidHarness](https://github.com/Sanuu7/AndroidHarness). It lets people add GPU support when they need it, instead of downloading it with the app. CPU inference still works without it.

## What is here

The backend source and shaders are in `src/ggml-vulkan`. They come from the llama.cpp revision recorded in `UPSTREAM_REVISION`, with the Android compatibility adjustment used by AndroidHarness. The build fetches the matching ggml core and Vulkan headers with pinned checksums. Third-party licences are in `LICENSES`.

Generated libraries, downloads and release packages are kept out of Git. Your release files are in the local `packages` folder.

## Build it

You need Android NDK 27.2.12479018, CMake 3.22.1 or newer, Ninja, Python 3 and `glslc`.

```sh
./scripts/build-android.sh
```

Set `ANDROID_SDK_ROOT` if your Android SDK is somewhere else. This builds arm64-v8a and x86_64, then creates the compressed libraries, a manifest and checksums in `packages`.

## Publish a release

Create a GitHub Release with the tag `local-gpu-v1`. Attach the two `.so.gz` files from `packages`, along with `SHA256SUMS` and `THIRD_PARTY_NOTICES.txt`. Keep the filenames unchanged and retain older assets so older app versions can still download their matching runtime.

You can also run the build workflow. It saves the packages as a build artifact. Publishing is off by default; enable it explicitly when running the workflow if you want it to upload the release files.

## Matching the app

AndroidHarness verifies the library hash bundled with the app before loading a download. A newly built runtime will not replace the runtime expected by an existing app build. Build the app with the matching packages when changing this backend:

```sh
./gradlew :app:assembleRelease -PgpuRuntimePackages=/path/to/AH-GPU-Runtime/packages
```

For the Play build, use `-Pdistribution=play :app:bundleRelease` with the same package directory.

The GitHub app downloads from this repository. The Play Store app uses Google Play Feature Delivery. Both rely on the device's Vulkan driver; this repository does not provide drivers or model weights.
