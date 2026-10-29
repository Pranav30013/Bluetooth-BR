`timescale 1ns / 1ps

module IQ_converter#(
    parameter integer W=16,
    parameter integer ph_acc_width=24,
    parameter  integer OSR=8,
    parameter integer filt_mult=2621,
    parameter integer filt_mult_width=12,
    parameter integer filt_shift=8
    )(
    input clk,rst,
    input signed [W:0] filter_output,
    output reg [ph_acc_width-1:0] phase_acc
    );
    
    //reg [ph_acc_width-1:0] phase_acc;
    wire signed [W+filt_mult_width:0] scaled_product ;
    wire signed [W+filt_mult_width:0] phase_inc ;
    
    assign scaled_product=filter_output*filt_mult;
    assign phase_inc=scaled_product>>>filt_shift;
    
    always@(posedge clk)begin
        if(rst)begin
            phase_acc<=24'd0;
        end
        else begin
            phase_acc<=phase_acc+phase_inc;
        end
    end
    
    
endmodule
