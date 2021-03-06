module airplane_p3
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		  HEX0,
		  HEX1,
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
	output	[6:0] HEX0, HEX1;

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
	wire [7:0] x, score;
	wire [6:0] y;
	wire writeEn;
	wire go;

	assign go = ~KEY[3];
	assign up = ~KEY[1];

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
	combined c0(
		.delay(SW[1:0]),
		.go(go),
		.clk(CLOCK_50),
		.reset_N(KEY[0]),
		.up(up),
		.x_out(x),
		.y_out(y),
		.colour_out(colour),
		.plot(writeEn),
		.score(score)
	);
	
	hxdisplay d0(
		.hex_digit(score[3:0]),
		.segments(HEX0[6:0])
		);
		
	hxdisplay d1(
		.hex_digit(score[7:4]),
		.segments(HEX1[6:0])
		);



    // Instansiate FSM control
    // control c0(...);
    
endmodule

module control(
	input go, clk, reset_N,hold,done_plane, collide, done_p1,done_p2, done_p3, done_c1,
	output reg reset_C, en_XY_plane, en_XY_p1,en_XY_p2, en_XY_p3, en_XY_c1, en_de, erase, plot, ck_cld,
	output reg [2:0] draw_op
	);
	
	reg [4:0] current_state, next_state;

	localparam START = 5'd0,
			   START_WAIT = 5'd1,
			   DRAW_PLANE = 5'd2,
			   DRAW_P1 = 5'd3,
			   DRAW_P2 = 5'd4,
			   DRAW_P3 = 5'd5,
			   DRAW_C1 = 5'd6,
			   DELAY = 5'd7,
			   ERASE_PLANE = 5'd8,
			   ERASE_P1 = 5'd9,
			   ERASE_P2 = 5'd10,
			   ERASE_P3 = 5'd11,
			   ERASE_C1 = 5'd12,	
			   CHECK_COLLISION = 5'd13,	
			   UPDATE_XY_PLANE = 5'd14,
			   UPDATE_XY_P1 = 5'd15,
			   UPDATE_XY_P2 = 5'd16,
			   UPDATE_XY_P3 = 5'd17,
			   UPDATE_XY_C1 = 5'd18;
			   		
	//State table
	always @(*)
	begin
		case (current_state)
			START: next_state = go? START_WAIT: START; 
			START_WAIT: next_state = go? START_WAIT: DRAW_PLANE;
			DRAW_PLANE: next_state = done_plane? DRAW_P1 : DRAW_PLANE;
			DRAW_P1: next_state = done_p1? DRAW_P2	: DRAW_P1;
			DRAW_P2: next_state = done_p2? DRAW_P3 : DRAW_P2;
			DRAW_P3: next_state = done_p3? DRAW_C1: DRAW_P3;
			DRAW_C1: next_state = done_c1? DELAY: DRAW_C1;
			DELAY: next_state = hold? ERASE_PLANE: DELAY;
			ERASE_PLANE: next_state = done_plane? ERASE_P1: ERASE_PLANE;
			ERASE_P1: next_state = done_p1? ERASE_P2: ERASE_P1;
			ERASE_P2: next_state = done_p2? ERASE_P3: ERASE_P2;
			ERASE_P3: next_state = done_p3? ERASE_C1: ERASE_P3;
			ERASE_C1: next_state = done_c1? CHECK_COLLISION: ERASE_C1;
			CHECK_COLLISION: next_state = collide? START: UPDATE_XY_PLANE;
			UPDATE_XY_PLANE: next_state = UPDATE_XY_P1;
			UPDATE_XY_P1: next_state = UPDATE_XY_P2;
			UPDATE_XY_P2: next_state = UPDATE_XY_P3;
		   UPDATE_XY_P3: next_state = UPDATE_XY_C1;
			UPDATE_XY_C1: next_state = DRAW_PLANE;
			
			
		endcase	
	end
	
	//Signals
	always @(*)
	begin: enable_signals
		reset_C = 0;
		en_XY_plane = 0;
		en_XY_p1= 0;
		en_XY_p2= 0;
		en_XY_p3= 0;
		en_XY_c1 = 0;
		en_de = 0;
		erase = 0;
		plot = 0;
		ck_cld = 0;
		draw_op = 3'b000;
		case (current_state)
			DRAW_PLANE: begin plot = 1; end
			DRAW_P1: begin plot = 1; draw_op = 3'b001; end
			DRAW_P2: begin plot = 1; draw_op = 3'b010; end
			DRAW_P3: begin plot = 1; draw_op = 3'b011; end
			DRAW_C1: begin plot = 1; draw_op = 3'b100; end
			DELAY: begin reset_C = 1; en_de = 1; end
		   ERASE_P1: begin erase = 1; plot = 1; draw_op = 3'b001; end
			ERASE_P2: begin erase = 1; plot = 1; draw_op = 3'b010; end
			ERASE_P3: begin erase = 1; plot = 1; draw_op = 3'b011; end
			ERASE_PLANE: begin erase = 1; plot = 1; end
			ERASE_C1: begin erase = 1; plot = 1; draw_op = 3'b100; end
			CHECK_COLLISION: begin ck_cld = 1; end
			UPDATE_XY_PLANE: en_XY_plane = 1;	
			UPDATE_XY_P1: en_XY_p1 = 1;
			UPDATE_XY_P2: en_XY_p2 = 1;
			UPDATE_XY_P3: en_XY_p3 = 1;
			UPDATE_XY_C1: en_XY_c1 = 1;
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
	input reset_C, reset_N, clk, enable_delay, en_XY_plane, erase, plot, up, ck_cld, en_XY_p1,en_XY_p2, en_XY_p3, en_XY_c1,
	input [2:0] draw_op,delay,
	
	
	output [7:0] x_out,
	output [6:0] y_out,
	output [2:0] colour_out,

	output reg  hold, done_plane, done_p1, done_p2, done_p3, done_c1, collide,
	output reg [7:0] score
	);
	
	reg p1, p2, p3, c1;
	reg [10:0] num_p1, num_p2, num_p3;
	reg [10:0] count_p1, count_p2, count_p3;
	reg [7:0] mux_x;
	reg [6:0] mux_y;
	reg [7:0] plane_x;
	reg [6:0] plane_y;
	reg [31:0] temp;
	reg [7:0] p1_x, p2_x, p3_x, c1_x;
	reg [6:0] p1_y, p2_y, p3_y, c1_y;
	reg [2:0] colour_reg;
	reg [3:0] count_plane, count_c1;
	reg [19:0] delay_count;
	reg [3:0] frame;
	reg [19:0] delay_limit;

	wire [7:0] random;
	wire [3:0] height;
	
	//plane coordinate logic
	always @(posedge clk)
	begin
		if(!reset_N)
		begin
			plane_x <= 7'd40;
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
	

	
	lfsr l0(
		.clk(clk),
		.reset(reset_N),
		.height(random)
		);
		

	
	// pipe1 coordinate logic
	always @(posedge clk)
	begin
		if(!reset_N)
		begin
			p1_x <= 8'd120;
			p1_y <= 0;
			p1 <= 0;
			num_p1 <= 0;
		end
		else if (en_XY_p1) begin
				if (!p1)
					begin
					p1 <= 1;	
					if (random < 20) begin
						p1_y <= random + 30;
						num_p1 <= (11'd119-(random+30))* 11'd8;
					end
					else if (7'd20 < random && random < 7'd120) begin
						p1_y <= random;
						num_p1 <= (11'd119-random) * 11'd8;
					end
					else if (random < 200) begin
						p1_y <= random - 120;
						num_p1 <= (11'd119-(random-120))* 11'd8;
					end
					else begin
						p1_y <= random - 180;
						num_p1 <= (11'd119-(random-180))* 11'd8;
					end					
				end
				else if (p1_x == 0) begin
					p1_x <= 8'd160;
					p1 <= 0;
				end	
				else 
					p1_x <= p1_x - 1;
				
		end		
	end

	// pipe2 coordinate logic
	always @(posedge clk)
	begin
		if(!reset_N)
		begin
			p2_x <= 8'd180;
			p2_y <= 0;
			p2 <= 0;
			num_p2 <= 0;
		end
		else if (en_XY_p2) begin
				if (!p2)
					begin
					p2 <= 1;
					if (random < 20) begin
						p2_y <= random + 30;
						num_p2 <= (11'd119-(random+30))* 11'd8;
					end
					else if (7'd20 < random && random < 7'd120) begin
						p2_y <= random;
						num_p2 <= (11'd119-random) * 11'd8;
					end
					else if (random < 200) begin
						p2_y <= random - 120;
						num_p2 <= (11'd119-(random-120))* 11'd8;
					end
					else begin
						p2_y <= random - 180;
						num_p2 <= (11'd119-(random-180))* 11'd8;
					end					
				end
				else if (p2_x == 0) begin
					p2_x <= 8'd160;
					p2 <= 0;
				end	
				else 
					p2_x <= p2_x - 1;
				
		end		
	end
	
	// pipe3 coordinate logic
	always @(posedge clk)
	begin
		if(!reset_N)
		begin
			p3_x <= 8'd240;
			p3_y <= 0;
			p3 <= 0;
			num_p3 <= 0;
		end
		else if (en_XY_p3) begin
				if (!p3)
					begin
					p3 <= 1;
					if (random < 20) begin
						p3_y <= random + 30;
						num_p3 <= (11'd119-(random+30))* 11'd8;
					end
					else if (7'd20 < random && random < 7'd120) begin
						p3_y <= random;
						num_p3 <= (11'd119-random) * 11'd8;
					end
					else if (random < 200) begin
						p3_y <= random - 120;
						num_p3 <= (11'd119-(random-120))* 11'd8;
					end
					else begin
						p3_y <= random - 180;
						num_p3 <= (11'd119-(random-180))* 11'd8;
					end					
				end
				else if (p3_x == 0) begin
					p3_x <= 8'd160;
					p3 <= 0;
				end	
				else 
					p3_x <= p3_x - 1;
				
		end		
	end
	
	

	// coin 1 coordinate logic
   always @(posedge clk)
	begin
		if(!reset_N)

		begin
			c1_x <= 8'd210;
			c1_y <= 7'd120;
			c1 <= 0;
			score <= 0;
		end
		else if (en_XY_c1) begin
				if (!c1)
					begin
					c1 <= 1;
					c1_y <= random;
					
				end
				else if (c1_x == 0) begin
					c1_x <= 8'd160;
					c1 <= 0;
				end
				else if (plane_x + 3 == c1_x)
						begin
							if ((plane_y + 3 >= c1_y) && ( plane_y <= c1_y + 3))
								begin
									score <= score + 1;
									c1_y <= 7'd121;
								end
							else
								c1_x <= c1_x - 1;
						end
				else if ((plane_x + 3 > c1_x) && (plane_x <= c1_x + 3))
							begin
								if ((plane_y + 3 == c1_y)|| (c1_y + 3 == plane_y)) begin
									score <= score + 1;
									c1_y <= 7'd121;
									end
								else
									c1_x <= c1_x - 1;
							end

				else 
					c1_x <= c1_x - 1;
				
		end		
	end
	
	//collision detect logic
	always @(posedge clk)
	begin
		if(!reset_N)
			collide <= 0;
		else if (ck_cld) begin // check for collison
				//collide with edge				
				if (plane_y == 0)
					collide <= 1;
				if (plane_y + 2'd3 == 7'd119)
					collide <= 1;
				//collide with pipe 1
				if (plane_y + 2'd3 > p1_y) begin // collide front
					if (plane_x + 2'd3 == p1_x)
						collide <= 1;				
				end
				
				if (plane_y + 2'd3 == p1_y) begin // collide upper
					if (plane_x <= p1_x + 4'd7 && plane_x >= p1_x -2'd3)
						collide <= 1;				
				end
				//collide with pipe 2
				if (plane_y + 2'd3 > p2_y) begin // collide front
					if (plane_x + 2'd3 == p2_x)
						collide <= 1;				
				end
				
				if (plane_y + 2'd3 == p2_y) begin // collide upper
					if (plane_x <= p2_x + 4'd7 && plane_x >= p2_x -2'd3)
						collide <= 1;				
				end
				//collide with pipe 3
				if (plane_y + 2'd3 > p3_y) begin // collide front
					if (plane_x + 2'd3 == p3_x)
						collide <= 1;				
				end
				
				if (plane_y + 2'd3 == p3_y) begin // collide upper
					if (plane_x <= p3_x + 4'd7 && plane_x >= p3_x -2'd3)
						collide <= 1;				
				end		
			
						
		end
	end
		
	
	//diffifculty logic
	always @(*)
	begin
		case (delay)
			3'b000: delay_limit = 20'd200000;
			3'b001: delay_limit = 20'd150000;
			3'b010: delay_limit = 20'd100000;
			3'b011: delay_limit = 20'd500;
		endcase
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
			if (delay_count == delay_limit) begin
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
			else if (draw_op == 3'b000)
				colour_reg <= 3'b001; //Colour for the plane
			else if (draw_op == 3'b001)
				colour_reg <= 3'b010; //colour for the pipe
			else if (draw_op == 3'b010)
				colour_reg <= 3'b010; //colour for the pipe
			else if (draw_op == 3'b011)
				colour_reg <= 3'b010; //colour for the pipe
			else if (draw_op == 3'b100)
				colour_reg <= 3'b110; //colour for the coin
			
	end

	//counter for drawing the plane
	always @(posedge clk)
	begin
		if(!reset_N) begin
			count_plane <= 0;
			done_plane <= 0;
		end
		else if (!plot || draw_op != 3'b000) begin
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

	//counter for drawing the coin 1
	always @(posedge clk)
	begin
		if(!reset_N) begin
			count_c1 <= 0;
			done_c1 <= 0;
		end
		else if (!plot || draw_op != 3'b100) begin
			count_c1 <= 0;
			done_c1 <= 0;		

		end
		else if (count_c1 == 4'b1111) begin
					count_c1 <= 0;
					done_c1 <= 1;
				end			
		else
			count_c1 <= count_c1 + 1'b1;	
						
	end
	
	//counter for drawing the pipe 1
	always @(posedge clk)
	begin
		if(!reset_N) begin
			count_p1 <= 0;
			done_p1 <= 0;
		end
		else if (!plot || draw_op != 3'b001) begin
			count_p1 <= 0;
			done_p1 <= 0;		
		end
		else if (count_p1 == num_p1) begin
					count_p1 <= 0;
					done_p1 <= 1;
				end			
		else
			count_p1 <= count_p1 + 1'b1;
		
						
	end
	
	//counter for drawing the pipe 2
	always @(posedge clk)
	begin
		if(!reset_N) begin
			count_p2 <= 0;
			done_p2 <= 0;
		end
		else if (!plot || draw_op != 3'b010) begin
			count_p2 <= 0;
			done_p2 <= 0;		
		end
		else if (count_p2 == num_p2) begin
					count_p2 <= 0;
					done_p2 <= 1;
				end			
		else
			count_p2 <= count_p2 + 1'b1;	
						
	end

	//counter for drawing the pipe 3
	always @(posedge clk)
	begin
		if(!reset_N) begin
			count_p3 <= 0;
			done_p3<= 0;
		end
		else if (!plot || draw_op != 3'b011) begin
			count_p3 <= 0;
			done_p3 <= 0;		
		end
		else if (count_p3 == num_p3) begin
					count_p3 <= 0;
					done_p3<= 1;
				end			
		else
			count_p3 <= count_p3 + 1'b1;	
						
	end
	
	
	//output xy multiplexier 
	always @(*)
	begin
		case (draw_op)
		3'b000: begin //draw the plane
			mux_x = plane_x + count_plane[1:0];
			mux_y = plane_y + count_plane[3:2];
			end
		3'b001: begin // draw the pipe 1
			mux_x = p1_x + count_p1[2:0]; 
			mux_y = p1_y + count_p1 [10:3];
			end
		3'b010: begin // draw the pipe 2
			mux_x = p2_x + count_p2[2:0]; 
			mux_y = p2_y + count_p2 [10:3];
			end
		3'b011: begin // draw the pipe 3
			mux_x = p3_x + count_p3[2:0]; 
			mux_y = p3_y + count_p3 [10:3];
			end
		3'b100: begin //draw coin 1
			mux_x = c1_x + count_c1[1:0];
			mux_y = c1_y + count_c1[3:2];
			end
		endcase
	end
	assign x_out = mux_x;
	assign y_out = mux_y;
	assign colour_out = colour_reg;

endmodule


module combined(
	input go, clk, reset_N,	up,
	input [1:0] delay,
	output [7:0] x_out,
	output [6:0] y_out,
	output [2:0] colour_out,
	output plot,
	output [7:0] score	
);

	wire reset_C, en_XY_plane, en_XY_p1,en_XY_p2, en_XY_p3, en_XY_c1, done_p1, done_p2, done_p3,done_c1, en_de, erase, p, ck_cld, hold, done_plane, collide;
	wire [2:0] draw_op;
	control c0(
		.clk(clk),
		.go(go),
		.reset_N(reset_N),
		.hold(hold),
		.done_plane(done_plane),
		.done_p1(done_p1),
		.done_p2(done_p2),
		.done_p3(done_p3),
		.done_c1(done_c1),
		.collide(collide),
		.reset_C(reset_C),
		.en_XY_plane(en_XY_plane),
		.en_XY_p1(en_XY_p1),
		.en_XY_p2(en_XY_p2),
		.en_XY_p3(en_XY_p3),
		.en_XY_c1(en_XY_c1),
		.en_de(en_de),
		.erase(erase),
		.plot(p),
		.draw_op(draw_op),
		.ck_cld(ck_cld)
	);
	
	datapath d0(
		.delay(delay),
		.up(up),		
		.hold(hold),
		.done_plane(done_plane),
		.done_p1(done_p1),
		.done_p2(done_p2),
		.done_p3(done_p3),
		.done_c1(done_c1),
		.reset_C(reset_C),
		.en_XY_plane(en_XY_plane),
		.en_XY_p1(en_XY_p1),
		.en_XY_p2(en_XY_p2),
		.en_XY_p3(en_XY_p3),
		.en_XY_c1(en_XY_c1),
		.enable_delay(en_de),
		.erase(erase),
		.plot(p),
		.clk(clk),
		.reset_N(reset_N),		
		.x_out(x_out),
		.y_out(y_out),
		.colour_out(colour_out),
		.ck_cld(ck_cld),
		.draw_op(draw_op),
		.collide(collide),
		.score(score)
	);
	
	assign plot = p;
endmodule


// a random number generator
module lfsr(	
	input clk,
	input reset,
	output reg [7:0] height);
	
	reg [0:3] out;
	
	wire feedback;
	
	assign feedback = (out[3]^out[2]);
	
	always @(posedge clk)
	begin
		if (!reset)
			out <= 4'b1111;
		else begin
			out <= {feedback, out[0:2]};
		end
	end
	
	always @(*)
	begin
		case (out)
		0: height = 8'd25;
		1: height = 8'd30;
		2: height = 8'd35;
		3: height = 8'd40;
		4: height = 8'd45;
		5: height = 8'd50;
		6: height = 8'd55;
		7: height = 8'd60;
		8: height = 8'd65;
		9: height = 8'd70;
		10: height = 8'd75;
		11: height = 8'd80;
		12: height = 8'd85;
		13: height = 8'd90;
		14: height = 8'd95;
		15: height = 8'd100;
		default: height = 8'd25;
		endcase
	end
endmodule


module hxdisplay(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule

