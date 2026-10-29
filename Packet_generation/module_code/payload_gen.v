`timescale 1ns / 1ps

module payload_gen(
    output reg [31:0] out,
    output reg done_row,
    output reg valid,
    input [31:0] data,
    input [1:0] logic_link,
    input [3:0] type,    
    input en_sys,
    input clk,
    input glbl_reset
    );
    
    reg [31:0] data_reg;
    reg en_13,en_23;
    reg [3:0] type_reg;
    reg [1:0] logic_link_reg;
    wire valid13,valid23;
    wire done13_row,done23_row;
    wire [31:0] FEC13_out;
    wire [31:0] FEC23_out;
    
    
    localparam IDLE  = 3'd0;
    localparam DECIDE  = 3'd3;
    localparam WAIT_FEC_OUTPUT  = 3'd4;
//    localparam STALL_1 = 3'd1;  
    localparam STALL_2 = 3'd2;  
    
    reg [2:0] state;

    always @(posedge clk)begin
        if(glbl_reset)begin
            en_13 <= 0;
            en_23 <= 0;
            out <= 0;
            state<=IDLE;
        end
        else if(en_sys)begin
            valid<=valid13 || valid23 || (type==4'b0111);
            done_row<=done13_row || done23_row || (type==4'b0111);
            case(state)
            IDLE: begin
                en_13<=0;
                en_23<=0;
                type_reg<=type;
                logic_link_reg<=logic_link;
                state<=STALL_2;
            end
            STALL_2:begin
                state<=DECIDE;
            end
            DECIDE: begin
                data_reg<=data;
                case(logic_link)
                    2'b00: begin
                            case(type)
                                4'b0101: begin en_13<=1; en_23<=0; end
                                4'b0110: begin en_13<=0; en_23<=1; end
                                4'b0111: begin en_13<=0; en_23<=0; out<=data; end
                                default: begin en_13<=0; en_23<=0; out<=0; end
                            endcase
//                            state <= (type==4'b0111) ? RESET : WAIT_FEC_OUTPUT;
                            state <= WAIT_FEC_OUTPUT;
                    end
                    default: begin en_13<=0; en_23<=0; state<=IDLE; end
                endcase
            end   
            WAIT_FEC_OUTPUT: begin
                if(valid13)      out <= FEC13_out;
                else if(valid23) out <= FEC23_out;
                if(done_row) state <= IDLE;
            end           
            endcase

        end
    end
    
    
    FEC_1_3 fec13_inst(.glbl_reset(glbl_reset),.clk(clk),
                       .en(en_13),.FEC13_out(FEC13_out),
                       .valid(valid13),.done(done13_row),.data(data_reg));
    FEC_2_3 fec23_inst(.glbl_reset(glbl_reset),.clk(clk),
                       .en(en_23),.FEC23_out(FEC23_out),
                       .valid(valid23),.done(done23_row),.data(data_reg));
    
    
    
    
    
endmodule

//HV1:0101
//HV2:0110  
//HV3:0111
//DV:1000