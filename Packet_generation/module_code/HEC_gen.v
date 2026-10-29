`timescale 1ns / 1ps


module HEC_gen(
    output reg [7:0]HEC,
    output reg gen_comp,
    input [9:0] data,
    input clk,
    input glbl_reset,
    input [7:0] UAP_slave,
    input [7:0] UAP_master,
    input [1:0] UAP_con,
    input en_sys
//    input acc_gen_comp
    );
    
    reg [3:0] count;
//    reg [3:0] index_1;
//    reg [3:0] index_2;
                  
    reg [7:0] lfsr;
//    assign HEC=(count==10)?lfsr:0;
    wire feedback=lfsr[7]^data[count-2];
    wire in=data[count];
    
    always @(posedge clk)begin
        if(glbl_reset==1 ) begin
            count=0;
            HEC=8'b0;
            gen_comp=1'b0;
            lfsr<=8'b0;
        end
        else if(en_sys==1 )begin
             if(count==0 || count==1) begin
                case(UAP_con)
                    2'b00: lfsr<=UAP_master;
                    2'b01: lfsr<=UAP_slave;
                    default: lfsr<=8'b0;
                endcase
                count<=count+1;
             end
             else if((2<=count) && (count<=11)) begin
                lfsr<={lfsr[6]^feedback,
                       lfsr[5],
                       lfsr[4]^feedback,
                       lfsr[3],
                       lfsr[2],
                       lfsr[1]^feedback,
                       lfsr[0]^feedback,
                       feedback};
                count<=count+1;
            end
            else if(12<=count & count<14) begin
                HEC<=lfsr;
                gen_comp=1'b1;
                count<=count+1;
            end 
            else if(count>=14) begin
                gen_comp=1'b0; 
            end
            //else count<=count+1;
              
        end
    end
    
endmodule
