vlib work

vlog -timescale 1ns/1ns airplane.v

vsim combined

log {/*}

add wave {/*}

force {delay} 2#010

force {clk} 0 0, 1 10 -r 20

force {reset_N} 0 0, 1 20

force {up} 0

force {go} 0 0, 1 40, 0 60

run 5000ns

