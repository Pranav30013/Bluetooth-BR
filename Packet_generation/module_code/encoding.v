`timescale 1ns / 1ps


module encoding(
    input [29:0] data_en,
    input clk,
    input  rst_top,
    input en_sys,
    output reg [33:0] parity,
    output  read
    );
    
    wire [63:0]data_en_app={data_en,34'b0};
    reg [7:0] count=7'b0000000;
    wire [7:0] rcount=63-count;
    
    wire in=data_en_app[rcount];
    
    // g(D)= 260534236651(in octal)
    wire fb=parity[33];
    
    assign read=(64<=count && count<67)?1:0;
    always @(posedge clk)begin
        if(rst_top==1'b1 )begin
                parity<=34'h000000000;
                count<=7'b0000000;               
        end
        else if(en_sys==1 )begin
            if(0<=count && count<64) begin
                parity<={parity[32],
                           parity[31]^fb,parity[30]^fb,parity[29],
                           parity[28],parity[27],parity[26],
                           parity[25]^fb,parity[24],parity[23]^fb,
                           parity[22],parity[21]^fb,parity[20]^fb,
                           parity[19]^fb,parity[18],parity[17],
                           parity[16],parity[15]^fb,parity[14],
                           parity[13],parity[12]^fb,parity[11]^fb,
                           parity[10]^fb,parity[9]^fb,parity[8],
                           parity[7]^fb,parity[6]^fb,parity[5],
                           parity[4]^fb,parity[3],parity[2]^fb,
                           parity[1],parity[0],fb^in};             
                    count<=count+1;
            end
            else if(64<=count && count<=67)begin
                count<=count+1;             
            end
        end
    end
    
endmodule
