# Timestamps, Bitstream Filters, Metadata, Attachments, Disposition

Reference for advanced packet-level and container-level options.

## Contents

- [Advanced Timestamp Handling](#advanced-timestamp-handling)
- [Bitstream Filters (-bsf)](#bitstream-filters--bsf)
- [Metadata Mapping (-map_metadata)](#metadata-mapping--map_metadata)
- [Attachments](#attachments)
- [Disposition Flags](#disposition-flags)

## Advanced Timestamp Handling

```bash
# Copy timestamps exactly from input
ffmpeg -copyts -i input.mp4 -c copy output.mp4

# Copy timestamps but shift them to start at zero (-start_at_zero only has an
# effect together with -copyts; on its own it does nothing)
ffmpeg -copyts -start_at_zero -i input.mp4 -c copy output.mp4

# Offset input timestamps
ffmpeg -itsoffset 5 -i input.mp4 -c copy output.mp4  # Delay by 5 seconds

# Scale video timestamps (2x speed). Audio samples cannot be rescaled by
# changing timestamps, so drop the audio (or re-encode it with atempo=2)
ffmpeg -itsscale:v 0.5 -i input.mp4 -c copy -an output.mp4

# Handle negative timestamps
ffmpeg -i input.mp4 -avoid_negative_ts make_zero output.mp4
```

### Timestamp Modes

| Mode | Description |
|------|-------------|
| `make_non_negative` | Shift timestamps to be non-negative |
| `make_zero` | Shift to start at exactly zero |
| `auto` | Auto-select based on format |
| `disabled` | Don't adjust timestamps |

## Bitstream Filters (-bsf)

```bash
# Extract AnnexB NAL units for H.264
ffmpeg -i input.mp4 -c:v copy -bsf:v h264_mp4toannexb output.h264

# Normalize redundant PPS NAL units (fix for some Blu-ray H.264 streams whose
# extra PPSs change irrelevant parameters and confuse later processing)
ffmpeg -i input.mp4 -c:v copy -bsf:v h264_redundant_pps output.mp4

# HEVC in MP4 (length-prefixed, hvcC) to raw Annex B start-code stream
ffmpeg -i input.mp4 -c:v copy -bsf:v hevc_mp4toannexb output.hevc

# ADTS AAC (e.g. from MPEG-TS) into MP4: strips the ADTS headers and builds the
# AudioSpecificConfig MP4 needs (FFmpeg inserts this automatically for mp4/mov)
ffmpeg -i input.ts -c copy -bsf:a aac_adtstoasc output.mp4

# The reverse (MP4 AAC to a raw .aac file) needs no bsf: the adts muxer
# writes ADTS headers itself
ffmpeg -i input.mp4 -vn -c:a copy output.aac

# Remove H.264 filler data NAL units (type 12; type 6 is SEI. HEVC filler is 38)
ffmpeg -i input.mp4 -c:v copy -bsf:v filter_units=remove_types=12 output.mp4

# Metadata injection
ffmpeg -i input.mp4 -c:v copy -bsf:v h264_metadata=level=4.1 output.mp4
```

### Common Bitstream Filters

| Filter | Description |
|--------|-------------|
| `h264_mp4toannexb` | Convert H.264 to AnnexB format |
| `hevc_mp4toannexb` | Convert HEVC to AnnexB format |
| `aac_adtstoasc` | Remove ADTS headers, create MP4 AudioSpecificConfig (ADTS to ASC) |
| `extract_extradata` | Extract codec extradata |
| `h264_redundant_pps` | Normalize redundant PPS NAL units (Blu-ray fixup) |
| `h264_metadata` | Modify H.264 metadata |
| `hevc_metadata` | Modify HEVC metadata |
| `filter_units` | Filter NAL units |
| `dump_extra` | Dump extradata to packets |
| `prores_metadata` | Modify ProRes metadata |
| `vp9_superframe` | VP9 superframe handling |
| `av1_metadata` | Modify AV1 metadata |

## Metadata Mapping (-map_metadata)

### Syntax

```bash
-map_metadata[:metadata_spec_out] infile[:metadata_spec_in]
```

### Metadata Specifiers

| Specifier | Target |
|-----------|--------|
| `g` | Global file metadata |
| `s:stream_index` | Stream metadata |
| `s:v` / `s:a` / `s:s` | All video/audio/subtitle streams |
| `c:chapter_index` | Chapter metadata (output chapter must already exist; to copy chapters use `-map_chapters`) |
| `p:program_index` | Program metadata |

### Examples

```bash
# Copy all metadata from input to output
ffmpeg -i input.mp4 -map_metadata 0 -c copy output.mp4

# Copy global metadata only
ffmpeg -i input.mp4 -map_metadata:g 0:g -c copy output.mp4

# Strip all metadata (chapters are separate: -map_chapters -1 removes them too)
ffmpeg -i input.mp4 -map_metadata -1 -map_chapters -1 -c copy output.mp4

# Copy metadata from second input file
ffmpeg -i video.mp4 -i metadata_source.mp4 -map 0 -map_metadata 1 -c copy output.mp4

# Copy stream metadata from input stream 0 to output stream 0
ffmpeg -i input.mp4 -map_metadata:s:0 0:s:0 -c copy output.mp4

# Copy chapters with their titles/metadata (default: from the first input
# that has chapters). -map_metadata:c 0:c is NOT valid here: it fails with
# "Invalid chapter index 0 while processing metadata maps"
ffmpeg -i input.mp4 -map_chapters 0 -c copy output.mp4

# Take chapters from a second file / drop all chapters
ffmpeg -i input.mp4 -i chapters_source.mkv -map 0 -map_chapters 1 -c copy output.mp4
ffmpeg -i input.mp4 -map_chapters -1 -c copy output.mp4

# Copy all metadata, but set specific values
ffmpeg -i input.mp4 -map_metadata 0 -metadata title="New Title" -c copy output.mp4
```

### Metadata Manipulation

```bash
# Add/modify metadata
ffmpeg -i input.mp4 -metadata title="Video Title" -metadata artist="Creator" output.mp4

# Set stream-specific metadata (the MP4 muxer does not store a stream title;
# MKV does, so use MKV when titles matter)
ffmpeg -i input.mkv -metadata:s:v:0 title="Main Video" -metadata:s:a:0 language=eng -c copy output.mkv

# Set chapter metadata (the output must have chapters, e.g. copied from input)
ffmpeg -i input.mp4 -metadata:c:0 title="Chapter 1" -c copy output.mp4

# Remove specific metadata (set to empty)
ffmpeg -i input.mp4 -metadata comment= -c copy output.mp4
```

## Attachments

### Adding (-attach)

```bash
# Attach font file (for subtitles)
ffmpeg -i input.mkv -attach DejaVuSans.ttf \
  -metadata:s:t:0 mimetype=application/x-truetype-font \
  -c copy output.mkv

# Attach cover art
ffmpeg -i input.mp4 -attach cover.jpg \
  -metadata:s:t:0 mimetype=image/jpeg \
  -c copy output.mkv

# Multiple attachments
ffmpeg -i input.mkv \
  -attach font1.ttf -metadata:s:t:0 mimetype=application/x-truetype-font \
  -attach font2.ttf -metadata:s:t:1 mimetype=application/x-truetype-font \
  -c copy output.mkv
```

### Extracting (-dump_attachment)

```bash
# These dump and then exit with "At least one output file must be specified";
# that message is harmless (add an output such as -f null - to silence it)

# Extract first attachment to specific file
ffmpeg -dump_attachment:t:0 extracted_font.ttf -i input.mkv

# Extract all attachments (uses filename metadata)
ffmpeg -dump_attachment:t "" -i input.mkv

# Extract specific stream by index
ffmpeg -dump_attachment:3 attachment.bin -i input.mkv
```

## Disposition Flags

```bash
# -map 0 keeps every track: without it only one audio stream is selected, so
# -disposition:a:1 would match nothing and the other tracks would be dropped

# Set stream as default
ffmpeg -i input.mkv -map 0 -c copy -disposition:a:0 default output.mkv

# Set as default and forced subtitle
ffmpeg -i input.mkv -map 0 -c copy -disposition:s:0 default+forced output.mkv

# Clear all dispositions
ffmpeg -i input.mkv -map 0 -c copy -disposition:a:1 0 output.mkv

# Multiple dispositions
ffmpeg -i input.mkv -map 0 -c copy \
  -disposition:v:0 default \
  -disposition:a:0 default \
  -disposition:a:1 0 \
  output.mkv
```

### Disposition Values

| Value | Description |
|-------|-------------|
| `default` | Default stream for playback |
| `dub` | Dubbed audio track |
| `original` | Original language |
| `comment` | Commentary track |
| `lyrics` | Lyrics track |
| `karaoke` | Karaoke version |
| `forced` | Forced subtitles |
| `hearing_impaired` | Subtitles for hearing impaired |
| `visual_impaired` | Audio for visually impaired |
| `clean_effects` | Clean audio effects |
| `attached_pic` | Attached picture (cover art) |
| `captions` | Closed captions |
| `descriptions` | Audio descriptions |
| `metadata` | Metadata stream |
| `dependent` | Dependent stream |
| `still_image` | Still image stream |
| `timed_thumbnails` | Timed thumbnail stream |
| `non_diegetic` | Non-diegetic audio |
| `multilayer` | Multilayer video (e.g. MV-HEVC) |
