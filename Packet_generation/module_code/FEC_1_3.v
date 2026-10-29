`timescale 1ns / 1ps

module FEC_1_3(
    input clk,
    input glbl_reset,
    input en,
    input [31:0] data,

    output reg [31:0] FEC13_out,
    output reg valid,
    output reg  done
);

    integer i;
    
    reg [95:0] fec_buffer;
    reg [2:0] state;
    
    localparam IDLE  = 3'd0;
    localparam OUT1  = 3'd1;
    localparam OUT2  = 3'd2;
    localparam OUT3  = 3'd3;
    localparam DONE  = 3'd4;
    localparam STALL_1  = 3'd5;
    localparam STALL_2  = 3'd6;
    
    
    always @(posedge clk) begin   
        if(glbl_reset || en==0) begin
            state <= IDLE;
            FEC13_out <= 0;
            fec_buffer <= 0;
            valid <= 0;
            done <= 0;
        end 
            else if(en==1) begin  
                case(state)  
                    IDLE: begin
                        done <= 0;
                        valid <= 0;
                        if(en) begin
                            for(i=0; i<32; i=i+1) begin
                                fec_buffer[3*i +: 3] <= {3{data[i]}};
                            end    
                            state <= OUT1;
                        end
                    end
                    OUT1: begin
                        FEC13_out <= fec_buffer[31:0];
                        valid <= 1;
                        state <= OUT2;
                    end  
                    OUT2: begin
                        FEC13_out <= fec_buffer[63:32];
                        valid <= 1;
                        state <= OUT3;
                    end  
                    OUT3: begin
                        FEC13_out <= fec_buffer[95:64];
                        valid <= 1;
                        done <= 0;
                        state <= DONE;
                    end
                    DONE: begin
                        valid <= 0;
                        done <= 1;
                        state <= STALL_1;
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