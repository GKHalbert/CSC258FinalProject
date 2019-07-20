module game
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
	input go, clk, reset_N,hold,done_plane, collide,
	output reg reset_C, en_XY_plane, en_de, erase, plot, ck_cld
	output reg [1:0] draw_op
	);
	
	reg [3:0] current_state, next_state;

	localparam START = 4'd0,
			   START_WAIT = 4'd1,
			   DRAW_PLANE = 4'd2,
			   DELAY = 4'd3,
			   ERASE_PLANE = 4'd4,
			   UPDATE_XY_PLANE= 4'd5;
			   CHECK_COLLISION = 4'd6;			
	//State table
	always @(*)
	begin
		case (current_state)
			START: next_state = go? START_WAIT: START; 
			START_WAIT: next_state = go? START_WAIT: DRAW;
			DRAW_PLANE: next_state = done_plane? DELAY : DRAW_PLANE; 
			DELAY: next_state = hold? ERASE_PLANE: DELAY;
			ERASE_PLANE: next_state = done_plane? CHECK_COLLISION: ERASE_PLANE;
			CHECK_COLLISION: next_state = collide? START: UPDATE_XY_PLANE;
			UPDATE_XY_PLANE: next_state = DRAW_PLANE;
			
		endcase	
	end
	
	//Signals
	always @(*)
	begin: enable_signals
		reset_C = 0;
		en_XY_plane = 0;
		en_de = 0;
		erase = 0;
		plot = 0;
		ck_cld = 0;
		draw_op = 2'b00;
		case (current_state)
			DRAW_PLANE: begin plot = 1; end
			DELAY: begin reset_C = 1; en_de = 1; end
			ERASE_PLANE: begin erase = 1; plot = 1; end
			CHECK_COLLISION: begin ck_cld = 1; end
			UPDATE_XY_PLANE: en_XY_plane = 1;	
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
	input reset_C, reset_N, clk, enable_delay, en_XY_plane, erase, plot, up, ck_cld,
	input [1:0] draw_op,	
	
	output [7:0] x_out,
	output [6:0] y_out,
	output [2:0] colour_out,

	output reg  hold, done_plane, collide
	);
	reg [7:0] mux_x;
	reg [6:0] mux_y;
	reg [7:0] plane_x;
	reg [6:0] plane_y;
	reg [2:0] colour_reg;
	reg [3:0] count_plane;
	reg [19:0] delay_count;
	reg [3:0] frame; 
	
	//plane coordinate logic
	always @(posedge clk)
	begin
		if(!reset_N)
		begin
			plane_x <= 7'd80;
			plane_y <= 7'd60;
			
		end
		else if (en_XY_plane)
		begin
			if(up)begin
				plane_y <= plane_y - 1;								
			end
			else begin
				plane_y <= plane_y + 1;				
			end			
			
		end
	end

	//collision detect logic
	always @(posedge clk)
	begin
		if(!reset_N)
			collide <= 0;
		else if (ck_cld) begin // check for collison
				if (plane_y == 0)
					collide <= 1;
				if (plane_y + 2'd3 == 7'd119)
					collide <= 1;		
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
			if (delay_count == 20'd833333) begin
				delay_count <= 0;
				frame <= frame + 1;
			end
			else
				delay_count <= delay_count + 1;

			if (frame == 4'd15) 
				hold <= 1;		
			end					
	end
	
	//output colour logic
	always @(posedge clk)
	begin
		if(!reset_N)
			colour_reg <= 0;
		else 
			if (erase)
				colour_reg <= 0; // Change the colour to match the background
			else if (draw_op == 2'b00)
				colour_reg <= 3'b001; //Colour for the plane
			else if (draw_op == 2'b01)
				colour_reg <= 3'b010; //colour for the pipe
			
	end

	//counter for drawing the plane
	always @(posedge clk)
	begin
		if(!reset_N) begin
			count_plane <= 0;
			done_plane <= 0;
		end
		else if (!plot || draw_op != 2'b00) begin
			count_plane <= 0;
			done_plane <= 0;		
		end
		else if (count_plane == 4'b1111) begin
					count_plane <= 0;
					done_plane <= 1;
				end			
		else
			count_plane <= count_plane + 1'b1;	
						
	end
	
	//output xy multiplexier 
	always @(*)
	begin
		case (draw_op)
		2'b00: begin //draw the plane
			mux_x = plane_x + count_plane[1:0];
			mux_y = plane_y + count_plane[3:2];
			end
		2'b01: begin // draw the pipe
			mux_x = 0; // placeholder
			mux_y = 0; // placeholder
		endcase
	end
	assign x_out = mux_x;
	assign y_out = mux_y;
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
