vlib work

vlog -timescale 1ns/1ns airplane.v

vsim lfsr

log {/*}

add wave {/*}

force {clk} 0 0, 1 10 -r 20

force {reset} 0 0, 1 20

run 500ns
