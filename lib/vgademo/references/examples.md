# vgademo Reference Examples

Two worked examples plus a negative anti-pattern example. Consult before emitting code.

Note: live output uses `##` for the four mandatory sections (Byte Budget, Code, Core Trick, Tradeoffs). Here they appear as `###` only because each example is nested under a `##` example header - do not copy the heading level from these examples.

## Example 1: 256-byte XOR-Plasma (NASM, .COM, Mode 13h)

### Byte Budget
Estimated assembled size: ~22 bytes / 256 bytes

### Code

```asm
org 100h
mov al,13h
int 10h
push 0A000h
pop es
.frame:
  xor di,di
  mov cx,64000
.pixel:
  mov ax,di
  shr ax,1
  xor al,ah
  add al,bl
  stosb
  loop .pixel
  inc bl
  jmp .frame
```

### Core Trick

Mechanism: pixel color = (DI>>1 XOR high-byte) + frame counter. DI walks linear VGA buffer; BL animates by re-biasing palette index each frame. No LUT, no trig - XOR of position halves yields plasma-like diagonal interference; `INC BL` cycles colors.

Key instructions: `STOSB`, `LOOP`, `XOR`, `SHR`, `INC`

Register reuse:
- `AX` - color + index (`AL` output, `AH` high-byte feedback)
- `CX` - pixel loop
- `DI` - screen pointer
- `BL` - frame counter
- `ES` - VGA segment (`A000h`)

### Tradeoffs

- Size won by: `STOSB` fuses store+increment; `AX` dual-use as index+color avoids second register; `LOOP` implicit `CX` dec.
- Cycles cost: ~5 cycles/pixel on 8086 = ~320k/frame; ~1 cycle/pixel on 386.
- Sacrificed: portability (VGA-locked, `A000h` hardcoded), no vsync (tearing), 8086-only `LOOP` penalty on 486+.

---

## Example 2: 512-byte Boot Sector Text-Mode Color Bars (NASM, raw binary, B800h, BIOS only)

### Byte Budget
Estimated assembled size: ~24 bytes code + 486 pad + 2 sig = 512 bytes / 512 bytes

### Code

```asm
org 7C00h
push 0B800h
pop es
xor bx,bx
.frame:
  xor di,di
  mov cx,2000
  mov al,0DBh
.cell:
  mov ah,bl
  add ah,cl
  stosw
  loop .cell
  inc bl
  jmp .frame
times 510-($-$$) db 0
dw 0AA55h
```

### Core Trick

Mechanism: text-mode color bars on full-block char (`0DBh`). Attribute byte = `BL` (frame counter) + `CL` (descending cell index from `LOOP`). `STOSW` writes char+attr pair per cell. `INC BL` shifts palette each frame, producing horizontal scroll of 16 EGA colors. Pure BIOS - no DOS, no VGA, boots from any media. `CL` counts down 2000→1, so cells get position-dependent attribute even within one frame.

Key instructions: `STOSW`, `LOOP`, `ADD`, `INC`, `PUSH`/`POP` (segment load)

Register reuse:
- `AX` - char + attr (`AL`=`0DBh` fixed, `AH`=color computed)
- `BX` - frame counter (`BL` only)
- `CX` - cell loop + per-cell color offset
- `DI` - text buffer pointer
- `ES` - `B800h`

### Tradeoffs

- Size won by: `STOSW` fuses char+attr write; `CX` dual-use (loop counter + color modulator); single `AL` load outside inner loop; `PUSH`/`POP` imm to load segment in 4 bytes vs 5 for `MOV AX,imm` + `MOV ES,AX`.
- Cycles cost: ~6 cycles/cell on 8086 = ~12k/frame; flicker-free at any speed (text mode = no retrace concern for this method).
- Sacrificed: text mode only (no graphics), 16-color EGA palette ceiling, boot signature mandatory (last 2 bytes locked).

---

## Negative Example (DO NOT EMIT - anti-pattern reference)

```asm
; BAD - violates multiple rules
org 100h
section .data           ; rule #4: introduces label beyond minimum
counter db 0            ; rule #4: named variable instead of register/SMC
section .text
main:                   ; rule #4: unnecessary label
    push bp             ; rule #3: PUSH for preservation without re-entry
    mov bp,sp           ; rule #4: stack frame ceremony
    mov eax,13h         ; SCOPE: 32-bit op in 16-bit mode → REFUSE: platform
    int 10h
    call clear_screen   ; rule #4: function for one-time use
    mov dword [counter],0  ; SCOPE: 32-bit operand → REFUSE: platform
    leave               ; rule #3,#4: prologue/epilogue
    ret
clear_screen:           ; rule #4: extracted function
    ret
```

### Why this fails (silent - do not output to user)

1. 32-bit `EAX`/`dword` in 16-bit mode → `CPU_MODE` violation.
2. `PUSH BP` / `MOV BP,SP` / `LEAVE` / `RET` = stack-frame ceremony with no re-entry need (Demoscene rule #3).
3. Named `counter` variable instead of register reuse (rule #2-3).
4. Function `clear_screen` called once → rule #4 violation.
5. Comments emitted without `COMMENTS=true` → rule #10 violation.
6. Marketing register in comments → Language Lock violation.
7. Section directives unneeded in `.COM` flat layout → rule #4.

Correct response to this style of request: `REFUSE: platform` (32-bit ops detected). Do not "fix and emit" - refuse cleanly.
