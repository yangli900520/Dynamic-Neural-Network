`timescale 1 ns / 1 ps

module harfrontendlogicmain #(parameter inWidth = 16, parameter weightWidth = 16)
(
	// declare inputs
	input clk,
	input reset,
	input weight_valid_NN,
	input feature_valid_NN,
	input signed [((inWidth-1)*weightWidth)-1:0] feature,
	input signed [weightWidth-1:0] weight,
	output output_valid_NN,
	output wire [15:0] max_out_NN,
	output wire [2:0] maxindex_out_NN,
	output wire NN_busy,
	output wire waiting_weight_NN
);


// Main logic here. We will send inputs one by one to the filtering block and the segmentation block
// Whenever we detect a segment, we will check the count of the samples.
//Eventually they need to go to a memory

	
	//NN
	wire NN_input_valid;
	//wire NN_busy;
	//wire signed [weightWidth-1:0] weight; 
	//wire signed [4*featureWidth-1:0] layer1Out;
	//wire signed [8*featureWidth-1:0] layer2Out;
	//wire signed [7*featureWidth-1:0] layer3Out;
			
	assign NN_input_valid = feature_valid_NN | weight_valid_NN;
	topNN NN_14_16_16_3 (.clk(clk) , .feature(feature), .weight(weight), .reset(reset), .input_valid(NN_input_valid), .busy(NN_busy), .startMax(), .finalvalid(output_valid_NN), .max(max_out_NN), .maxindex(maxindex_out_NN), .waitingWeight(waiting_weight_NN));
endmodule
			
			
			
