`timescale 1ns / 1ps


module reg_bank(
    input [31:0] in,input clk,
    input rst_top,input [2:0]en,
    output reg [31:0] reg0,output reg [31:0] reg1,
    output reg [31:0] reg2,output reg [31:0] reg3,
    output reg [31:0] reg4,output reg [31:0] reg5,
    output reg [31:0] reg6,output reg [31:0] reg7,
    output reg [31:0] cpu_rd,input wen
    );
      
    integer i;
    
    
//    reg0->{UAP_master(8),LAP_master(24)}=32bits
//    reg1->{UAP_slave(8),LAP_slave(24)}=32bits
//    reg2->{UAP_con(2),seqn(1),arqn(1),flow(1),type(4),LT_addr(3),lap_con(1)}=13 bits of 32
//    reg3->{length_payload(5),logic_link(2)}=7 bits of 32
//    reg7->{lsb=1}->start
    
    always @(posedge clk) begin
        if(rst_top==1)begin
            reg0<=32'b0;reg1<=32'b0;reg2<=32'b0;reg3<=32'b0;reg4<=32'b0;
            reg5<=32'b0;reg6<=32'b0;reg7<=32'b0;         
        end
        else begin
            case(en)
                3'b000: begin
                            cpu_rd <= reg0;
                            if(wen) reg0 <= in;
                        end
                3'b001: begin
                            cpu_rd <= reg1;
                            if(wen) reg1 <= in;
                        end
                3'b010: begin
                            cpu_rd <= reg2;
                            if(wen) reg2 <= in;
                        end
                3'b011: begin
                            cpu_rd <= reg3;
                            if(wen) reg3 <= in;
                        end
                3'b100: begin
                            cpu_rd <= reg4;
                            if(wen) reg4 <= in;
                        end 
                3'b101: begin
                            cpu_rd <= reg5;
                            if(wen) reg5 <= in;
                        end 
                3'b110: begin
                            cpu_rd <= reg6;
                            if(wen) reg6 <= in;
                        end
                3'b111: begin
                            cpu_rd <= reg7;
                            if(wen) reg7 <= in;
                        end
                default: cpu_rd <= 32'b0;
                endcase
            end
        end       
endmodule
