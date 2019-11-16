RMDIR /s /q sim
MKDIR sim

vlib sim/mem
vmap mem sim/mem

vlib sim/gba
vmap gba sim/gba

vlib sim/top
vmap gba sim/top

