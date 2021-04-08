module mac #(    parameter weightWidth = 16,
	parameter featureWidth = 16,
    parameter memoryDepth = 7
    )
(
    input signed [weightWidth-1:0] a,
    input signed [featureWidth-1:0] b,
    input clk, reset, sload,
    output reg signed [featureWidth+weightWidth:0] f
);

    // Declare registers and wires
    reg signed [weightWidth-1:0] l1;
    reg signed [featureWidth-1:0] l2;
    reg signed [featureWidth+weightWidth:0] add;
    reg sloadreg;
    wire signed [featureWidth+weightWidth-1:0] mul;
    
    // Store the results of the operations on the current data
    assign mul = l1 * l2;
    
    // Store the value of the accumulation (or clear it)
    always @ (*)
    begin
		if (reset) begin
			add <= 0;
		end
		else begin
			if (sloadreg) begin
				add <= 0;
			end
			else begin
				add <= f;
			end
		end
    end
    
    // Clear or update data, as appropriate
    always @ (posedge clk or posedge reset)
    begin
        if (reset) begin
            l1 <= 0;
            l2 <= 0;
            f <= 0;
			//add <= 0;
            sloadreg <= 0;
        end
        
        else begin
            l1 <= a;
            l2 <= b;
            f <= add + mul;
            sloadreg <= sload;
        end
    end
endmodule
