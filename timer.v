module timer(input clk, reset, CE, S, load, input [13:0] inputs,
                 output [7:0] seg, an,
                 output wire rled, bled);

    wire [3:0] D7, D6, D5, D4, D3, D2, D1, D0, LED0;
    wire [26:0] counter;
    wire [13:0] modified_inputs;
    wire [5:0] CEO;
    wire Y;


    assign Y = S ? Chz2 : Chz1;
    assign rled = load | reset;

    // NOTE: SECONDS
    mod10_plain m0 (clk, reset, Y, D0, CEO1);
    mod6_plain m1 (clk, reset, CEO1, D1, CEO2);
    // NOTE: MINUTES
    mod10 m2 (clk, reset, CEO2, load, inputs[3:0], D2, CEO3);
    mod6 m3 (clk, reset, CEO3, load, inputs[7:4], D3, CEO4);

    mod24 m4(clk, reset, CEO4, load, inputs[13:8], {D5, D4}, CEO[5:4]);

    bled_ctrl bled_c(clk, reset, Y, CEO4, load, {D5, D4}, bled);

    DISP7SEG ssd (clk, D0, D1, D2, D3, D4, D5, D6, D7,
                    text_mode, slow, med, fast, error,
                    seg, an);
    _1hz ONEHZ(clk, reset, CE, counter, Chz1);
    _1khz KHZ(clk, reset, CE, counter, Chz2);

endmodule


module bled_ctrl(input clk, reset, Y, CEO4, load, [5:0]loadD, output reg bled);
    reg [5:0] counter;

    always @(posedge clk, posedge reset) begin
        if (reset | CEO4) begin
            bled <= 1;
            counter <= 0;
        end
        else if (Y) begin
            counter <= counter + 1;
            if (counter > 58) begin
                counter <= 0;
                bled <= 0;
            end
        end
        else if (load) begin
            counter <= loadD;
            bled <= 0;
        end
    end
endmodule

