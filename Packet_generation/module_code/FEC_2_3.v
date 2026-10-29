`timescale 1ns / 1ps

module FEC_2_3(
    input clk,
    input glbl_reset,
    input en,
    input [31:0] data,

    output reg [31:0] FEC23_out,
    output reg valid,
    output reg done
);


    localparam IDLE  = 3'd0;
    localparam SHIFT = 3'd1;
    localparam OUT =   3'd2;   
    localparam OUT1  = 3'd3;
    localparam OUT2  = 3'd4;
    localparam DONE  = 3'd5;
    localparam STALL_1  = 3'd5;
    localparam STALL_2  = 3'd6;
    
    reg [63:0]lfsr_out;
    reg [4:0] lfsr_1,lfsr_2,lfsr_3,lfsr_4;
    reg [2:0] state;
    reg [3:0] count;
    reg [3:0] index;
    wire [9:0] data_1=data[9:0];
    wire [9:0] data_2=data[19:10];
    wire [9:0] data_3=data[29:20];
    wire [9:0] data_4={8'b0,data[31:30]};
    
    wire fb_1=data_1[index]^lfsr_1[4];
    wire fb_2=data_2[index]^lfsr_2[4];
    wire fb_3=data_3[index]^lfsr_3[4];
    wire fb_4=data_4[index]^lfsr_4[4];
    
    always @(posedge clk) begin
        if(glbl_reset || en==0) begin
            state <= IDLE;
            lfsr_1<=5'b0;
            lfsr_2<=5'b0;
            lfsr_3<=5'b0;
            lfsr_4<=5'b0;
            valid <= 0;
            done <= 0;
            count<=0;
            index<=0;
        end  
        else if(en) begin
            case(state)
                IDLE:begin 
                        count<=0;
                        state<=SHIFT;
                        valid <= 0;
                        done <= 0;
                        lfsr_1 <= 0;
                        lfsr_2 <= 0;
                        lfsr_3 <= 0;
                        lfsr_4 <= 0;
                        lfsr_out<= 0;
                        FEC23_out<=0;
                     end
                SHIFT:begin
                        index<=count;
                        lfsr_1<={lfsr_1[3]^fb_1,lfsr_1[2],lfsr_1[1]^fb_1,lfsr_1[0],fb_1};
                        lfsr_2<={lfsr_2[3]^fb_2,lfsr_2[2],lfsr_2[1]^fb_2,lfsr_2[0],fb_2};
                        lfsr_3<={lfsr_3[3]^fb_3,lfsr_3[2],lfsr_3[1]^fb_3,lfsr_3[0],fb_3};
                        lfsr_4<={lfsr_4[3]^fb_4,lfsr_4[2],lfsr_4[1]^fb_4,lfsr_4[0],fb_4};
                        count<=count+1;        
                        if(count==9) state<=OUT;              
                      end 
                OUT:begin
                         lfsr_out<={4'b0,lfsr_4,data_4,lfsr_3,data_3,lfsr_2,data_2,lfsr_1,data_1};
//                         FEC23_out<={data_3[1:0],lfsr_2,data_2,lfsr_1,data_1};
                         valid<=1'b0;
                         state<=OUT1;   
                     end
                OUT1:begin
                         FEC23_out<=lfsr_out[31:0];
                         valid<=1'b1;
                         state<=OUT2;   
                     end
                OUT2:begin
                         FEC23_out<=lfsr_out[61:32];
                         valid<=1'b1;
                         done<=1'b0;                         
                         state<=DONE;   
                     end
                DONE:begin
                         valid<=1'b0;
                         done<=1'b1;                         
                         state<=STALL_1;   
                     end 
                STALL_1: begin
                        valid <= 0;
                        done <= 0;
                        state <= STALL_2;
                    end    
                STALL_2: begin
                        state <= IDLE;
                    end      
                     
            endcase
        end      
    end
    
    
 endmodule