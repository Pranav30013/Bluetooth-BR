`timescale 1ns / 1ps


module Barker_seq_gen(
    input [23:0] lap,
    input clk,
    output wire [29:0] Bar_seq
    );
    
    assign Bar_seq=(lap[23]==0)?{6'b001101,lap}:{6'b110010,lap}; 
    
    
endmodule


