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

VHDL:
- CPU done, some bugs probably still left
- Graphic mostly implemented (affine Sprites and Bitmap working already!)
- Sound mostly implemented
- Turbomode working but with large graphical glitches
- saving with EEPROM ok
- all registers implemented

Missing big parts:
- affine Tilemaps -> Mode 7, e.g. Mario Kart
- Waveram Audiochannel only has one bank as in old GBC
- FLASH-save is implemented but not working yet

Software model, cyclebased Emulator in C#:
- all features done
- Armwrestler Tests 100% pass
- ~300 Games tested (due to lack of time, most only until getting ingame)
-> considered complete for now, can be used as "known good" for 99%.

# FPGA Ressource usage (GBA only)
- 28500 LE (LUTS+FF), 8500 CPU, 6000 GPU
- 2Mbit Ram -> WRAM fast, VRAM, Palette, OAM, Framebuffer
- WRAM Slow, Gamepak and Saves(EEPROM, SRAM, Flash) are on SDRam.

Next update: soon
