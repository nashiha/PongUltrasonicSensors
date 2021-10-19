// Parallax PING))) Controller
// Author: Burak Gök
// Date: 23/11/2015
module ping_controller(
	input clk,            // 50MHz Clock
	inout sig,
	output reg[8:0] dist // 0-318 cm
	);
	
	reg _sig = 0;
	reg[2:0] state = 3'b000;  // 7-state FSM
	reg[25:0] counter;        // up to 925000 (18.5 ms)
	reg[11:0] cm_counter;     // up to 2914
	
	assign sig = _sig;
	
	reg[8:0] temp;
	
	always @ (posedge clk)
		case (state)
			3'b000: // Set SIG to LOW
			begin
				_sig = 0;
				temp = 0;
				counter = 0;
				state = 3'b001;
			end
			
			3'b001: // Keep SIG LOW (~2us) & Set SIG to HIGH -- pulseOut started
			begin
				counter = counter + 1;
				if (counter == 100) begin
					_sig = 1;
					counter = 0;
					state = 3'b010;
				end
			end
			
			3'b010: // Keep SIG HIGH for (min: 2us, typical: 5us) & Set SIG to LOW  -- pulseOut ended
			begin
				counter = counter + 1;
				if (counter == 250) begin
					_sig = 0;
					counter = 0;
					state = 3'b011;
				end
			end
			
			3'b011: // Keep SIG LOW (~2us)
			begin
				counter = counter + 1;
				if (counter == 100) begin
					_sig = 1'bz;
					counter = 0;
					state = 3'b100; // 101, 111, 100
				end
			end
			
			3'b100: // Wait for the sensor to become stable. When it is, it emits HIGH signal. (~6us)
			begin
				counter = counter + 1;
				if (counter == 300) begin
					counter = 0;
					state = 3'b101;
				end
			end
			
			3'b101: // Wait until SIG to become LOW  -- pulseIn ended (min: 115us, max: 18.5ms)
			begin
				counter = counter + 1;
				cm_counter = cm_counter + 1;
				if (cm_counter == 2914) begin
					cm_counter = 0;
					temp = temp + 1;
				end
				if (!sig || counter == 925000) begin
					dist = temp;
					counter = 0;
					state = 3'b110;
				end
			end
			
			3'b110: // Wait before the next measurement (min: 200us, used: 20ms-enough)
			begin
				counter = counter + 1;
				if (counter == 1000000) begin
					state = 3'b000;
				end
			end
			
		endcase
		
endmodule
