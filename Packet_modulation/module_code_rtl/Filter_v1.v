`timescale 1ns / 1ps

module filter_v1 #(
    parameter W=16)(
    input clk,rst,data_in,dout_en,start,
    output reg signed [W:0] data_out
    );
    
    `include "gauss_coeff.vh"
    
    reg [NTAPS-1:0] shift_reg;
    reg signed [W:0] acc;  
    reg [counter_size-1:0] count;
    reg hold_bit;
    integer i;
    
    always @(posedge clk)begin
        if(rst)begin
            data_out<= {W{1'b0}};
            shift_reg<= {NTAPS{1'b0}};
            hold_bit<=1'b0;
        end
        else begin
        
            //To sample at OSR rate
            if(dout_en||start)begin
               hold_bit<=data_in;
            end

            //shift the Shift_reg
            shift_reg<={shift_reg[NTAPS-2:0],data_in};
            
            //initialize the accumulator
            acc={W{1'b0}};
            
            //calculate accumulator
            for(i=0;i<=NTAPS-1;i=i+1)begin
                if (shift_reg[i])
                    acc = acc + $signed({1'b0, coeff[i]});
                else
                    acc = acc - $signed({1'b0, coeff[i]});
            end
            
            data_out<=acc;
        end
    end
  
    
    
    
    
endmodule

