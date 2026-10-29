`timescale 1ns / 1ps

module Acc_gen(
    input [23:0] lap,
    input clk,
    input rst_top,
    input en_sys,
    input acc_code_len,
//    output [67:0] acc_otr,
//    output [71:0] acc_wtr,
    output [71:0] acc_code,
    output  acc_gen_comp
    );
    
    // PRNG : 3F2A33DD69B121C1 p0 to p63 
    // PRNG : 83848D96BBCC54FC p63 to p0 
    wire [33:0] parity;
    wire [63:0] sync;
    wire [63:0] codeword;
    wire [29:0]data_en;
    wire read;
    wire [3:0] preamble;
    wire [3:0] trailer;
    reg [63:0] PRNG=64'h83848D96BBCC54FC;
    wire [29:0] Bar_seq;
    wire [29:0] randn=PRNG[63:34];
    
    
    Barker_seq_gen bar_seq_gen_inst(.lap(lap),.clk(clk),.Bar_seq(Bar_seq)); 
    
    assign data_en=Bar_seq^randn;
    
    encoding encoding_uut(.clk(clk),.rst_top(rst_top),.data_en(data_en),
                          .parity(parity),.read(read),.en_sys(en_sys));
    
    assign codeword=(read==1 && rst_top==0)?{data_en,parity}:64'b0;
    assign acc_gen_comp=read;
    assign sync=(read==1 && rst_top==0)?codeword^PRNG:64'b0;
    
    assign preamble=(sync[0]==1 && rst_top==0)?4'b1010:4'b0101;
    assign trailer=(sync[63]==1 && rst_top==0)?4'b1010:4'b0101;
    
    assign acc_code=(read==1 && rst_top==0)?
                    (acc_code_len)?{trailer,sync,preamble}:
                                   {4'b0,sync,preamble}:72'b0;
                                   
                                   
//    always @(posedge clk) begin
//        acc_gen_comp<=read;
//    end                               
    
//    assign acc_wtr=(read==1 && rst_top==0)?{trailer,sync,preamble}:72'b0;
//    assign acc_otr=(read==1 && rst_top==0)?{sync,preamble}:68'b0;
    
    
endmodule
