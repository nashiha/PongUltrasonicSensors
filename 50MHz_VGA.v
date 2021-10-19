// Author: Burak Gök
// Date: 15/11/2015
module sync_gen50(
	input clk,
	output reg[9:0] h_count, v_count,
	output reg valid, hsync, vsync);
	
	parameter h_pulse = 96;     // horizontal sync pulse width in pixels
	parameter h_bp = 48;        // horizontal back porch width in pixels
	parameter h_pixels = 640;   // horizontal display width in pixels
	parameter h_fp = 16;        // horizontal front porch width in pixels
	parameter h_pol = 0;        // horizontal sync pulse polarity (1 = positive, 0 = negative)
	parameter v_pulse = 2;      // vertical sync pulse width in rows
	parameter v_bp = 29;        // vertical back porch width in rows, "33"
	parameter v_pixels = 480;   // vertical display width in rows
	parameter v_fp = 10;        // vertical front porch width in rows
	parameter v_pol = 0;        // vertical sync pulse polarity (1 = positive, 0 = negative)
	
	// SVGA 800x600 72Hz (pixel clock: 50MHz)
//	parameter h_pulse = 120, h_bp = 61, h_pixels = 806, h_fp = 53, h_pol = 1,
//             v_pulse = 6,   v_bp = 21, v_pixels = 604, v_fp = 35, v_pol = 1;
				 
	// SVGA 800x600 60Hz (pixel clock: 40MHz)
//	parameter h_pulse = 128, h_bp = 88, h_pixels = 800, h_fp = 40, h_pol = 1,
//             v_pulse = 4,   v_bp = 23, v_pixels = 600, v_fp = 1,  v_pol = 1;
	
	parameter h_period = h_pulse + h_bp + h_pixels + h_fp;
	parameter v_period = v_pulse + v_bp + v_pixels + v_fp;
	
	reg cycle;
	always @ (posedge clk) begin
		cycle = ~cycle;
	end

	// Counters
	always @ (posedge cycle) begin
		if (h_count < h_period - 1)      // horizontal counter (pixels)
			h_count <= h_count + 1;
		else begin
			h_count <= 0;
			if (v_count < v_period - 1)   // vertical counter (rows)
				v_count <= v_count + 1;
			else
				v_count <= 0;
		end
	end
	
	//        ↕ Reference point
	// ──┐ ┌───────────────────────────┐ ┌─ hsync, vsync
	//   └─┘░░                       ░░└─┘
	//    P BP                       FP P
	//        ┌─────────────────────┐
	// ───────┘                     └────── valid (video signal)
	always @ (posedge cycle) begin
		// horizontal sync signal
		hsync <= (h_count < h_pixels + h_fp || h_count > h_pixels + h_fp + h_pulse) 
					? ~h_pol // deassert horizontal sync pulse
					: h_pol; // assert horizontal sync pulse
					
		// vertical sync signal
		vsync <= (v_count < v_pixels + v_fp || v_count > v_pixels + v_fp + v_pulse) 
					? ~v_pol // deassert vertical sync pulse
					: v_pol; // assert vertical sync pulse

		// set display enable output
		valid <= (h_count < h_pixels && v_count < v_pixels); // display/blanking time; enable/disable display
	end

endmodule
