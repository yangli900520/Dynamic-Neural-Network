module relu #(parameter weightWidth = 16,
		parameter featureWidth = 16)
(    
    input signed [featureWidth-1:0] x,
    input enable,
    input clk,
    output reg [featureWidth-1:0] finalout
);
    always @(posedge clk) begin
        if (enable) begin
            if (!x[featureWidth-1]) //check MSB if 0 it is positive else it is neg
                finalout <= x;
            else
                finalout <= 0;
        end
        else begin
            finalout <= 0;    
        end
    end
    
    
endmodule