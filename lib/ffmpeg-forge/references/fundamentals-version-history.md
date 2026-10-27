# FFmpeg Version History

## Checking Your Version

```bash
# Check installed version
ffmpeg -version

# Check build configuration
ffmpeg -buildconf
```

## Official Sources for Latest Version

- Official Download Page: https://ffmpeg.org/download.html
- Official Git Repository: https://git.ffmpeg.org/gitweb/ffmpeg.git
- GitHub Releases: https://github.com/FFmpeg/FFmpeg/releases

## Current Releases (as of 2026-10)

- **9.0.2 "Lei"** (2026-09-18): latest stable. These references do not yet document 9.0-specific features; check https://ffmpeg.org/download.html and the changelog.
- **8.1.3 "Hoare"** (2026-09-21): latest on the 8.1 branch.
- **7.1.5**: latest on the 7.1 LTS branch.

## FFmpeg 8.0 "Huffman"

The 8.0 branch was cut from master on 2025-08-09 (8.0.1 released 2025-11-20).

FFmpeg 8.0 is one of the largest releases to date, named after the Huffman code algorithm invented in 1952.

### AI and Transcription

- **Whisper AI Filter**: Built-in speech recognition via whisper.cpp for live subtitle generation and transcription
- Supports 99 languages with automatic language detection
- Outputs to SRT, JSON, or plain text formats
- Voice Activity Detection (VAD) support with Silero VAD

### Vulkan Codecs (Cross-Platform GPU)

- **FFv1 Vulkan**: Encode and decode via Vulkan compute shaders
- **ProRes RAW Vulkan**: Decode via Vulkan compute shaders
- **AV1 Vulkan Encoder**: Fixed-function AV1 encode via Vulkan Video (`VK_KHR_video_encode_av1`)
- **VP9 Vulkan Decoder**: Fixed-function VP9 decode via Vulkan Video (`VK_KHR_video_decode_vp9`)
- The compute-based codecs (FFv1, ProRes RAW) run on any Vulkan 1.3 compute-capable device; AV1 encode and VP9 decode need a driver/GPU that exposes the `VK_KHR_video_*` extensions

### New Codecs

- **APV Codec**: Samsung Advanced Professional Video encoder (via libopenapv) and native decoder
- **ProRes RAW Decoder**: Native Apple ProRes RAW decode
- **RealVideo 6.0 Decoder**: Native RV6 decode support
- **G.728 Decoder**: Low-delay CELP audio codec
- **Sanyo LD-ADPCM Decoder**: Sanyo audio format
- **ADPCM IMA Xbox Decoder**: Xbox audio format
- **libx265 Alpha Layer Encoding**: HEVC with alpha channel

### Hardware Acceleration

- **VVC VA-API Decoding**: H.266/VVC hardware decode on Intel/AMD Linux
- **OpenHarmony Support**: H.264/H.265 encode/decode for HarmonyOS platform

### New Features

- **WHIP Muxer**: Sub-second latency WebRTC ingestion
- **Animated JPEG XL Encoding**: Via libjxl library
- **FLV v2 Support**: Multitrack audio/video and modern codecs
- **VVC in Matroska**: H.266/VVC support in MKV container
- **VVC SCC Support**: Screen Content Coding with IBC, Palette Mode, ACT
- **TLS Verification**: Still off by default in 8.0 (`tls_verify` defaults to 0; the Changelog defers default-on to the next major version bump). Enable it with `-tls_verify 1` (plus `-ca_file` if needed)

### New Filters

- **whisper**: AI speech recognition filter
- **colordetect**: Detect JPEG/MPEG range and alpha channel properties
- **pad_cuda**: GPU-accelerated padding filter
- **scale_d3d11**: Direct3D 11 hardware scaling filter

### Breaking Changes

- **Dropped**: OpenSSL 1.1.0 support (requires 1.1.1+)
- **Dropped**: yasm assembler support (use nasm instead)
- **Deprecated**: OpenMAX encoders
- **Changed**: Default PNG prediction method set to PAETH
- **Changed**: GCC autovectorization no longer disabled on x86/ARM/AArch64

### Infrastructure

- New Forgejo-based code hosting at code.ffmpeg.org
- Modernized mailing list infrastructure

## FFmpeg 7.1 "Péter" LTS (September 2024)

- **VVC Decoder Stable**: Full native H.266/VVC decoder (production-ready)
- **MV-HEVC Decoder**: 3D HEVC for Apple Vision Pro / iPhone spatial video
- **LC-EVC Decoder**: MPEG-5 Part 2 enhancement layer
- **xHE-AAC Decoder**: Extended High Efficiency AAC
- **Vulkan H.264/H.265 Encoders**: GPU encoding via Vulkan Video
- **Native Intel QSV VVC Decoder**: Hardware-accelerated VVC
- **AVX2 VVC Optimizations**: Faster software VVC decoding
- **Full-Range Color Fixes**: Correct color range handling throughout pipeline

## Staying Up-to-Date

### Why Version Matters

- Security fixes: Patch releases address vulnerabilities
- Bug fixes: Issues with specific codecs or filters get resolved
- New features: Major versions add codec support and filters
- Performance: Optimizations improve encoding speed

### Recommended Update Strategy

1. **Production**: Use LTS releases (7.1) for stability, apply patch updates
2. **Development**: Use the latest stable release (9.0.x as of 2026-10) for new features
3. **Always**: Check release notes before upgrading

### Official Resources

- Release Notes: https://ffmpeg.org/download.html
- Security Advisories: https://ffmpeg.org/security.html
- Mailing Lists: https://ffmpeg.org/contact.html
