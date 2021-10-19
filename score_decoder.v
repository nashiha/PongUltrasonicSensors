
module score_decoder(
	input [3:0] score1, score2,
	input [9:0] XPos, YPos,
	output player1, player2
	);
	
	parameter swh = 320, dt = 20, sp = 20, pxm = 8;
	parameter dw = 3*pxm, dh = 5*pxm;
	parameter d1l = swh - (sp + dw), d1r = swh - sp, d2l = swh + sp, d2r = swh + sp + dw, db = dt + dh;
	
	reg [0:14] font [9:0];
	
	always begin
		font[0] = 15'b111101101101111;
		font[1] = 15'b010010010010010;
		font[2] = 15'b111001111100111;
		font[3] = 15'b111001111001111;
		font[4] = 15'b101101111001001;
		font[5] = 15'b111100111001111;
		font[6] = 15'b111100111101111;
		font[7] = 15'b111001001001001;
		font[8] = 15'b111101111101111;
		font[9] = 15'b111101111001111;
	end
	
	wire [9:0] s1x = XPos - d1l, s2x = XPos - d2l, sy = YPos - dt;
	wire [2:0] s1px = s1x / pxm, s2px = s2x / pxm, spy = sy / pxm;
	
	wire [0:14] dig1 = font[score1];
	wire [0:14] dig2 = font[score2];
	
	assign player1 = (YPos >= dt && YPos < db) && 
						  (XPos >= d1l && XPos < d1r && dig1[s1px + 3*spy]);
					  
	assign player2 = (YPos >= dt && YPos < db) &&
					     (XPos >= d2l && XPos < d2r && dig2[s2px + 3*spy]);

//	assign fill = (sy > 0 && sy <= dh) && 
//				  ((s1x >= 0 && s1x < dw) || (s2x >= 0 && s2x < dw));

endmodule
