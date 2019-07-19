// Part 2 skeleton

module part2
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire go;

	assign go = ~KEY[3];

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
    
    // Instansiate datapath
	// datapath d0(...);
	module combined(
		.go(go),
	 	.clk(CLOCK_50),
		.reset_N(resetn),	
		.colour(SW[9:7]),
		.x_out(x),
		.y_out(y),
		.colour_out(colour),
		.plot(writeEn)
	
	);


    // Instansiate FSM control
    // control c0(...);
    
endmodule

module control(
	input go, clk, reset_N,hold,done,
	output reg reset_C, en_XY, en_de, erase, plot
	);
	
	reg [2:0] current_state, next_state;

	localparam START = 3'd0,
			   START_WAIT = 3'd1,
			   DRAW = 3'd2,
			   DELAY = 3'd3,
			   ERASE = 3'd4,
			   UPDATE_XY= 3'd5;

	always @(*)
	begin
		case (current_state)
			START: next_state = go? START_WAIT: START; 
			START_WAIT: next_state = go? START_WAIT: DRAW;
			DRAW: next_state = done? DELAY : DRAW; 
			DELAY: next_state = hold? ERASE: DELAY;
			ERASE: next_state = done? UPDATE_XY: ERASE;
			UPDATE_XY: next_state = DRAW;
		endcase	
	end
	
	always @(*)
	begin
		reset_C = 0;
		en_XY = 0;
		en_de = 0;
		erase = 0;
		plot = 0;
		case (current_state)
			DRAW: plot = 1;
			DELAY: begin reset_C = 1; en_de = 1; end
			ERASE: begin erase = 1; plot = 1; end
			UPDATE_XY: en_XY = 1;	
		endcase	
	end	

	always @(posedge clk)
	begin
		if (!reset_N)
			current_state <= START;
		else
			current_state <= next_state;
	end

endmodule

module datapath(
	input reset_C, reset_N, clk, enable_delay, enable_XY, erase, plot,
	input [2:0] colour,
	
	output [7:0] x_out,
	output [6:0] y_out,
	output [2:0] colour_out,

	output reg  hold, done
	);
	
	reg [7:0] x;
	reg [6:0] y;
	reg [2:0] colour_reg;
	reg up;
	reg right;
	reg [3:0] count;
	reg [19:0] delay_count;
	reg [3:0] frame; 
	//XY counter logic
	always @(posedge clk)
	begin
		if(!reset_N)
		begin
			x <= 0;
			y <= 7'd60;
			up <= 1;
			right <= 1;
		end
		else if (enable_XY)
		begin
			if(up)begin
				y <= y - 1;
				if (y == 0)
					up = ~up;							
			end
			else begin
				y <= y + 1;
				if (y + 1'd3 == 7'd119)
					up = ~up;							
			end

			if(right)begin
				x <= x + 1;
				if (x + 1'd3 == 159)
					right = ~right;							
			end
			else begin
				x <= x - 1;
				if (x == 0)
					right = ~right;							
			end
			
			
		end
	end

	//delay&frame counter
	always @(posedge clk)
	begin
		if (!reset_N || !reset_C) begin
			delay_count <= 0;
			frame <= 0;
			hold <= 0;
		end
		else if (enable_delay) begin
			if (delay_count == 6'd8333333) begin
				delay_count <= 0;
				frame <= frame + 1;
			end
			else
				delay_count <= delay_count + 1;

			if (frame == 2'd15) 
				hold <= 1;		
			end					
	end
	
	always @(posedge clk)
	begin
		if(!reset_N)
			colour_reg <= 0;
		else 
			if (erase)
				colour_reg <= 0;
			else
				colour_reg <= colour;
			
	end

	//counter
	always @(posedge clk)
	begin
		if(!reset_N) begin
			count <= 0;
			done <= 0;
		end
		else if (!plot) begin
			count <= 0;
			done <= 0;		
		end
		else if (count == 4'b1111) begin
					count <= 0;
					done <= 1;
				end			
		else
			count <= count + 1'b1;	
						
	end

	assign x_out = x + count[1:0];
	assign y_out = y + count[3:2];
	assign colour_out = colour_reg;

endmodule

module combined(
	input go, clk, reset_N,	
	input [2:0] colour,
	output [7:0] x_out,
	output [6:0] y_out,
	output [2:0] colour_out,
	output plot
	
);

	wire reset_C, en_XY, en_de, erase, p, hold, done;

	control c0(
		.clk(clk),
		.go(go),
		.reset_N(reset_N),
		.hold(hold),
		.done(done),
		.reset_C(reset_C),
		.en_XY(en_XY),
		.en_de(en_de),
		.erase(erase),
		.plot(p)
	);
	
	datapath d0(
		.colour(colour),
		.hold(hold),
		.done(done),
		.reset_C(reset_C),
		.enable_XY(en_XY),
		.enable_delay(en_de),
		.erase(erase),
		.plot(p),
		.clk(clk),
		.reset_N(reset_N),		
		.x_out(x_out),
		.y_out(y_out),
		.colour_out(colour_out)			
	);
	
	assign plot = p;
endmodule
