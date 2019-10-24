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

# Target Boards
1. Terasic DE2-115
2. Terasic DE-10(Mister)
3. Analogue Pocket(if jailbreak possible)
4. Xilinx ZCU104

Current CPU takes ~6000LE on Cyclone 4.
400Kbit of Memory for WRAM Small and BIOS.
Gamepak, WRAMLarge and EEProm will go into SDRam.

# Status: 

Software model, cyclebased Emulator in C#:
- all features done
- Armwrestler Tests 100% pass
- ~300 Games tested (due to lack of time, most only until getting ingame)
-> considered complete for now

VHDL:
- CPU nearly done, Timing is met
- all register definitions done


Next update when first commercial game is running.
