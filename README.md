# CSC258FinalProject
Final project for course CSC258 at the University of Toronto. A small game similar to Flappy Bird written in verilog, runs on a DE1-SOC board.

README

Our project is called dodge the pipe, which is similar to the “Flappy Bird”, the blue pixel represents the air plane and the green rectangle represents the pipe, the plane needs to dodge the pipe and collect the yellow coin.

We use the monitor, KEY and SW.
 KEY[0]: reset the game
 KEY[1]: make plane upward one pixel
 KEY[3]: start the game
 SW[1:0]: the difficulty level of the game

Top level module name:  airplane

Name of models:
	airplane: top level module
	Control: show state table
	Datapath: display plane, pipes and coins, detect collision
	Combined: combine Control and Datapath modules
	Lfsr: random number generater
	Hexdisplay: show score (the number of collected coin) on the hex

Verilog modules not created by us:
	VGA adapter

Resource: https://flappybird.io/ 
	https://vlsicoding.blogspot.com/2014/07/verilog-code-for-4-bit-linear-feedback-shift-register.html - linear feedback shift register
