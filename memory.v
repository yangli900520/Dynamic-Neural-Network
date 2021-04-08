module memory #(parameter inWidth = 121,
    parameter weightWidth = 16,
    parameter memoryDepth = 7)
(
   output reg signed [weightWidth-1:0] data_out,
   input [memoryDepth-1:0] address,
   input signed [weightWidth-1:0] data_in,
   input write_enable,
   input clk,
   input reset
);
   reg [weightWidth-1:0] memory [inWidth-1:0];
    integer i;

//    always @(reset) begin
//        if (reset) begin
//            for (i=0; i<121; i=i+1) memory[i] <= 16'd0;
//        end
//        end

   always @(posedge clk or posedge reset) begin
        if (reset) begin
                for (i=0; i<inWidth; i=i+1) memory[i] <= 16'd0;
				data_out <= 0;
        end
        else if (write_enable) begin
                memory[address] <= data_in;
		end
        else begin
			data_out <= memory[address];
		end
   end

endmodule