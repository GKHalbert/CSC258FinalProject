vlib work

vlog -timescale 1ns/1ns airplane.v

vsim control

log {/*}

add wave {/*}


force {clk} 0 0, 1 10 -r 20

force {reset_N} 0 0, 1 20

force {go} 0 0, 1 40, 0 60

force {done_plane} 0 0, 1 100

force {done_p1} 0 0, 1 120

force {done_p2} 0 0, 1 140

force {done_p3} 0 0, 1 160

force {hold} 0 0, 1 200

force {done_c1} 0 0, 1 180

force {collide} 0
run 500ns

