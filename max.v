module max #(parameter featureWidth = 16)
(
	input signed [featureWidth-1:0] x_1,
	input signed [featureWidth-1:0] x_2,
	input signed [featureWidth-1:0] x_3,
	input signed [featureWidth-1:0] x_4,
	input signed [featureWidth-1:0] x_5,
	input signed [featureWidth-1:0] x_6,
	input signed [featureWidth-1:0] x_7,
	input signed [featureWidth-1:0] x_8,
	input enable,
	input clk,
	input reset,
	input start,
	
	output reg [2:0] maxindex,
	output reg outvalid,
	output reg signed [featureWidth-1:0] max
);
    integer i;
    reg [3:0] cnt;
    reg cntend;
    reg signed [featureWidth-1:0] buffer [8:0];
   //max = 0;
   //maxindex = 0;
   always @(posedge clk or posedge reset) begin
    if (reset) begin
        cnt <= 0;    
        cntend <= 0;    
        max <= 16'b1000000000000000;
		outvalid <= 0;
		maxindex <= 0;
        for (i=0; i<9; i=i+1) buffer[i] <= 16'b1000000000000000;
    end
       
	 else if (enable) begin
		// if (start) begin // register the inputs
		  buffer[0] <= 16'b1000000000000000; //for latch inferral
		  buffer[1] <= x_1;
		  buffer[2] <= x_2;
		  buffer[3] <= x_3;
		  buffer[4] <= x_4;
		  buffer[5] <= x_5;
		  buffer[6] <= x_6;
		  buffer[7] <= x_7;
		  buffer[8] <= x_8;
		  // cnt <= 0;    
		  // cntend <= 0;
		  // max <= -{15{1'b1}};
		  // outvalid <= 0;
		// end
	   //else begin
		  outvalid <= 0;
		  if (buffer[cnt] > max) begin
				maxindex <= cnt-1;
				max <= buffer[cnt];
		  end
		  else begin
				maxindex <= maxindex;
				max <= max;
		  end
		 //cnt <= cnt + 3'b1;
		 //tmpcnt <= cnt;
		 
		if (!cntend) begin
			if (cnt < 8) begin //no of output layer neurons 
            	cnt <= cnt + 4'b1;
				outvalid <= 0;
			end 
			else begin
				cntend <= 1;
				outvalid <= 1;
			end
		end		
		else begin
			max <= 16'b1000000000000000;
			cntend <= 0;
			cnt <= 0;
			outvalid <= 0;
		end


//		 if (cnt>3'd6) begin
//			outvalid <= 1;
//			cnt <= 0;
//		 end
		 
	    //end
		 
    end 
	else begin
		max <= 16'b1000000000000000;
		cntend <= 0;
		cnt <= 0;
		outvalid <= 0;
	end
end
endmodule
