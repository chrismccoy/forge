# C++ facts
Covers: C++17/20/23 with CMake/vcpkg, abseil, Boost.Asio, Eigen, OpenMP, OpenCV, Dear ImGui, cross-compiling for iOS and Android
Verified: 2026-09-29 against official documentation. Re-verify facts older than 12 months.

## ABI and packaging

### CPP-01 std types across library boundaries need one ABI
- Trap: Plugins or prebuilt .so/.a files exchange `std::string`/`std::list` with code built by another toolchain or with other flags.
- Reality: Since GCC 5.1, libstdc++ has a dual ABI selected by `_GLIBCXX_USE_CXX11_ABI`. Mixing the settings gives link errors on `std::__cxx11` symbols or runtime breakage. On Android, only one C++ runtime may be used per app. STLs are mutually incompatible, and apps with several native .so files should use `libc++_shared`.
- Detect: "plugin SDK", "prebuilt binary", "ship .so", several native libs on Android with `c++_static`.
- Fix: Build everything with one toolchain and ABI setting, or put a C ABI at the boundary. On Android use `ANDROID_STL=c++_shared` when there is more than one .so.
- Source: Dual ABI - https://gcc.gnu.org/onlinedocs/libstdc++/manual/using_dual_abi.html ; NDK C++ support - https://developer.android.com/ndk/guides/cpp-support

### CPP-02 abseil has no stable ABI
- Trap: The app links against a system or prebuilt abseil from a different version, or ships abseil as a shared lib to plugins.
- Reality: Abseil states that its ABI may change without notice, and that binaries built with one version may not work with another.
- Detect: "system abseil", mixing gRPC/protobuf binaries with a separately built abseil.
- Fix: Build abseil from source in the same build (vcpkg, FetchContent or Bazel) with the same compiler and flags as every consumer.
- Source: Compatibility guidelines - https://abseil.io/about/compatibility

### CPP-03 absl::flat_hash_map is not pointer-stable or ordered
- Trap: Code keeps pointers or references into a flat_hash_map, or tests or outputs depend on iteration order.
- Reality: Rehash invalidates flat_hash_map iterators, references and pointers. node_hash_map keeps element addresses stable. Iteration order in both is not deterministic.
- Detect: "index of pointers into map", golden-file output from map iteration.
- Fix: Use node_hash_map or indices for stable handles, and sort before emitting output.
- Source: Swiss tables guide - https://abseil.io/docs/cpp/guides/container

## Concurrency

### CPP-04 Asio: strands and one outstanding write
- Trap: Several threads call `io_context::run()` and handlers touch a socket or session state with no strand, or `async_write` is issued per message as messages arrive.
- Reality: Handlers are serialized only when one thread runs the io_context (an implicit strand). Shared socket objects are unsafe to use concurrently. `async_write` requires that no other write run on the stream until it completes.
- Detect: thread pool plus Boost.Asio, "broadcast to sessions", fan-out writes.
- Fix: Bind each connection's handlers to a strand, and queue outgoing messages so there is exactly one write in flight.
- Source: Strands - https://www.boost.org/doc/libs/latest/doc/html/boost_asio/overview/core/strands.html ; async_write - https://www.boost.org/doc/libs/latest/doc/html/boost_asio/reference/async_write/overload1.html

### CPP-05 OpenMP is not available out of the box with Apple clang
- Trap: "OpenMP everywhere" in a CMake build for macOS with Xcode's compiler.
- Reality: Apple clang rejects `-fopenmp`, and Xcode does not ship `libomp`.
- Detect: OpenMP plus macOS or Xcode targets.
- Fix: Use Homebrew/LLVM clang or a separately built libomp (`-Xclang -fopenmp -lomp`), or make OpenMP optional in CMake.
- Source: OpenMP on macOS (R Project) - https://mac.r-project.org/openmp/

### CPP-06 A Dear ImGui context is single-threaded
- Trap: UI widgets are built from worker threads, or the game or camera consumes input while ImGui is focused.
- Reality: One ImGui context must not be used from several threads in parallel. The app must drop its own mouse and keyboard handling when `io.WantCaptureMouse`/`WantCaptureKeyboard` is set, while still feeding all input to ImGui.
- Detect: "render stats from worker thread", camera controls plus ImGui overlay.
- Fix: Build the UI on one thread with data snapshots. Gate app input on the WantCapture flags.
- Source: Dear ImGui FAQ - https://github.com/ocornut/imgui/blob/master/docs/FAQ.md

## Numerics and imaging

### CPP-07 Eigen fixed-size types in STL containers before C++17
- Trap: `std::vector<Eigen::Vector4d>` or structs with `Matrix4f` members are used in containers in a C++14 build.
- Reality: Before C++17, fixed-size vectorizable types in STL containers need `Eigen::aligned_allocator`, or they may crash on misalignment. C++17 on GCC 7+, clang 5+ or MSVC 19.12+ handles over-alignment.
- Detect: Eigen with a C++ standard below 17, or old aligned-allocator boilerplate.
- Fix: Compile as C++17 or later everywhere Eigen types cross, or use aligned_allocator.
- Source: Eigen STL containers - https://libeigen.gitlab.io/eigen/docs-nightly/group__TopicStlContainers.html

### CPP-08 OpenCV Mat copies share data; imread is BGR
- Trap: `cv::Mat b = a;` is treated as a snapshot, or decoded frames are passed to RGB models or textures unchanged.
- Reality: Mat copy and assignment copy only the header, so data is shared and reference-counted. A deep copy needs `clone()`/`copyTo()`. imread/imdecode return color channels in B G R order.
- Detect: frame queues or buffers of Mat across threads; "feed to TensorRT/OpenGL".
- Fix: Clone when handing frames to other stages, and convert with `cvtColor(..., COLOR_BGR2RGB)` where RGB is expected.
- Source: Mat tutorial - https://docs.opencv.org/4.13.0/d6/d6d/tutorial_mat_the_basic_image_container.html ; imgcodecs - https://docs.opencv.org/4.13.0/d4/da8/group__imgcodecs.html

## Mobile targets

### CPP-09 Android NDK defaults differ by build system
- Trap: The code relies on exceptions/RTTI (dynamic_cast, typeid, throw) and assumes the NDK behaves like desktop.
- Reality: In ndk-build, exceptions and RTTI are disabled by default. CMake enables both by default.
- Detect: ndk-build (Android.mk) plus exceptions or dynamic_cast.
- Fix: Use CMake, or set `APP_CPPFLAGS := -fexceptions -frtti`/`LOCAL_CPP_FEATURES`.
- Source: NDK C++ support - https://developer.android.com/ndk/guides/cpp-support

### CPP-10 iOS: no downloaded code and no JIT
- Trap: The iOS app downloads plugins, scripts or shader logic that changes features, or embeds a JIT (LuaJIT, a custom VM that emits machine code).
- Reality: App Review Guideline 2.5.2 forbids downloading or executing code that adds or changes features. The allow-jit (MAP_JIT) entitlement exists only for macOS, and LuaJIT disables its JIT compiler on iOS.
- Detect: "hot-load modules", "remote scripting", "JIT" in an iOS target.
- Fix: Bundle all code in the app. Use interpreters only for bundled content or content allowed under 4.7, and plan performance for interpreter mode.
- Source: App Review Guidelines - https://developer.apple.com/app-store/review/guidelines/ ; allow-jit entitlement - https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.cs.allow-jit ; LuaJIT install - https://luajit.org/install.html
