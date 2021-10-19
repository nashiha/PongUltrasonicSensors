
module pong(
	input clk,
	input p1c, p2c,         // Paddle Test Inputs
	inout tri sig1, sig2,   // Ultrasonic Sensor Signals
	input rst, frz,         // Reset & Freeze Game Signals
	input mute,             // Mute Signal
	output hsync, vsync,    // VGA Sync Signals
	output[7:0] rgb,        // VGA Color Signal
	output speaker,         // Amplifier Signal
	output[8:0] led
	);
	
	parameter lr = 4, lw = 2 * lr;
	parameter pe = 10; // paddle elevation
	parameter pw = 10, ph = 80, br = 10; // paddle width & height, ball radius
	parameter pf = pe + pw, phh = ph / 2, brs = br**2;
	parameter sw = 640, sh = 480; // screen width & height
	parameter swh = sw / 2, shh = sh / 2;
	
	reg [25:0] counter = 0;
	reg cycle;                    // slow clock for game graphics
	reg [9:0] p1 = shh, p2 = shh; // paddle positions
	reg [9:0] bx = swh, by = shh; // position components of ball
	reg [3:0] vx = 5, vy = 3;     // speed components of ball
	reg dx = 1, dy = 0;           // direction components of ball
	
	reg [3:0] score1 = 0, score2 = 0;
	
	wire [9:0] XPos, YPos; // raster positions
	wire valid; // indicates whether raster positions are in visible area
	wire [8:0] dist1, dist2; // ultrasonic sensor data

	sync_gen50 syncVGA( // VGA Controller
			.clk(clk),
			.h_count(XPos), .v_count(YPos),
			.valid(valid),
			.hsync(hsync), .vsync(vsync));
			
	ping_controller ping1( // Ultrasonic Sensor Controller #1
			.clk(clk),
			.sig(sig1),
			.dist(dist1));
			
	ping_controller ping2( // Ultrasonic Sensor Controller #2
			.clk(clk),
			.sig(sig2),
			.dist(dist2));

	wire paddle1 = (XPos > pe && XPos < pf) && (YPos > p1 - phh && YPos < p1 + phh);
	wire paddle2 = (XPos > sw - pf && XPos < sw - pe) && (YPos > p2 - phh && YPos < p2 + phh);
	wire line    = (XPos > swh - lr && XPos < swh + lr) && ((YPos / lw) % 2 == 0);
	wire player1, player2;
	
	score_decoder scr_dec(score1, score2, XPos, YPos, player1, player2);
	
	wire signed[9:0] diff_bx = XPos - bx, diff_by = YPos - by;
	wire ball = diff_bx*diff_bx + diff_by*diff_by <= brs;

	assign rgb = valid 
					? (paddle1 || player1) ? 8'b10011011 : ((paddle2 || player2) ? 8'b11110000
						: (ball ? 8'b11010011 : (line ? 8'b10110111 : 8'b00000000)))
					: 8'b00000000; // It is necessary to set the color to black for invalid region.
	
	always @ (posedge clk)
	begin
		counter = counter + 1;
		if (counter == 1000000) begin // 20ms
			counter = 0;
			cycle = ~cycle;
		end
	end
	
//	reg[5:0] pct;
	
	reg [3:0] rnd; // Random number. This number is unpredictable since how many 
	               // times this number changes until next round is unpredictable 
				      // because it depends on both Vx that changes according to this 
				      // number and the player.
	always @ (posedge cycle)
		rnd = (rnd == 4'b1111) ? 4'b0000 : {rnd[2:0], !(rnd[3] ^ rnd[2])};
	
	reg [1:0] sound_sel; // Sound Select
	reg sound_en;        // Sound Enable
	
	game_audio audio(clk, mute, sound_en, sound_sel, speaker);
	
	reg over = 0;
	
	always @ (posedge cycle, posedge rst) // 25 frame per second
		if (rst) begin
			score1 = 0; score2 = 0;
			p1 = shh; p2 = shh;
			bx = swh; by = shh;
			vy = 3 + rnd[1:0];
			vx = 8 - vy;
			dx = 1;
			dy = rnd[0];
		end
		else if (!frz) begin
	
		p1 = sh - dist1 * 12 + phh;
		p2 = sh - dist2 * 12 + phh;

		// Paddle Test
//		if (p1c) p1 = (p1 - 5 < phh) ? phh : p1 - 5;
//		if (!p1c) p1 = (p1 + 5 > sh - phh) ? sh - phh : p1 + 5;
//		if (p2c) p2 = (p2 - 5 < phh) ? phh : p2 - 5;
//		if (!p2c) p2 = (p2 + 5 > sh - phh) ? sh - phh : p2 + 5;
		
		sound_en = 0;
		
		// Walls - A priori
		if (!dy && by - br <= vy) begin by = br; dy = ~dy; sound_en = 1; sound_sel = 0; end
		else if (dy && by + br >= sh - vy) begin by = sh - br; dy = ~dy; sound_en = 1; sound_sel = 0; end
		else begin by = dy ? by + vy : by - vy; end
		
//		// Paddles Heights (range check missing)
//		if (!dx && bx - br <= pf + vx 
//			&& (by >= p1 - phh && by <= p1 + phh)) begin bx = pf + br; dx = ~dx; end
//		else if (dx && bx + br >= sw - (pf + vx)
//			&& (by >= p2 - phh && by <= p2 + phh)) begin bx = sw - (pf + br); dx = ~dx; end
//		// Score Regions
////		else if (bx <= vx || bx >= sw - vx) begin
////			if (bx <= vx) score2 = score2 + 1;
////			else score1 = score1 + 1;
////			p1 = shh; p2 = shh;
////			bx = swh; by = shh;
////		end
//		else bx = dx ? bx + vx : bx - vx;

		// Paddles - A posteriori
		bx = dx ? bx + vx : bx - vx;
		if (!dx && (bx >= pe && bx <= pf && by >= p1 - phh && by <= p1 + phh)) begin
			bx = pf + br;
			dx = ~dx;
			sound_en = 1; sound_sel = 0;
//			pct = (pf - bx + br) * vy / vx;
//			by = dy ? by - pct : by + pct;
		end
		else if (dx && (bx >= sw - pf && bx <= sw - pe && by >= p2 - phh && by <= p2 + phh)) begin
			bx = sw - (pf + br);
			dx = ~dx;
			sound_en = 1; sound_sel = 0;
//			pct = (bx + pf - sw + br) * vy / vx;
//			by = dy ? by - pct : by + pct;
		end
		
		if (bx <= vx || bx >= sw - vx) begin
			sound_en = 1; 
			if (bx <= vx) score2 = score2 + 1;
			else score1 = score1 + 1;
			bx = swh; by = shh;
			if (score1 == 9 || score2 == 9) begin
				vx = 0; vy = 0;
				sound_sel = 2;
			end
			else begin // reset round
				sound_sel = 1;
				vy = 3 + rnd[1:0];
				vx = 8 - vy;
				dx = (score1 < score2) ? 1 : 0;
				dy = rnd[0];
			end
		end
	end
	
//	assign led = dist1;

endmodule


