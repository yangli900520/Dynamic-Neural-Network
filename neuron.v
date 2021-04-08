module neuron #(    parameter inWidth = 120,
    parameter weightWidth = 16,
	parameter featureWidth = 16,
    parameter memoryDepth = 7, // 2^7 addresses
	parameter div = 4, // divide by 2^4 before truncation
    parameter layerselect = 1,
    parameter confugnum = 4
	 )
(
    input startup,
    input reset,
    input enable,
    input signed [(inWidth*featureWidth)-1:0] in,
    input signed [weightWidth-1:0] weight,
    input clk,
    output wire signed [featureWidth-1:0] out, //what will the size be???
    output reg outvalid, tmp3
);    
    //reg resetmac;
    reg we;
    reg tmp, tmp2, newIn, macreset; //pipelining registers
    reg [memoryDepth-1:0] raddr;
    reg [memoryDepth-1:0] waddr;
    reg [memoryDepth-1:0] idx;
    wire signed [weightWidth-1:0] ramOut;
    wire signed [weightWidth+featureWidth:0] macOut;
	 wire signed [featureWidth-1:0] truncateOut;
    reg [memoryDepth-1:0] addr;
    reg signed [featureWidth-1:0] qIn;
    reg signed [weightWidth-1:0] macIna;
    reg signed [featureWidth-1:0] macInb;
    reg [memoryDepth-1:0] qidx;
    
    reg signed [weightWidth+featureWidth-1:0] multout [inWidth-1:0];
    reg signed [weightWidth-1:0] weighreg [inWidth-1:0];
    reg [weightWidth-1:0] memory [inWidth-1:0];
    wire [weightWidth+featureWidth-1:0] macoutt [confugnum-1:0];
    integer i = 0;
    integer j = 0;
    integer g = 0; 
    integer h = 0;
 
    

    

    always @(*) begin //mux address to be sent to memory depending on the mode (write or read).
    if (reset) begin
        addr <= 0;
        we <= 0;
    end
    
    else if (enable) begin
        case (startup)
        1: begin
            addr <= waddr;
            we <= 1;
        end
        0: begin
            addr <= raddr;
            we <= 0;
        end
		default: begin
            we <= 0;
            addr <= 0;
        end			  
        endcase
    end //end enable
    else begin
        addr <= 0;
        we <= 0;
    end //end else enable
    end

    always @(*) begin //mux inputs to be sent to MAC depending on the mode (write or read).
    if (reset) begin
        macIna <= 0;
        macInb <= 0;
    end
    
    else if (enable) begin
        case (startup)
        1: begin
            macIna <= 0;
            macInb <= 0;
        end
        0: begin
            macIna <= ramOut;
            macInb <= qIn;
        end
		default: begin
            macIna <= 0;
            macInb <= 0;
        end							
        endcase
    end //end enable
    else begin
        macIna <= 0;
        macInb <= 0;
    end //end else enable
    end

    
    always @(posedge clk or posedge reset) begin // writing to memory or reading from memory.
    if (reset) begin
        raddr <= 0;
        waddr <= 0;
		newIn <= 0;
		for (i = 0; i < inWidth+1; i = i + 1) begin
		    weighreg[i] <= 0;
		end
    end
    else if (enable) begin
        if (startup) begin
			newIn <= 0;
            raddr <= 0;
            weighreg[j] <= weight;
            j     <= j + 1;
			if (waddr < inWidth-1) begin
				waddr <= waddr + 7'd1;
			end 
			else begin
				waddr <=0;
			end
        end
        else begin
            waddr <= 0;
			if (raddr < inWidth-1) begin
				raddr <= raddr + 7'd1;
				newIn <= 0;
			end 
			else begin
				raddr <=0;
				newIn <= 1;
			end
        end
    end //end enable
	else if (!enable) begin
		raddr <=0;
		waddr <= 0;
		newIn <= 0;
	end
    end
    
    always @(posedge clk or posedge reset) begin // register newIn to add 4 clock cycles of delay, tmp3 is the outvalid flag for the last neuron (-1 clock cycle delay).
    if (reset) begin
        tmp <= 0;
		tmp2 <= 0;
		tmp3 <= 0;
		outvalid <= 0;
		macreset <= 1;
    end
    else if (enable) begin
        tmp <= newIn;
		tmp2 <= tmp;
		tmp3 <= tmp2;
		outvalid <= tmp3;
		macreset <= 0;
	end
	else if (!enable) begin
		macreset <= 1;
	end
    end
	     
    always @(posedge clk or posedge reset) begin
    if (reset) begin
        qIn <= 0;
    end
    else if (enable) begin
		if (!startup) begin
			qIn <= in >> (raddr * featureWidth);
			//qIn <= raddr * featureWidth;
		end 
		else begin
			qIn <= 0;
		end
	end
	else if (!enable) begin 
		qIn <= 0;
	end
    end
    
    always @(posedge clk or posedge reset) begin
    if (macreset) begin
         for (g = 0; g < inWidth; g = g + 1) begin
            multout [g] <= 0;
         end
    end
    else if (enable) begin
        if (!startup) begin
        for (i = 0; i < inWidth; i = i + 1) begin
            multout [i] <= weighreg[i] * in[i*featureWidth+:featureWidth];
            
        end
        end
    end
    end   
        
   always @(posedge clk or posedge reset) begin
        if (reset) begin
                for (h=0; h<inWidth; h=h+1) memory[h] <= 16'd0;
        end
        else if (we) begin
                memory[addr] <= weight;
		end
   end    
    
 generate
 genvar I;
   for (I=0; I<confugnum; I=I+1) begin
      //  always @(posedge clk) begin
              if (I==0) begin
                  fourmultthreeadd #(
                               .AWIDTH(weightWidth),
                               .BWIDTH(weightWidth),
                               .CWIDTH(weightWidth),
                               .DWIDTH(weightWidth),
                               .EWIDTH(weightWidth),
                               .PWIDTH(weightWidth+featureWidth),
                               .dsize(weightWidth)
                              )
               fourmultthreeadd_inst0 (
                              .clk(clk),
                              .rst(reset),
                              .a(in[I*confugnum*featureWidth+:featureWidth]),
                              .b(in[(I*confugnum+1)*featureWidth+:featureWidth]),
                              .c(in[(I*confugnum+2)*featureWidth+:featureWidth]),
                              .d(in[(I*confugnum+3)*featureWidth+:featureWidth]),
                              .a_w(memory[I*confugnum]),
                              .b_w(memory[I*confugnum+1]),
                              .c_w(memory[I*confugnum+2]),
                              .d_w(memory[I*confugnum+3]),  
                              .macoutt(0),                           
                              .ce(enable),
                              .p(macoutt[I])
                               );
               end
               else begin
                                 fourmultthreeadd #(
                               .AWIDTH(weightWidth),
                               .BWIDTH(weightWidth),
                               .CWIDTH(weightWidth),
                               .DWIDTH(weightWidth),
                               .EWIDTH(weightWidth),
                               .PWIDTH(weightWidth+featureWidth),
                               .dsize(weightWidth)
                              )
               fourmultthreeadd_inst (
                              .clk(clk),
                              .rst(reset),
                              .a(in[I*confugnum*featureWidth+:featureWidth]),
                              .b(in[(I*confugnum+1)*featureWidth+:featureWidth]),
                              .c(in[(I*confugnum+2)*featureWidth+:featureWidth]),
                              .d(in[(I*confugnum+3)*featureWidth+:featureWidth]),
                              .a_w(memory[I*confugnum]),
                              .b_w(memory[I*confugnum+1]),
                              .c_w(memory[I*confugnum+2]),
                              .d_w(memory[I*confugnum+3]),  
                              .macoutt(macoutt[I-1]),                           
                              .ce(enable),
                              .p(macoutt[I])
                               );
               end
               end
  endgenerate           
    
    
    
    
    memory #(inWidth, weightWidth, memoryDepth) xMEM( .data_out(ramOut), .address(addr), .data_in(weight), .write_enable(we), .clk(clk), .reset(reset) );
    mac #(weightWidth,featureWidth,memoryDepth) xMAC(.clk(clk), .reset(macreset), .a(macIna), .b(macInb), .sload(macreset), .f(macOut));
    
	generate
		if ( layerselect < 4 ) begin
			outDown #(weightWidth,featureWidth,div) xDown(.clk(clk), .reset(reset), .enable(enable), .in(macoutt[I]), .out(truncateOut));
			relu #(weightWidth, featureWidth)  xRELU(.enable(enable), .clk(clk), .x(truncateOut), .finalout(out));
		end
		else begin
			outDown #(weightWidth,featureWidth,div) xDown(.clk(clk), .reset(reset), .enable(enable), .in(macoutt[I]), .out(out));
		end
    endgenerate
	 

endmodule