module outDown #(
		parameter weightWidth = 16,
		parameter featureWidth = 16,
		parameter div = 7
    )
	 
	 (
	 input reset,
	 input clk,
	 input enable,
	 input signed [featureWidth+weightWidth:0] in,
	 output signed [featureWidth-1:0] out
	 );
	 
	 reg [featureWidth+weightWidth:0] tmp;
	 
	 always @(posedge clk or posedge reset) begin
	 if (reset) begin
		//out <= 0;
		tmp <= 0;
	 end
	 else begin
		 if (enable) begin
				tmp <= in >> div;
		 end
		 else begin
				tmp <= 0;
		 end
	 end
	 end
	 
	 assign out = tmp[featureWidth-1:0];
	 
endmodule
		
		