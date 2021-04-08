
module topNN (clk, feature, weight, reset, input_valid, busy, startMax, finalvalid, max, maxindex,waitingWeight);

    parameter inWidth = 16;
    parameter weightWidth = 16;
    parameter featureWidth = 16;
    parameter memoryDepth = 7;
    parameter L1N = 16;
    parameter L2N = 16;
    parameter L3N = 16;
	parameter L4N = 3;
	localparam L1bias = 0; // These are not used atm.
	localparam L2bias = 0;
	localparam L3bias = 0;
	localparam L4bias = 0;

    input reset;
    input signed [((inWidth-1)*weightWidth)-1:0] feature;
    input signed [weightWidth-1:0] weight;
    input clk;
	input input_valid;
	output reg busy;
	output wire signed [featureWidth-1:0] max; // output neuron value
	output wire startMax, finalvalid;
	output wire [2:0] maxindex; // output neuron index
    output reg waitingWeight;
	
	reg signed [L4N*featureWidth-1:0] maxin;
	
	reg signed [weightWidth-1:0] weightreg;
    reg [10:0] cnt;
    reg [(L1N+L2N+L3N+L4N-1):0] startupN;
    reg [(L1N+L2N+L3N+L4N-1):0] resetN;
    reg [(L1N+L2N+L3N+L4N-1):0] enableN;
	reg hardResetNeurons;
	reg signed [inWidth*featureWidth-1:0] layer1in;
    reg signed [(L1N+1)*featureWidth-1:0] layer2in;
    reg signed [(L2N+1)*featureWidth-1:0] layer3in;
	reg signed [(L3N+1)*featureWidth-1:0] layer4in;
	wire signed [L1N*featureWidth-1:0] layer1Out; 
    wire signed [L2N*featureWidth-1:0] layer2Out; 
    wire signed [L3N*featureWidth-1:0] layer3Out; 
	wire signed [L4N*featureWidth-1:0] layer4Out; 
    wire [(L1N+L2N+L3N+L4N-1):0] outvalid; //51 neurons
    
    integer i;
    
    
    localparam init = 0, ramload=1, L1idle = 2, L1busy = 3; // 4 states, ramload is the state where we load the neuron weights into rams. Layer 1 determines the system busy/idle state.
	localparam w1 = 0, w2 = 1, w3 = 2, w4 = 3, w5 = 4, w6 = 5, w7 = 6, w8 = 7, w9 = 8, w10 = 9, w11 = 10, w12 = 11, w13 = 12, w14 = 13, w15 = 14, w16 = 15, 
				w17 = 16, w18 = 17, w19 = 18, w20 = 19, w21 = 20, w22 = 21, w23 = 22, w24 = 23, w25 = 24, w26 = 25, w27 = 26, w28 = 27, w29 = 28, w30 = 29, w31 = 30, w32 = 31, 
				w33 = 32, w34 = 33, w35 = 34, w36 = 35, w37 = 36, w38 = 37, w39 = 38, w40 = 39, w41 = 40, w42 = 41, w43 = 42, w44 = 43, w45 = 44, w46 = 45, w47 = 46, w48 =  47, 
				w49 = 48, w50 = 49, w51 = 50, 
				wfin = 51, wbeg = 52; //memory filling states (ramload)
	localparam L2L3L4MAXidle = 0, L2busyL3L4MAXidle = 1, L3busyL2L4MAXidle = 2, L4busyL2L3MAXidle = 3, MAXbusyL2L3L4idle = 4; // 5 states for Layer 2, Layer 3, Layer 4 and Max.
	
	reg [1:0] state, nxtState; //neural network states
	reg [5:0] wstate, nxtWstate; //individual neuron memory write states
	reg [2:0] hiddenState, nxthiddenState; //neural network states
	
	reg enableMax;
    
	always @(posedge clk or posedge reset) begin // state logic
	if (reset) begin
		cnt <= 10'd0;
		weightreg <= 0;
		enableN <= 51'b0; //disable all neurons
		startupN <= 51'b0; //do not start write mode yet 
		resetN <= 51'b1111111111111111111111111111111111111111111111111; //reset all neurons
		enableMax <= 1'b0; //disable Max (output function)
		waitingWeight <= 1'b0;
		busy <= 1'b1;
		layer1in <= 0;
		layer2in <= 0;
		layer3in <= 0;
		layer4in <= 0;
		maxin <= 0;
	end
	else begin
		case(state)
		init: begin
			cnt <= 10'd0;
			enableN <= 51'b0; //disable all neurons
			startupN <= 51'b0; //do not start write mode yet 
			resetN <= 51'b1111111111111111111111111111111111111111111111111; //reset all neurons
			enableMax <= 1'b0; //disable Max (output function)
			waitingWeight <= 1'b0;
			busy <= 1'b1;
			layer1in <= 0;
			layer2in <= 0;
			layer3in <= 0;
			layer4in <= 0;
		end
		
		ramload: begin
			if (input_valid) begin
				weightreg <= weight;
			end else begin
				weightreg <= 0;
			end
			case (wstate)
				wfin: begin
					busy <= 1'b1;
					waitingWeight <= 1'b0;
					cnt <= 10'd0;
					resetN <= 51'b0;
					startupN <= 51'b0; //finish reading mode in all neurons (reading weights from weight memories)
					enableN <=  51'b0;
				end
				
				w51: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b000000000000000000000000000000000000000000000000000;
					startupN <= 51'd1125899906842624;
					enableN <= 51'd1125899906842624;
				end
				w50: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b100000000000000000000000000000000000000000000000000;
					startupN <= 51'd562949953421312;
					enableN <= 51'd562949953421312;
				end
				w49: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b110000000000000000000000000000000000000000000000000;
					startupN <= 51'd281474976710656;
					enableN <= 51'd281474976710656;
				end
				w48: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111000000000000000000000000000000000000000000000000;
					startupN <= 51'd140737488355328;
					enableN <= 51'd140737488355328;
				end
				w47: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111100000000000000000000000000000000000000000000000;
					startupN <= 51'd70368744177664;
					enableN <= 51'd70368744177664;
				end
				w46: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111110000000000000000000000000000000000000000000000;
					startupN <= 51'd35184372088832;
					enableN <= 51'd35184372088832;
				end
				w45: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111000000000000000000000000000000000000000000000;
					startupN <= 51'd17592186044416;
					enableN <= 51'd17592186044416;
				end
				w44: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111100000000000000000000000000000000000000000000;
					startupN <= 51'd8796093022208;
					enableN <= 51'd8796093022208;
				end
				w43: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111110000000000000000000000000000000000000000000;
					startupN <= 51'd4398046511104;
					enableN <= 51'd4398046511104;
				end
				w42: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111000000000000000000000000000000000000000000;
					startupN <= 51'd2199023255552;
					enableN <= 51'd2199023255552;
				end
				w41: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111100000000000000000000000000000000000000000;
					startupN <= 51'd1099511627776;
					enableN <= 51'd1099511627776;
				end
				w40: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111110000000000000000000000000000000000000000;
					startupN <= 51'd549755813888;
					enableN <= 51'd549755813888;
				end
				w39: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111000000000000000000000000000000000000000;
					startupN <= 51'd274877906944;
					enableN <= 51'd274877906944;
				end
				w38: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111100000000000000000000000000000000000000;
					startupN <= 51'd137438953472;
					enableN <= 51'd137438953472;
				end
				w37: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111110000000000000000000000000000000000000;
					startupN <= 51'd68719476736;
					enableN <= 51'd68719476736;
				end
				w36: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111000000000000000000000000000000000000;
					startupN <= 51'd34359738368;
					enableN <= 51'd34359738368;
				end
				w35: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111100000000000000000000000000000000000;
					startupN <= 51'd17179869184;
					enableN <= 51'd17179869184;
				end
				w34: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111110000000000000000000000000000000000;
					startupN <= 51'd8589934592;
					enableN <= 51'd8589934592;
				end
				w33: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111000000000000000000000000000000000;
					startupN <= 51'd4294967296;
					enableN <= 51'd4294967296;
				end
				w32: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111100000000000000000000000000000000;
					startupN <= 51'd2147483648;
					enableN <= 51'd2147483648;
				end
				w31: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111110000000000000000000000000000000;
					startupN <= 51'd1073741824;
					enableN <= 51'd1073741824;
				end
				w30: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111000000000000000000000000000000;
					startupN <= 51'd536870912;
					enableN <= 51'd536870912;
				end
				w29: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111100000000000000000000000000000;
					startupN <= 51'd268435456;
					enableN <= 51'd268435456;
				end
				w28: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111110000000000000000000000000000;
					startupN <= 51'd134217728;
					enableN <= 51'd134217728;
				end
				w27: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111111000000000000000000000000000;
					startupN <= 51'd67108864;
					enableN <= 51'd67108864;
				end
				w26: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111111100000000000000000000000000;
					startupN <= 51'd33554432;
					enableN <= 51'd33554432;
				end
				w25: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111111110000000000000000000000000;
					startupN <= 51'd16777216;
					enableN <= 51'd16777216;
				end
				w24: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111111111000000000000000000000000;
					startupN <= 51'd8388608;
					enableN <= 51'd8388608;
				end
				w23: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111111111100000000000000000000000;
					startupN <= 51'd4194304;
					enableN <= 51'd4194304;
				end
				w22: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111111111110000000000000000000000;
					startupN <= 51'd2097152;
					enableN <= 51'd2097152;
				end
				w21: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111111111111000000000000000000000;
					startupN <= 51'd1048576;
					enableN <= 51'd1048576;
				end
				w20: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111111111111100000000000000000000;
					startupN <= 51'd524288;
					enableN <= 51'd524288;
				end
				w19: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111111111111110000000000000000000;
					startupN <= 51'd262144;
					enableN <= 51'd262144;
				end
				w18: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111111111111111000000000000000000;
					startupN <= 51'd131072;
					enableN <= 51'd131072;
				end
				w17: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111111111111111100000000000000000;
					startupN <= 51'd65536;
					enableN <= 51'd65536;
				end
				w16: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111111111111111110000000000000000;
					startupN <= 51'd32768;
					enableN <= 51'd32768;
				end
				w15: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111111111111111111000000000000000;
					startupN <= 51'd16384;
					enableN <= 51'd16384;
				end
				w14: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111111111111111111100000000000000;
					startupN <= 51'd8192;
					enableN <= 51'd8192;
				end
				w13: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111111111111111111110000000000000;
					startupN <= 51'd4096;
					enableN <= 51'd4096;
				end
				w12: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111111111111111111111000000000000;
					startupN <= 51'd2048;
					enableN <= 51'd2048;
				end
				w11: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111111111111111111111100000000000;
					startupN <= 51'd1024;
					enableN <= 51'd1024;
				end
				w10: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111111111111111111111110000000000;
					startupN <= 51'd512;
					enableN <= 51'd512;
				end
				w9: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111111111111111111111111000000000;
					startupN <= 51'd256;
					enableN <= 51'd256;
				end
				w8: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111111111111111111111111100000000;
					startupN <= 51'd128;
					enableN <= 51'd128;
				end
				w7: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111111111111111111111111110000000;
					startupN <= 51'd64;
					enableN <= 51'd64;
				end
				w6: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111111111111111111111111111000000;
					startupN <= 51'd32;
					enableN <= 51'd32;
				end
				w5: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111111111111111111111111111100000;
					startupN <= 51'd16;
					enableN <= 51'd16;
				end
				w4: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111111111111111111111111111110000;
					startupN <= 51'd8;
					enableN <= 51'd8;
				end
				w3: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111111111111111111111111111111000;
					startupN <= 51'd4;
					enableN <= 51'd4;
				end
				w2: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111111111111111111111111111111100;
					startupN <= 51'd2;
					enableN <= 51'd2;
				end
				w1: begin
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= cnt + 10'd1;
					resetN <= 51'b111111111111111111111111111111111111111111111111110;
					startupN <= 51'd1;
					enableN <= 51'd1;
				end
				wbeg: begin // init state for wstate. here it waits for weights and once input is valid moves on to writing to memories starting from neuron 1. See below for transitions.
					busy <= 1'b1;
					waitingWeight <= 1'b1;
					cnt <= 10'd0;
					resetN <=   51'b111111111111111111111111111111111111111111111111111;
					startupN <= 51'b0; //switch to reading mode in all neurons (reading weights from weight memories)
					enableN <=  51'b0;
				end
				default: begin
					busy <= 1'b1;
					waitingWeight <= 1'b0;
					cnt <= 10'd0;
					resetN <= 51'b0;
					startupN <= 51'b0; //switch to reading mode in all neurons (reading weights from weight memories)
					enableN <=  51'b0;
				end
			endcase
		end
		
		L1idle: begin
			busy <= 0;
			enableN[L1N-1:0] <= 16'b0; //disable L1 neurons
			if (input_valid) begin
				layer1in <= {feature,16'd0}; //append the bias 1
			end else begin
				//layer1in <= 0;
				layer1in <= {feature,16'd0};
			end
			if (state != ramload) begin
				case(hiddenState)
					L2L3L4MAXidle: begin
						enableN[L1N+L2N+L3N+L4N-1:L1N] <= 35'b00000000000000000000000000000000000; // layer 2&3&4 neurons are disabled
						enableMax <= 0; // Max layer disabled
						maxin <= 0;
						if (outvalid[L1N-1:0] == 16'b11111111111111) begin
							layer2in <= {layer1Out,16'd0}; //append the bias 2
						end else begin
							layer2in <= 0;
						end
					end 
					
					L2busyL3L4MAXidle: begin
						enableN[L1N+L2N-1:L1N] <= 16'b1111111111111111; // layer 2 neurons are enabled
						enableMax <= 1'b0; //disable Max (output function)
						maxin <= 0;
						if (outvalid[L1N+L2N-1:L1N] == 16'b1111111111111111) begin
							layer3in <= {layer2Out,16'd0}; //append the bias 3
							enableN[L1N+L2N-1:L1N] <= 16'b0; //layer 2 neurons are disabled
						end else begin
							layer3in <= 0;
						end
					end
					
					L3busyL2L4MAXidle: begin
						enableN[L1N+L2N+L3N-1:L1N+L2N] <= 16'b1111111111111111; // layer 3 neurons are enabled
						enableMax <= 1'b0; //disable Max (output function)
						if (outvalid[L1N+L2N+L3N-1:L1N+L2N] == 16'b1111111111111111) begin
							layer4in <= {layer3Out,16'd0}; //append the bias 4 
							enableN[L1N+L2N+L3N-1:L1N+L2N] <= 16'b0; // layer 3 neurons are disabled
						end else begin
							layer4in <= 0;
						end
					end
					
					L4busyL2L3MAXidle: begin
						enableN[L1N+L2N+L3N+L4N-1:L1N+L2N+L3N] <= 3'b111; // layer 4 neurons are enabled
						enableMax <= 1'b0; //disable Max (output function)
						if (outvalid[L1N+L2N+L3N+L4N-1:L1N+L2N+L3N] == 3'b111) begin
							maxin <= layer4Out;
							enableN[L1N+L2N+L3N+L4N-1:L1N+L2N+L3N] <= 3'b000; // layer 4 neurons are disabled
						end else begin
							maxin <= 0;
						end
					end
					
					
					MAXbusyL2L3L4idle: begin
						enableMax <= 1; // Max layer enabled
										// Can be added: if final valid high, register the output and hold it.
					end
					
					default: begin
						enableN[L1N+L2N+L3N+L4N-1:L1N] <= 35'b00000000000000000000000000000000000; // layer 2&3&4 neurons are disabled
						enableMax <= 0; // Max layer disabled
						layer2in <= 0;
						layer3in <= 0;
						layer4in <= 0;
						maxin <= 0;
					end
				endcase
			end
			else begin // Ganapati
				enableN[L1N+L2N+L3N+L4N-1:L1N] <= 35'b00000000000000000000000000000000000; // layer 2&3&4 neurons are disabled 
				enableMax <= 0; // Max layer disabled
				layer2in <= 0;
				layer3in <= 0;
				layer4in <= 0;
				maxin <= 0;
			end
		end
		
		L1busy: begin
			busy <= 1'b1;
			enableN[L1N-1:0] <= 16'b11111111111111; //enable the first layer neurons (layer 1)
			if (state != ramload) begin
				case(hiddenState)
					L2L3L4MAXidle: begin
						enableN[L1N+L2N+L3N+L4N-1:L1N] <= 35'b00000000000000000000000000000000000; // layer 2&3&4 neurons are disabled
						enableMax <= 0; // Max layer disabled
						maxin <= 0;
						if (outvalid[L1N-1:0] == 16'b11111111111111) begin
							layer2in <= {layer1Out,16'd0}; //append the bias 1
						end else begin
							layer2in <= 0;
						end
					end 
					
					L2busyL3L4MAXidle: begin
						enableN[L1N+L2N-1:L1N] <= 16'b1111111111111111; // layer 2 neurons are enabled
						enableMax <= 1'b0; //disable Max (output function)
						maxin <= 0;
						if (outvalid[L1N+L2N-1:L1N] == 16'b1111111111111111) begin
							layer3in <= {layer2Out,16'd0}; //append the bias 2
							enableN[L1N+L2N-1:L1N] <= 16'b0; //layer 2 neurons are disabled
						end else begin
							layer3in <= 0;
						end
					end
					
					L3busyL2L4MAXidle: begin
						enableN[L1N+L2N+L3N-1:L1N+L2N] <= 16'b1111111111111111; // layer 3 neurons are enabled
						enableMax <= 1'b0; //disable Max (output function)
						if (outvalid[L1N+L2N+L3N-1:L1N+L2N] == 16'b1111111111111111) begin
							layer4in <= {layer3Out,16'd0}; //append the bias 3
							enableN[L1N+L2N+L3N-1:L1N+L2N] <= 16'b0; // layer 3 neurons are disabled
						end else begin
							layer4in <= 0;
						end
					end
					
					L4busyL2L3MAXidle: begin
						enableN[L1N+L2N+L3N+L4N-1:L1N+L2N+L3N] <= 3'b111; // layer 3 neurons are enabled
						enableMax <= 1'b0; //disable Max (output function)
						if (outvalid[L1N+L2N+L3N+L4N-1:L1N+L2N+L3N] == 3'b111) begin
							maxin <= layer4Out;
							enableN[L1N+L2N+L3N+L4N-1:L1N+L2N+L3N] <= 3'b000; // layer 4 neurons are disabled
						end else begin
							maxin <= 0;
						end
					end
					
					
					MAXbusyL2L3L4idle: begin
						enableMax <= 1; // Max layer enabled
										// Can be added: if final valid high, register the output and hold it.
					end
					
					default: begin
						enableN[L1N+L2N+L3N+L4N-1:L1N] <= 35'b00000000000000000000000000000000000; // layer 2&3&4 neurons are disabled
						enableMax <= 0; // Max layer disabled
						layer2in <= 0;
						layer3in <= 0;
						layer4in <= 0;
						maxin <= 0;
					end
				endcase
			end
			else begin // Ganapati
				enableN[L1N+L2N+L3N+L4N-1:L1N] <= 35'b00000000000000000000000000000000000; // layer 2&3&4 neurons are disabled 
				enableMax <= 0; // Max layer disabled
				layer2in <= 0;
				layer3in <= 0;
				layer4in <= 0;
				maxin <= 0;
			end
		end
		
		default: begin
			busy <= 1'b1;
			waitingWeight <= 1'b0;
			cnt <= 0;
			enableN <= 51'b0; //disable all neurons
			startupN <= 51'b0; //do not start write mode yet 
			resetN <= 51'b1111111111111111111111111111111111111111111111111; //reset all neurons
		end
	endcase
	end	
    end


    always @(*) begin // transition logic
        if (reset) begin
            nxtState = init;
			nxtWstate = wbeg;
			nxthiddenState = L2L3L4MAXidle;
        end
        else begin
			case (state)
				init: begin
					nxtState = ramload; //move on to memory filling state
                    nxtWstate = wbeg;
				end
				
				ramload: begin			
					if (wstate == wfin) begin
						nxtState = L1idle;
                        nxtWstate = wfin;
					end 
					else if (wstate == wbeg) begin //if we are just beginning writing the weights, keep the ramload state
						nxtState = ramload;
						if (input_valid) begin // if input valid start writing to first neuron
							nxtWstate = w1;
						end else begin // if input is not ready, stay at begin state
							nxtWstate = wbeg;
						end
					end
					else begin
						nxtState = ramload;
						if (cnt < inWidth - 1) begin //continue filling first neuron
							nxtWstate = w1;
						end else if (cnt < 2*inWidth - 1) begin //continue filling second neuron
							nxtWstate = w2;
						end else if (cnt < 3*inWidth - 1) begin //continue filling third  neuron
							nxtWstate = w3;
						end else if (cnt < 4*inWidth - 1) begin // goes on until ...
							nxtWstate = w4;
						end else if (cnt < 5*inWidth - 1) begin // 
							nxtWstate = w5;
						end else if (cnt < 6*inWidth - 1) begin // 
							nxtWstate = w6;
						end else if (cnt < 7*inWidth - 1) begin // 
							nxtWstate = w7;
						end else if (cnt < 8*inWidth - 1) begin // 
							nxtWstate = w8;
						end else if (cnt < 9*inWidth - 1) begin // 
							nxtWstate = w9;
						end else if (cnt < 10*inWidth - 1) begin // 
							nxtWstate = w10;
						end else if (cnt < 11*inWidth - 1) begin // 
							nxtWstate = w11;
						end else if (cnt < 12*inWidth - 1) begin // 
							nxtWstate = w12;
						end else if (cnt < 13*inWidth - 1) begin // 
							nxtWstate = w13;
						end else if (cnt < 14*inWidth - 1) begin // first layer complete
							nxtWstate = w14;
						end else if (cnt < 15*inWidth - 1) begin
							nxtWstate = w15;
						end else if (cnt < 16*inWidth - 1) begin
							nxtWstate = w16;	
						end else if (cnt < 16*inWidth - 1 + 1*(L1N+1)) begin
							nxtWstate = w17;
						end else if (cnt < 16*inWidth - 1 + 2*(L1N+1)) begin
							nxtWstate = w18;
						end else if (cnt < 16*inWidth - 1 + 3*(L1N+1)) begin
							nxtWstate = w19;
						end else if (cnt < 16*inWidth - 1 + 4*(L1N+1)) begin
							nxtWstate = w20;
						end else if (cnt < 16*inWidth - 1 + 5*(L1N+1)) begin
							nxtWstate = w21;
						end else if (cnt < 16*inWidth - 1 + 6*(L1N+1)) begin
							nxtWstate = w22;
						end else if (cnt < 16*inWidth - 1 + 7*(L1N+1)) begin
							nxtWstate = w23;
						end else if (cnt < 16*inWidth - 1 + 8*(L1N+1)) begin
							nxtWstate = w24;
						end else if (cnt < 16*inWidth - 1 + 9*(L1N+1)) begin
							nxtWstate = w25;
						end else if (cnt < 16*inWidth - 1 + 10*(L1N+1)) begin
							nxtWstate = w26;
						end else if (cnt < 16*inWidth - 1 + 11*(L1N+1)) begin
							nxtWstate = w27;
						end else if (cnt < 16*inWidth - 1 + 12*(L1N+1)) begin
							nxtWstate = w28;
						end else if (cnt < 16*inWidth - 1 + 13*(L1N+1)) begin
							nxtWstate = w29;
						end else if (cnt < 16*inWidth - 1 + 14*(L1N+1)) begin
							nxtWstate = w30;
						end else if (cnt < 16*inWidth - 1 + 15*(L1N+1)) begin
							nxtWstate = w31;
						end else if (cnt < 16*inWidth - 1 + 16*(L1N+1)) begin
							nxtWstate = w32;
						end else if (cnt < 16*inWidth - 1 + 16*(L1N+1) + 1*(L2N+1)) begin
							nxtWstate = w33;
						end else if (cnt < 16*inWidth - 1 + 16*(L1N+1) + 2*(L2N+1)) begin
							nxtWstate = w34;
						end else if (cnt < 16*inWidth - 1 + 16*(L1N+1) + 3*(L2N+1)) begin
							nxtWstate = w35;
						end else if (cnt < 16*inWidth - 1 + 16*(L1N+1) + 4*(L2N+1)) begin
							nxtWstate = w36;
						end else if (cnt < 16*inWidth - 1 + 16*(L1N+1) + 5*(L2N+1)) begin
							nxtWstate = w37;
						end else if (cnt < 16*inWidth - 1 + 16*(L1N+1) + 6*(L2N+1)) begin
							nxtWstate = w38;
						end else if (cnt < 16*inWidth - 1 + 16*(L1N+1) + 7*(L2N+1)) begin
							nxtWstate = w39;
						end else if (cnt < 16*inWidth - 1 + 16*(L1N+1) + 8*(L2N+1)) begin
							nxtWstate = w40;
						end else if (cnt < 16*inWidth - 1 + 16*(L1N+1) + 9*(L2N+1)) begin
							nxtWstate = w41;
						end else if (cnt < 16*inWidth - 1 + 16*(L1N+1) + 10*(L2N+1)) begin
							nxtWstate = w42;                                  
						end else if (cnt < 16*inWidth - 1 + 16*(L1N+1) + 11*(L2N+1)) begin
							nxtWstate = w43;                                  
						end else if (cnt < 16*inWidth - 1 + 16*(L1N+1) + 12*(L2N+1)) begin
							nxtWstate = w44;                                  
						end else if (cnt < 16*inWidth - 1 + 16*(L1N+1) + 13*(L2N+1)) begin
							nxtWstate = w45;                                  
						end else if (cnt < 16*inWidth - 1 + 16*(L1N+1) + 14*(L2N+1)) begin
							nxtWstate = w46;                                  
						end else if (cnt < 16*inWidth - 1 + 16*(L1N+1) + 15*(L2N+1)) begin
							nxtWstate = w47;                                  
						end else if (cnt < 16*inWidth - 1 + 16*(L1N+1) + 16*(L2N+1)) begin
							nxtWstate = w48;                                  
						end else if (cnt < 16*inWidth - 1 + 16*(L1N+1) + 16*(L2N+1) + 1*(L3N+1)) begin
							nxtWstate = w49;                                  
						end else if (cnt < 16*inWidth - 1 + 16*(L1N+1) + 16*(L2N+1) + 2*(L3N+1)) begin
							nxtWstate = w50;
						end else if (cnt < 16*inWidth - 1 + 16*(L1N+1) + 16*(L2N+1) + 3*(L3N+1)) begin
							nxtWstate = w51;
						end else begin // neurons are done, go to writing finished state
							nxtWstate = wfin;
						end
					end
				end
				
				L1idle: begin
					if (input_valid) begin // if new input arrives when L1 is idle, set next state to start operation. Input is registered in the above always block!
						nxtState = L1busy;
					    nxtWstate = wfin;
					end else begin
						nxtState = L1idle;
					    nxtWstate = wfin;
					end
				end
				
				L1busy: begin
					if (outvalid[L1N-1:0] == 16'b11111111111111) begin
						nxtState = L1idle; // after output is ready, set next state to idle and wait for new input there.
					    nxtWstate = wfin;
					end else begin
						nxtState = L1busy;
					    nxtWstate = wfin;
					end
				end
				
				default: begin
					nxtState = init;
					nxtWstate = wbeg;
				end
			endcase
			
			case(hiddenState)
			
				L2L3L4MAXidle: begin
					if (outvalid[L1N-1:0] == 16'b11111111111111) begin // if L1 output is valid, set next state to Layer 2 operation
						nxthiddenState = L2busyL3L4MAXidle;
					end else begin
						nxthiddenState = L2L3L4MAXidle;
					end
				end
				
				L2busyL3L4MAXidle: begin
					if (outvalid[L1N+L2N-1:L1N] == 16'b1111111111111111) begin
						nxthiddenState = L3busyL2L4MAXidle; // if L2 output is valid, set next state to Layer 3 operation
					end else begin
						nxthiddenState = L2busyL3L4MAXidle;
					end
				end
				
				L3busyL2L4MAXidle: begin
					if (outvalid[L1N+L2N+L3N-1:L1N+L2N] == 16'b1111111111111111) begin
						nxthiddenState = L4busyL2L3MAXidle; // if L3 output is valid, set next state to Layer 4 operation
					end
					else begin
						nxthiddenState = L3busyL2L4MAXidle;
					end
				end
				
				L4busyL2L3MAXidle: begin
					if (outvalid[L1N+L2N+L3N+L4N-1:L1N+L2N+L3N] == 3'b111) begin
						nxthiddenState = MAXbusyL2L3L4idle; // if L4 output is valid, set next state to Max operation
					end
					else begin
						nxthiddenState = L4busyL2L3MAXidle;
					end
				end
				
				MAXbusyL2L3L4idle: begin
					if (finalvalid) begin
						nxthiddenState = L2L3L4MAXidle; // if Max output is valid, set next state idle
						//enableMax = 1'b0;
					end
					else begin
						nxthiddenState = MAXbusyL2L3L4idle;
					end
				end
				
				default: begin
					nxthiddenState = L2L3L4MAXidle;
				end	
			endcase
		end
	end	
		
	always @(posedge clk) begin // state change
		if (reset) begin
			state <= init;
			hardResetNeurons <=1;
		end
		else begin
			state <= nxtState;
			hardResetNeurons <=0;
		end
	end
	
	always @(posedge clk) begin // wstate change
		if (reset) begin
			wstate <= wbeg;
		end
		else begin
			wstate <= nxtWstate;
		end
	end
	
	always @(posedge clk) begin // hiddenState change
		if (reset) begin
			hiddenState <= L2L3L4MAXidle;
		end
		else begin
			hiddenState <= nxthiddenState;
		end
	end
	
	
	always @(posedge clk) begin  // forloop for each layer
	    if (enableN[0]) begin
	       for ( i = 0; i < inWidth; i = i + 1) begin
	          
		   end
		end
	end
	
	
//neuron #(inWidth,weightWidth,featureWidth,4,8,1) n1_1 (.clk(clk), .in(layer1in), .weight(weightreg), .enable(enableN[0]),  .reset(resetN[0] | hardResetNeurons),  .startup(startupN[0]),  .out(layer1Out[15:0]),    .outvalid(outvalid[0]), .tmp3());	
	
	
	
	
	
	


    
//Layer 1 Neurons (14 inputs, 16b weights, 16b features, 2^memoryDepth memory addresses, divide by 2^7 before truncating, 1st layer)

neuron #(inWidth,weightWidth,featureWidth,4,8,1) n1_1 (.clk(clk), .in(layer1in), .weight(weightreg), .enable(enableN[0]),  .reset(resetN[0] | hardResetNeurons),  .startup(startupN[0]),  .out(layer1Out[15:0]),    .outvalid(outvalid[0]), .tmp3());
neuron #(inWidth,weightWidth,featureWidth,4,8,1) n1_2 (.clk(clk), .in(layer1in), .weight(weightreg), .enable(enableN[1]),  .reset(resetN[1] | hardResetNeurons),  .startup(startupN[1]),  .out(layer1Out[31:16]),   .outvalid(outvalid[1]), .tmp3());
neuron #(inWidth,weightWidth,featureWidth,4,8,1) n1_3 (.clk(clk), .in(layer1in), .weight(weightreg), .enable(enableN[2]),  .reset(resetN[2] | hardResetNeurons),  .startup(startupN[2]),  .out(layer1Out[47:32]),   .outvalid(outvalid[2]), .tmp3());
neuron #(inWidth,weightWidth,featureWidth,4,8,1) n1_4 (.clk(clk), .in(layer1in), .weight(weightreg), .enable(enableN[3]),  .reset(resetN[3] | hardResetNeurons),  .startup(startupN[3]),  .out(layer1Out[63:48]),   .outvalid(outvalid[3]), .tmp3());
neuron #(inWidth,weightWidth,featureWidth,4,8,1) n1_5 (.clk(clk), .in(layer1in), .weight(weightreg), .enable(enableN[4]),  .reset(resetN[4] | hardResetNeurons),  .startup(startupN[4]),  .out(layer1Out[79:64]),   .outvalid(outvalid[4]), .tmp3());
neuron #(inWidth,weightWidth,featureWidth,4,8,1) n1_6 (.clk(clk), .in(layer1in), .weight(weightreg), .enable(enableN[5]),  .reset(resetN[5] | hardResetNeurons),  .startup(startupN[5]),  .out(layer1Out[95:80]),   .outvalid(outvalid[5]), .tmp3());
neuron #(inWidth,weightWidth,featureWidth,4,8,1) n1_7 (.clk(clk), .in(layer1in), .weight(weightreg), .enable(enableN[6]),  .reset(resetN[6] | hardResetNeurons),  .startup(startupN[6]),  .out(layer1Out[111:96]),  .outvalid(outvalid[6]), .tmp3());
neuron #(inWidth,weightWidth,featureWidth,4,8,1) n1_8 (.clk(clk), .in(layer1in), .weight(weightreg), .enable(enableN[7]),  .reset(resetN[7] | hardResetNeurons),  .startup(startupN[7]),  .out(layer1Out[127:112]), .outvalid(outvalid[7]), .tmp3());
neuron #(inWidth,weightWidth,featureWidth,4,8,1) n1_9 (.clk(clk), .in(layer1in), .weight(weightreg), .enable(enableN[8]),  .reset(resetN[8] | hardResetNeurons),  .startup(startupN[8]),  .out(layer1Out[143:128]), .outvalid(outvalid[8]), .tmp3());
neuron #(inWidth,weightWidth,featureWidth,4,8,1) n1_10 (.clk(clk), .in(layer1in), .weight(weightreg),.enable(enableN[9]),  .reset(resetN[9] | hardResetNeurons),  .startup(startupN[9]),  .out(layer1Out[159:144]), .outvalid(outvalid[9]), .tmp3());
neuron #(inWidth,weightWidth,featureWidth,4,8,1) n1_11 (.clk(clk), .in(layer1in), .weight(weightreg),.enable(enableN[10]), .reset(resetN[10] | hardResetNeurons), .startup(startupN[10]), .out(layer1Out[175:160]), .outvalid(outvalid[10]), .tmp3());
neuron #(inWidth,weightWidth,featureWidth,4,8,1) n1_12 (.clk(clk), .in(layer1in), .weight(weightreg),.enable(enableN[11]), .reset(resetN[11] | hardResetNeurons), .startup(startupN[11]), .out(layer1Out[191:176]), .outvalid(outvalid[11]), .tmp3());
neuron #(inWidth,weightWidth,featureWidth,4,8,1) n1_13 (.clk(clk), .in(layer1in), .weight(weightreg),.enable(enableN[12]), .reset(resetN[12] | hardResetNeurons), .startup(startupN[12]), .out(layer1Out[207:192]), .outvalid(outvalid[12]), .tmp3());
neuron #(inWidth,weightWidth,featureWidth,4,8,1) n1_14 (.clk(clk), .in(layer1in), .weight(weightreg),.enable(enableN[13]), .reset(resetN[13] | hardResetNeurons), .startup(startupN[13]), .out(layer1Out[223:208]), .outvalid(outvalid[13]), .tmp3());
neuron #(inWidth,weightWidth,featureWidth,4,8,1) n1_15 (.clk(clk), .in(layer1in), .weight(weightreg),.enable(enableN[14]), .reset(resetN[14] | hardResetNeurons), .startup(startupN[14]), .out(layer1Out[239:224]), .outvalid(outvalid[14]), .tmp3());
neuron #(inWidth,weightWidth,featureWidth,4,8,1) n1_16 (.clk(clk), .in(layer1in), .weight(weightreg),.enable(enableN[15]), .reset(resetN[15] | hardResetNeurons), .startup(startupN[15]), .out(layer1Out[255:240]), .outvalid(outvalid[15]), .tmp3());


//Layer 2 Neurons (16+1 inputs, 16b weights, 16b features, 2^5 memory addresses, divide by 2^4 before truncating, 2nd layer)
neuron #(L1N+1,weightWidth,featureWidth,5,12,2) n2_1  (.clk(clk), .in(layer2in), .weight(weightreg),.enable(enableN[16]), .reset(resetN[16] | hardResetNeurons), .startup(startupN[16]), .out(layer2Out[15:0])  ,  .outvalid(outvalid[16]), .tmp3());
neuron #(L1N+1,weightWidth,featureWidth,5,12,2) n2_2  (.clk(clk), .in(layer2in), .weight(weightreg),.enable(enableN[17]), .reset(resetN[17] | hardResetNeurons), .startup(startupN[17]), .out(layer2Out[31:16]) ,  .outvalid(outvalid[17]), .tmp3());
neuron #(L1N+1,weightWidth,featureWidth,5,12,2) n2_3  (.clk(clk), .in(layer2in), .weight(weightreg),.enable(enableN[18]), .reset(resetN[18] | hardResetNeurons), .startup(startupN[18]), .out(layer2Out[47:32]) ,  .outvalid(outvalid[18]), .tmp3());
neuron #(L1N+1,weightWidth,featureWidth,5,12,2) n2_4  (.clk(clk), .in(layer2in), .weight(weightreg),.enable(enableN[19]), .reset(resetN[19] | hardResetNeurons), .startup(startupN[19]), .out(layer2Out[63:48]) ,  .outvalid(outvalid[19]), .tmp3());
neuron #(L1N+1,weightWidth,featureWidth,5,12,2) n2_5  (.clk(clk), .in(layer2in), .weight(weightreg),.enable(enableN[20]), .reset(resetN[20] | hardResetNeurons), .startup(startupN[20]), .out(layer2Out[79:64]) ,  .outvalid(outvalid[20]), .tmp3());
neuron #(L1N+1,weightWidth,featureWidth,5,12,2) n2_6  (.clk(clk), .in(layer2in), .weight(weightreg),.enable(enableN[21]), .reset(resetN[21] | hardResetNeurons), .startup(startupN[21]), .out(layer2Out[95:80]) ,  .outvalid(outvalid[21]), .tmp3());
neuron #(L1N+1,weightWidth,featureWidth,5,12,2) n2_7  (.clk(clk), .in(layer2in), .weight(weightreg),.enable(enableN[22]), .reset(resetN[22] | hardResetNeurons), .startup(startupN[22]), .out(layer2Out[111:96]),  .outvalid(outvalid[22]), .tmp3());
neuron #(L1N+1,weightWidth,featureWidth,5,12,2) n2_8  (.clk(clk), .in(layer2in), .weight(weightreg),.enable(enableN[23]), .reset(resetN[23] | hardResetNeurons), .startup(startupN[23]), .out(layer2Out[127:112]), .outvalid(outvalid[23]), .tmp3());
neuron #(L1N+1,weightWidth,featureWidth,5,12,2) n2_9  (.clk(clk), .in(layer2in), .weight(weightreg),.enable(enableN[24]), .reset(resetN[24] | hardResetNeurons), .startup(startupN[24]), .out(layer2Out[143:128]), .outvalid(outvalid[24]), .tmp3());
neuron #(L1N+1,weightWidth,featureWidth,5,12,2) n2_10 (.clk(clk), .in(layer2in), .weight(weightreg),.enable(enableN[25]), .reset(resetN[25] | hardResetNeurons), .startup(startupN[25]), .out(layer2Out[159:144]), .outvalid(outvalid[25]), .tmp3());
neuron #(L1N+1,weightWidth,featureWidth,5,12,2) n2_11 (.clk(clk), .in(layer2in), .weight(weightreg),.enable(enableN[26]), .reset(resetN[26] | hardResetNeurons), .startup(startupN[26]), .out(layer2Out[175:160]), .outvalid(outvalid[26]), .tmp3());
neuron #(L1N+1,weightWidth,featureWidth,5,12,2) n2_12 (.clk(clk), .in(layer2in), .weight(weightreg),.enable(enableN[27]), .reset(resetN[27] | hardResetNeurons), .startup(startupN[27]), .out(layer2Out[191:176]), .outvalid(outvalid[27]), .tmp3());
neuron #(L1N+1,weightWidth,featureWidth,5,12,2) n2_13 (.clk(clk), .in(layer2in), .weight(weightreg),.enable(enableN[28]), .reset(resetN[28] | hardResetNeurons), .startup(startupN[28]), .out(layer2Out[207:192]), .outvalid(outvalid[28]), .tmp3());
neuron #(L1N+1,weightWidth,featureWidth,5,12,2) n2_14 (.clk(clk), .in(layer2in), .weight(weightreg),.enable(enableN[29]), .reset(resetN[29] | hardResetNeurons), .startup(startupN[29]), .out(layer2Out[223:208]), .outvalid(outvalid[29]), .tmp3());
neuron #(L1N+1,weightWidth,featureWidth,5,12,2) n2_15 (.clk(clk), .in(layer2in), .weight(weightreg),.enable(enableN[30]), .reset(resetN[30] | hardResetNeurons), .startup(startupN[30]), .out(layer2Out[239:224]), .outvalid(outvalid[30]), .tmp3());
neuron #(L1N+1,weightWidth,featureWidth,5,12,2) n2_16 (.clk(clk), .in(layer2in), .weight(weightreg),.enable(enableN[31]), .reset(resetN[31] | hardResetNeurons), .startup(startupN[31]), .out(layer2Out[255:240]), .outvalid(outvalid[31]), .tmp3());



//Layer 3 Neurons (16+1 inputs, 16b weights, 16b features, 2^5 memory addresses, divide by 2^7 before truncating, 3rd layer)
neuron #(L2N+1,weightWidth,featureWidth,5,15,3) n3_1  (.clk(clk), .in(layer3in), .weight(weightreg),.enable(enableN[32]), .reset(resetN[32] | hardResetNeurons), .startup(startupN[32]), .out(layer3Out[15:0]) ,   .outvalid(outvalid[32]), .tmp3());
neuron #(L2N+1,weightWidth,featureWidth,5,15,3) n3_2  (.clk(clk), .in(layer3in), .weight(weightreg),.enable(enableN[33]), .reset(resetN[33] | hardResetNeurons), .startup(startupN[33]), .out(layer3Out[31:16]),   .outvalid(outvalid[33]), .tmp3());
neuron #(L2N+1,weightWidth,featureWidth,5,15,3) n3_3  (.clk(clk), .in(layer3in), .weight(weightreg),.enable(enableN[34]), .reset(resetN[34] | hardResetNeurons), .startup(startupN[34]), .out(layer3Out[47:32]),   .outvalid(outvalid[34]), .tmp3());
neuron #(L2N+1,weightWidth,featureWidth,5,15,3) n3_4  (.clk(clk), .in(layer3in), .weight(weightreg),.enable(enableN[35]), .reset(resetN[35] | hardResetNeurons), .startup(startupN[35]), .out(layer3Out[63:48]),   .outvalid(outvalid[35]), .tmp3());
neuron #(L2N+1,weightWidth,featureWidth,5,15,3) n3_5  (.clk(clk), .in(layer3in), .weight(weightreg),.enable(enableN[36]), .reset(resetN[36] | hardResetNeurons), .startup(startupN[36]), .out(layer3Out[79:64]),   .outvalid(outvalid[36]), .tmp3());
neuron #(L2N+1,weightWidth,featureWidth,5,15,3) n3_6  (.clk(clk), .in(layer3in), .weight(weightreg),.enable(enableN[37]), .reset(resetN[37] | hardResetNeurons), .startup(startupN[37]), .out(layer3Out[95:80]),   .outvalid(outvalid[37]), .tmp3());
neuron #(L2N+1,weightWidth,featureWidth,5,15,3) n3_7  (.clk(clk), .in(layer3in), .weight(weightreg),.enable(enableN[38]), .reset(resetN[38] | hardResetNeurons), .startup(startupN[38]), .out(layer3Out[111:96]),  .outvalid(outvalid[38]), .tmp3());
neuron #(L2N+1,weightWidth,featureWidth,5,15,3) n3_8  (.clk(clk), .in(layer3in), .weight(weightreg),.enable(enableN[39]), .reset(resetN[39] | hardResetNeurons), .startup(startupN[39]), .out(layer3Out[127:112]), .outvalid(outvalid[39]), .tmp3());
neuron #(L2N+1,weightWidth,featureWidth,5,15,3) n3_9  (.clk(clk), .in(layer3in), .weight(weightreg),.enable(enableN[40]), .reset(resetN[40] | hardResetNeurons), .startup(startupN[40]), .out(layer3Out[143:128]), .outvalid(outvalid[40]), .tmp3());
neuron #(L2N+1,weightWidth,featureWidth,5,15,3) n3_10 (.clk(clk), .in(layer3in), .weight(weightreg),.enable(enableN[41]), .reset(resetN[41] | hardResetNeurons), .startup(startupN[41]), .out(layer3Out[159:144]), .outvalid(outvalid[41]), .tmp3());
neuron #(L2N+1,weightWidth,featureWidth,5,15,3) n3_11 (.clk(clk), .in(layer3in), .weight(weightreg),.enable(enableN[42]), .reset(resetN[42] | hardResetNeurons), .startup(startupN[42]), .out(layer3Out[175:160]), .outvalid(outvalid[42]), .tmp3());
neuron #(L2N+1,weightWidth,featureWidth,5,15,3) n3_12 (.clk(clk), .in(layer3in), .weight(weightreg),.enable(enableN[43]), .reset(resetN[43] | hardResetNeurons), .startup(startupN[43]), .out(layer3Out[191:176]), .outvalid(outvalid[43]), .tmp3());
neuron #(L2N+1,weightWidth,featureWidth,5,15,3) n3_13 (.clk(clk), .in(layer3in), .weight(weightreg),.enable(enableN[44]), .reset(resetN[44] | hardResetNeurons), .startup(startupN[44]), .out(layer3Out[207:192]), .outvalid(outvalid[44]), .tmp3());
neuron #(L2N+1,weightWidth,featureWidth,5,15,3) n3_14 (.clk(clk), .in(layer3in), .weight(weightreg),.enable(enableN[45]), .reset(resetN[45] | hardResetNeurons), .startup(startupN[45]), .out(layer3Out[223:208]), .outvalid(outvalid[45]), .tmp3());
neuron #(L2N+1,weightWidth,featureWidth,5,15,3) n3_15 (.clk(clk), .in(layer3in), .weight(weightreg),.enable(enableN[46]), .reset(resetN[46] | hardResetNeurons), .startup(startupN[46]), .out(layer3Out[239:224]), .outvalid(outvalid[46]), .tmp3());
neuron #(L2N+1,weightWidth,featureWidth,5,15,3) n3_16 (.clk(clk), .in(layer3in), .weight(weightreg),.enable(enableN[47]), .reset(resetN[47] | hardResetNeurons), .startup(startupN[47]), .out(layer3Out[255:240]), .outvalid(outvalid[47]), .tmp3());

//Layer 4 Neurons (16+1 inputs, 16b weights, 16b features, 2^5 memory addresses, divide by 2^7 before truncating, 3rd layer)
neuron #(L3N+1,weightWidth,featureWidth,5,15,4) n4_1  (.clk(clk), .in(layer4in), .weight(weightreg),.enable(enableN[48]), .reset(resetN[48] | hardResetNeurons), .startup(startupN[48]), .out(layer4Out[15:0]), .outvalid(),  .tmp3(outvalid[48]));
neuron #(L3N+1,weightWidth,featureWidth,5,15,4) n4_2  (.clk(clk), .in(layer4in), .weight(weightreg),.enable(enableN[49]), .reset(resetN[49] | hardResetNeurons), .startup(startupN[49]), .out(layer4Out[31:16]), .outvalid(), .tmp3(outvalid[49]));
neuron #(L3N+1,weightWidth,featureWidth,5,15,4) n4_3  (.clk(clk), .in(layer4in), .weight(weightreg),.enable(enableN[50]), .reset(resetN[50] | hardResetNeurons), .startup(startupN[50]), .out(layer4Out[47:32]), .outvalid(), .tmp3(outvalid[50]));

max #(featureWidth) ml(.enable(enableMax), .clk(clk), .reset(reset), .start(enableMax), .x_1(maxin[15:0]),.x_2(maxin[31:16]),.x_3(maxin[47:32]),.x_4(16'b1000000000000000),.x_5(16'b1000000000000000),.x_6(16'b1000000000000000),.x_7(16'b1000000000000000), .x_8(16'b1000000000000000) , .max(max), .maxindex(maxindex), .outvalid(finalvalid));
//max #(featureWidth) ml(.enable(enableMax), .clk(clk), .reset(reset), .start(enableMax), .x_1(16'd1),.x_2(16'd4),.x_3(16'd9),.x_4(16'b1000000000000000),.x_5(16'b1000000000000000),.x_6(16'b1000000000000000),.x_7(16'b1000000000000000), .x_8(16'b1000000000000000) , .max(max), .maxindex(maxindex), .outvalid(finalvalid));


endmodule