module mod24(input clk, reset, CE, load, [5:0] iloaded, output reg [5:0]counter, output [1:0]CEO);
    wire b;
    always @ (posedge clk, posedge reset) begin
        if(reset) begin
            counter[5:4] <= 4'b0000;
            counter[3:0] <= 4'b0000;
        end
        else if (load) begin
                counter[5:4] <= (iloaded[5:4] > 1 && iloaded[3:0] > 3) ? 2: iloaded[5:4];
                counter[3:0] <= (iloaded[5:4] > 1 && iloaded[3:0] > 3) ? 3: iloaded[3:0];

        end else if (CE) begin
            counter[3:0] <= counter[3:0] + 1;

            // if 24 hours have passed, reset
            if(counter[5:4] > 1 & counter[3:0] > 2) begin
                counter[5:4] <= 4'b0000;
                counter[3:0] <= 4'b0000;
            end
            // When Least Significant Digit reaches 10, set to 0 and increment MSD
            if(counter[3:0] == 4'b1001) begin
                counter[3:0] <= 4'b0000;
                counter[5:4] <= counter[5:4] + 1;
            end

        end else begin
        end
    end
endmodule

module mod10_plain (input clk, reset, CE, output reg [3:0] counter, output CEO);
    always @(posedge clk)
    if (reset || CEO)
            counter <= 0;
     else if (CE)
        counter <= counter + 1;
  assign CEO = (counter == 9) && CE;
endmodule


module mod10 (input clk, reset, CE, load, [3:0] iloaded,  output reg [3:0] counter, output CEO);
    always @(posedge clk)
    if (reset || CEO)
            counter <= 0;
    else if (load)
            counter <= (iloaded > 8) ? 9: iloaded;
     else if (CE)
        counter <= counter + 1;
    assign CEO = (counter == 9) && CE;
endmodule


module mod6 (input clk, reset, CE, load, [3:0] iloaded, output reg [3:0] counter, output CEO);
    always @(posedge clk)
    if (reset || CEO)
            counter <= 0;
    else if (load)
            counter <= (iloaded > 4) ? 5: iloaded;
     else if (CE)
        counter <=  counter + 1;
  assign CEO = (counter > 4) && CE;
endmodule

module mod6_plain (input clk, reset, CE, output reg [3:0] counter, output CEO);
    always @(posedge clk)
    if (reset || CEO)
            counter <= 0;
     else if (CE)
        counter <= counter + 1;
  assign CEO = (counter == 5) && CE;
endmodule


module _1hz (input clk, reset, CE, output reg [26:0] counter, output CEO);
    always @(posedge clk)
    if (reset || CEO)
        counter <= 0;
    else if (CE)
        counter <= counter + 1;
    assign CEO = (counter == 99999999) && CE;
endmodule

module _10hz (input clk, reset, CE, output reg [26:0] counter, output CEO);
    always @(posedge clk)
    if (reset || CEO)
        counter <= 0;
    else if (CE)
        counter <= counter + 1;
    assign CEO = (counter == 9999999) && CE;
endmodule

module _1khz (input clk, reset, CE, output reg [26:0] counter, output CEO);
    always @(posedge clk)
    if (reset || CEO)
        counter <= 0;
    else if (CE)
        counter <= counter + 1;

    assign CEO = (counter == 999999) && CE;
endmodule


// Given by the instructor 
module DISP7SEG(
    input clk
	
    ,input [3:0] D0
    ,input [3:0] D1
    ,input [3:0] D2
    ,input [3:0] D3

    ,input [3:0] D4
    ,input [3:0] D5
    ,input [3:0] D6
    ,input [3:0] D7

    ,input text_mode
    ,input slow
    ,input med
    ,input fast
    ,input error

    ,output [7:0] seg
    ,output [7:0] an
    );
wire [2:0] sel;
wire [4:0] Y;
wire clk_out;

wire a0, a1, a2, a3, a4;
wire b0, b1, b2, b3, b4;
wire c0, c1, c2, c3, c4;
wire d0, d1, d2, d3, d4;
wire e0, e1, e2, e3, e4;
wire f0, f1, f2, f3, f4;
wire g0, g1, g2, g3, g4;
wire h0, h1, h2, h3, h4;
wire [7:0] seg_number;

assign a4 = 0;
assign b4 = 0;
assign c4 = 0;
assign d4 = 0;
assign e4 = 0;
assign f4 = 0;
assign g4 = 0;
assign h4 = 0;

assign {a3, a2, a1, a0} = D0;
assign {b3, b2, b1, b0} = D1;
assign {c3, c2, c1, c0} = D2;
assign {d3, d2, d1, d0} = D3;
assign {e3, e2, e1, e0} = D4;
assign {f3, f2, f1, f0} = D5;
assign {g3, g2, g1, g0} = D6;
assign {h3, h2, h1, h0} = D7;


assign seg = text_mode & error ? ( sel == 3'b000 ? 8'b11111111 : sel == 3'b001 ? 8'b00101111 : sel == 3'b010 ? 8'b10101111 : 8'b10000110 ):
	     text_mode & fast  ? ( sel == 3'b000 ? 8'b10000111 : sel == 3'b001 ? 8'b10010010 : sel == 3'b010 ? 8'b10001000 : 8'b10001110 ):
             text_mode & med   ? ( sel == 3'b000 ? 8'b10100001 : sel == 3'b001 ? 8'b10100011 : sel == 3'b010 ? 8'b10100011 : 8'b10010000 ):
             text_mode & slow  ? ( sel == 3'b000 ? 8'b11111111 : sel == 3'b001 ? 8'b01000000 : sel == 3'b010 ? 8'b11000111 : 8'b10010010 ):
             seg_number;

bcd7seg bcd7seg (.Y(Y), .disp(seg_number));

slowclock slowclock (.clk_in(clk), .clk_out(clk_out));

my_counter my_counter (.clk(clk_out), .Q(sel));

mux8to1 mux8to1 (.A({a4, a3, a2, a1, a0}), .B({b4, b3, b2, b1, b0}), .C({c4, c3, c2, c1, c0}), .D({d4, d3, d2, d1, d0}),
				 .E({e4, e3, e2, e1, e0}), .F({f4, f3, f2, f1, f0}), .G({g4, g3, g2, g1, g0}), .H({h4, h3, h2, h1, h0}), .sel(sel), .Y(Y));

decoder3to8 decoder3to8 ( .en(sel), .an(an));

endmodule
////////////////////////////////////
module bcd7seg(input[4:0] Y, output reg[7:0] disp);
	always@(Y)	begin
		case(Y[3:0])
			00:       disp={!Y[4], 7'b1000000};
			01:       disp={!Y[4], 7'b1111001};
			02:       disp={!Y[4], 7'b0100100};
			03:       disp={!Y[4], 7'b0110000};
			04:       disp={!Y[4], 7'b0011001};
			05:       disp={!Y[4], 7'b0010010};
			06:       disp={!Y[4], 7'b0000010};
			07:       disp={!Y[4], 7'b1111000};
			08:       disp={!Y[4], 7'b0000000};
			09:       disp={!Y[4], 7'b0010000};
			/*10:       disp={!Y[4], 7'b0001000};
			11:       disp={!Y[4], 7'b0000011};
			12:       disp={!Y[4], 7'b1000110};
			13:       disp={!Y[4], 7'b0100001};
			14:       disp={!Y[4], 7'b0000110};
			default:  disp={!Y[4], 7'b0001110};*/
			default: disp={!Y[4], 7'b1000000};
		endcase
	end
endmodule
////////////////////////////////////
module slowclock (clk_in, clk_out);
input clk_in; output clk_out;
reg clk_out;
reg [25 : 0] period_count;

always @ (posedge clk_in)
	if (period_count != 2500 - 1)
	begin
		period_count <= period_count + 1;
		clk_out <= 0;
	end
	else
	begin
		period_count <= 0;
		clk_out <= 1;
	end
endmodule
////////////////////////////////////
module my_counter( clk, Q );
input clk;
output [2:0] Q;
reg [2:0] temp;

always @(posedge clk)
begin
	temp <= temp + 1;
end

assign Q = temp;

endmodule
////////////////////////////////////
module mux8to1( input [4:0] A, B, C, D, E, F, G, H, input [2:0] sel, output reg [4:0] Y);
// assign Y = (sel==0)?A : (sel==1)?B : (sel==2)?C : (sel==3)?D : (sel==4)?E : (sel==5)?F : (sel==6)?G : H;
always @* begin
	case(sel)
		3'd0: Y = A;
		3'd1: Y = B;
		3'd2: Y = C;
		3'd3: Y = D;
		3'd4: Y = E;
		3'd5: Y = F;
		3'd6: Y = G;
		3'd7: Y = H;
		default: Y = 5'd0;
	endcase
end
endmodule
////////////////////////////////////
module decoder3to8 (input [2:0] en, output reg [7:0] an);
always@(en)
begin
	case (en)
		0: an=8'b11111110;
		1: an=8'b11111101;
		2: an=8'b11111011;
		3: an=8'b11110111;
		4: an=8'b11101111;
		5: an=8'b11011111;
		6: an=8'b10111111;
		7: an=8'b01111111;
	endcase
end
endmodule
////////////////////////////////////
