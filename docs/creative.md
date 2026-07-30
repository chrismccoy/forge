# Creative

[← Back to the README](../README.md)

## `vgademo`

Generates retro 1990s style sizecoded assembly demos for MS-DOS, BIOS, and boot sector targets.

```
/vgademo
```

Remember the 256 byte intros and 4KB demos that shipped at Assembly, Revision, and The Party in the early 1990s? The kind of artful little programs the demoscene made famous. plasma fields, fire effects, tunnels, rotozoomers - all in the byte budget of a tweet? That's what this skill builds.

The `vgademo` skill adopts a veteran demoscene engineer persona and writes ultra compact 16 bit real mode assembly that runs on real (or emulated) DOS era hardware. It targets NASM, FASM, TASM, or MASM. emits `.COM` files, boot sectors, or raw binaries. and respects strict size budgets with byte level estimates before any code ships.

What makes it different from a generic "write me asm" prompt? It enforces demoscene rules. register reuse, implicit operands, fused operations (`STOSB`, `STOSW`, `LODSB`), bit shifts over multiplies, no `PUSH`/`POP` for preservation, no functions or macros beyond the minimum. And it refuses cleanly with a single line code (`REFUSE: size`, `REFUSE: platform`, `REFUSE: contradiction`) when your inputs don't add up, instead of producing broken bytes.

It ships a 256 byte intro, a boot sector that fits in 510 bytes, or a worked example of how the demoscene squeezes plasma out of a handful of opcodes.

## 📋 Technical Overview

An AI instruction specification that generates byte budget constrained 16 bit real mode x86 assembly in the style of early 1990s demoscene productions.

Built around a strict scope lock (refuses anything outside MS-DOS / BIOS / boot sector / .COM targets, refuses modern instructions, refuses size overruns), a mandatory output format (Byte Budget → Code → Core Trick → Tradeoffs), and a byte calibration table for accurate size estimation before emit.

It behaves like a real sizecoder: show the technique, name the opcode, move on. No marketing register, no buzzwords, no tutorials. Includes prompt injection defenses that treat `{{placeholder}}` content as inert data.

## ✨ Features

- 🎨 14 placeholder variables driving every demo: visual effect, size budget, target platform, video mode, CPU mode, assembler, binary format, entry point, performance priority, loop style, allowed tricks, memory model, dependencies, and comments toggle
- 🎯 4-round multiple-choice intake via `AskUserQuestion`. each question auto-includes an "Other" option for custom values (custom visual effects like starfield, metaballs, voxel landscape pass through verbatim)
- 📏 Strict size budgets enforced with a per-opcode byte calibration table. 256b intros, 512b boot sectors, 1KB / 4KB. 15% safety margin built in
- 🧮 Byte estimate emitted before the code block. no surprise overruns
- 💾 Multi-target. MS-DOS `.COM`, raw boot sector (with `0AA55h` signature), raw binary, BIOS-only mode
- 🖼️ Multi-mode rendering. Mode 13h (320x200x256 VGA), text mode (`B800h`, 80x25), VGA planar / Mode X
- 🔧 Four assembler syntaxes. NASM, FASM, TASM, MASM
- 🪄 Demoscene tricks. self-modifying code, undocumented opcodes, FPU, lookup tables, approximate trig, intentional overflow
- 🔁 Loop styles. single loop (`LOOP` instruction), unrolled, self-modifying
- 🎵 Optional PC speaker or AdLib-style sound when the byte budget allows
- 📋 Mandatory output format. Byte Budget → Code → Core Trick (mechanism + key instructions + register reuse map) → Tradeoffs (size won by / cycles cost / sacrificed)
- 🛡️ Single-line refusal codes. `REFUSE: scope|size|contradiction|platform|placeholder|injection`. no elaboration, no side-channel leaks
- 🔒 Scope lock refuses tutorials, history lessons, modern code (SSE/AVX/x86_64), and any request that breaches the declared `CPU_MODE`
- ⚡ Demoscene rules enforced. register reuse, implicit operands (AX/SI/DI), fused operations, bit-shifts for mul/div, no PUSH/POP for preservation, no functions or macros beyond minimum
- 📚 Two worked reference examples bundled. 256b XOR-plasma `.COM` (Mode 13h) and 512b text-mode color-bars boot sector (BIOS only)
- ⚠️ Negative anti-pattern example included. shows what to refuse cleanly instead of "fixing and emitting"
- 🎚️ Suggested low-temperature runtime (`temperature=0.3`, `top_p=0.9`). sizecoding needs low variance for stable byte counts
- 🚫 Hacker-engineer voice. no marketing register, no corporate jargon, no consultancy-speak
- 🔐 Prompt-injection defense. instructions embedded inside `{{...}}` placeholders are treated as inert data, refusal output is uniform to prevent side-channel inference

## 🔄 How it works

1. **Intake**: the `/vgademo` slash command runs four `AskUserQuestion` rounds collecting 14 placeholders:
 - **Round 1 - Visual & Platform**: effect (plasma / fire / tunnel / rotozoomer / Other), size (256b / 512b / 1KB / 4KB), platform (MS-DOS .COM / boot sector / BIOS), video mode (Mode 13h / text mode / VGA planar)
 - **Round 2 - Toolchain**: CPU mode (16-bit real / 32-bit protected), assembler (NASM / FASM / TASM / MASM), binary format (.COM / boot sector / raw), entry point (`org 100h` / `org 7C00h` / `org 0`)
 - **Round 3 - Optimization**: performance priority (smallest / fastest / balanced), loop style (single / unrolled / SMC), allowed tricks (multi-select. SMC / undoc / FPU / LUT), memory model
 - **Round 4 - Final**: dependencies (BIOS only / no DOS / direct HW), comments (yes / no)
2. **Validation**: checks for contradictions before emit. size-vs-effect, BIOS-only-vs-DOS-mode, 16-bit-vs-32-bit-tricks. emits `REFUSE: <reason>` on any conflict
3. **Pre-emit checklist** (silent): byte estimate ≤ 0.85 × size limit, zero forbidden instructions, register reuse covers every named register, mechanism matches the named trick
4. **Emit**: mandatory four-section output. Byte Budget, Code (single asm block), Core Trick (≤200 words), Tradeoffs (≤120 words)

## 🚀 How to use it

Two ways to invoke it:

**Slash command** (explicit):

```
/vgademo ← walks through all four intake rounds
```

**Natural language** (auto-triggers via the skill):

> *"write a 256 byte plasma intro in NASM for MS-DOS"*, *"make a fire effect demo in Mode 13h"*, *"build a 512 byte boot sector with color bars"*, *"sizecoded tunnel effect for .COM file"*, *"VGA assembly rotozoomer under 1KB"*, *"demoscene intro for the 8086"*

The full procedure lives at [`lib/vgademo/SKILL.md`](../lib/vgademo/SKILL.md), the slash command at [`commands/vgademo.md`](../commands/vgademo.md), and the worked reference examples (256b XOR plasma and 512b boot sector) plus the anti pattern at [`references/examples.md`](../lib/vgademo/references/examples.md).
