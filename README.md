# FPGBA

GBA on FPGA

GBA Implementation in VHDL for FPGA from scratch.

In scope:
- all videomodes including affine and special effects
- all soundchannels
- saving as in GBA
- cyclebased
- turbomode(target is 2x Speed)
- pixelperfect-scaling with framebuffer

Out of scope:
- Multiplayer features like Serial
- GBA Module function(e.g. Boktai sun sensor)
- savestates
- debugging on hardware (VHDL simulation should be enough)
- all Peripheral like VGA/HDMI, SDRAM, Controller, ....

# Target Boards
1. Terasic DE2-115
2. Terasic DE-10(Mister)
3. Analogue Pocket(if jailbreak possible)
4. Xilinx ZCU104

# Status: 

176 games tested until ingame:
- 169 without major issues (no crash, playable)
- about 10% still with graphical issues, mostly due to incorrect timing

VHDL:
- CPU done
- Graphic fully implemented
- Sound fully implemented
- Turbomode working but with large graphical glitches
- saving with EEPROM/SRam/FLASH ok
- all registers implemented

Missing big parts:
- Gamepak Prefetch
- Timing accuracy. Currently about 50% Tests passed (about as good as VBA-M)

Software model, cyclebased Emulator in C#:
- all features done
- Armwrestler Tests 100% pass
- ~300 Games tested (due to lack of time, most only until getting ingame)
-> considered complete for now, can be used as "known good" for 99%.

# FPGA Ressource usage (GBA only)
- 25500 LE (LUTS+FF), 9000 CPU, 7500 GPU
- 2Mbit Ram used for WRAM fast, VRAM, Palette, OAM, Framebuffer
- WRAM Slow, Gamepak and Saves(EEPROM, SRAM, Flash) are on SDRam.
