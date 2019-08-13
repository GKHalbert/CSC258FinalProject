vlib work

vlog -timescale 1ns/1ns airplane.v

vsim datapath

log {/*}

add wave {/*}

force {draw_op} 2#001

force {clk} 0 0, 1 10 -r 20


force {reset_C} 0 0, 1 20

force {reset_N} 0 0, 1 20

force {up} 0

force {en_XY_plane} 0 0, 1 40, 0 100

force {plot} 0

force {enable_delay} 0 0, 1 100

force {en_XY_p1} 0 0, 1 60

force {erase} 0

force {ck_cld} 1

run 5000ns
 
