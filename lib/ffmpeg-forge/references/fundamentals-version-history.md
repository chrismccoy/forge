# FFmpeg Version History

Feature lists for FFmpeg 8.0 and 7.1 LTS, a checklist of version-sensitive claims in this skill, and update guidance. Last verified: 2026-10 against 8.0.1.

## Contents

- [Checking the Installed Version](#checking-the-installed-version)
- [Official Sources for Latest Version](#official-sources-for-latest-version)
- [Current Releases](#current-releases)
- [Version-Sensitive Claims](#version-sensitive-claims)
- [FFmpeg 8.0 "Huffman"](#ffmpeg-80-huffman)
- [FFmpeg 7.1 "Péter" LTS (September 2024)](#ffmpeg-71-péter-lts-september-2024)
- [Staying Up-to-Date](#staying-up-to-date)

## Checking the Installed Version

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

## Current Releases

Release numbers and patch levels change often. Check https://ffmpeg.org/download.html for the current stable release and the latest patch on each branch (including the 7.1 LTS branch). These references cover 7.1 LTS and 8.x; features added in 9.0 or later are not documented here.

## Version-Sensitive Claims

Changes in FFmpeg 8.1 and 9.0 have not been reviewed for this skill. The claims below depend on the version and were checked on 8.0.1 only. Re-check them after an upgrade with the command given; the SKILL.md section that relies on each is named so it can be updated.

| Claim | Where in SKILL.md | Re-check command | Result on 8.0.1 |
|---|---|---|---|
| 8.x overwrites the output options `-color_primaries`/`-color_trc` with the frame's values, so tags must be set with `setparams` | Non-Negotiable Rules, "Delivery defaults" (Color) | `ffmpeg -f lavfi -i testsrc2 -t 1 -pix_fmt yuv420p -color_primaries bt709 -color_trc bt709 -colorspace bt709 c.mp4` then `ffprobe -v error -show_entries stream=color_primaries,color_transfer c.mp4` | Primaries and transfer `unknown` (only `colorspace` kept); the `setparams` form gives `bt709` for all three |
| `-crf` alone gives constant quality on `libvpx-vp9`/`libaom-av1` in 8.x; `-b:v 0` is needed on older builds | Anti-Patterns (`-crf` with nonzero `-b:v`) | `ffmpeg -i in.mp4 -t 1 -c:v libvpx-vp9 -crf 31 -an v.webm` and watch for a "bitrate not specified" warning | No warning; encode runs at q=31 |
| Animating `drawtext` `fontsize` with a time expression segfaults on some 8.0.1 builds | Anti-Patterns (drawtext `fontsize`) | `ffmpeg -i in.mp4 -t 1 -vf "drawtext=text=A:fontsize='20+10*t'" -f null -` | Segmentation fault, exit code 139 (Ubuntu 8.0.1) |
| The `whisper` filter exists from 8.0 and needs `--enable-whisper` | Scripts table (`generate-whisper-subtitles.sh`), Anti-Patterns (`whisper` writes via `destination=`) | `ffmpeg -h filter=whisper` | `Unknown filter 'whisper'.` on the Ubuntu build (not compiled in); options checked against the 8.0 source |
| Latest stable release named in the version-coverage note | Version coverage paragraph at the top | https://ffmpeg.org/download.html | Changes with each release |

Other version-dependent statements in the references: the WHIP muxer (8.0+, `streaming.md`), Vulkan codec availability (7.1/8.0, `fundamentals-vulkan-compute-codecs.md`), `pad_cuda` (8.0+), `tls_verify` still defaulting to 0 in 8.0, and `-/filter_complex` replacing the deprecated `-filter_complex_script`.

## FFmpeg 8.0 "Huffman"

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
- **VVC SCC Support (native decoder)**: decodes Screen Content Coding tools (IBC, Palette Mode, ACT)
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
2. **Development**: Use the latest stable release (see https://ffmpeg.org/download.html) for new features
3. **Always**: Check release notes before upgrading

### Official Resources

- Release Notes: https://ffmpeg.org/download.html
- Security Advisories: https://ffmpeg.org/security.html
- Mailing Lists: https://ffmpeg.org/contact.html
