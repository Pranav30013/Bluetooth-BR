`timescale 1ns / 1ps

module Read_BRAM #(
    parameter W=16)(
    input clk,rst,start,
    input [31:0] data_in,
    input dout_en,
    output reg [3:0] row_addr,
    output data_out,
    output done
    );
    
    // Parameters
    localparam acc_len= 72;
    localparam header_len = 54;
    localparam payload_len=240;
    localparam total_len=acc_len+header_len+payload_len;
    
    //Initiallization
    reg [31:0] shift_reg;
    reg [1:0] state;
    reg [4:0] count;
    reg [8:0] bit_count;
    wire read_en;
    
    //States
    localparam [1:0] IDLE=2'd0;
    localparam [1:0] SEND=2'd1;
    
    
    //TO read or to hold
    always@(posedge clk)begin
        if(rst)begin
            row_addr<=4'd0;
            shift_reg<=32'b0;
            state<=2'd0;
            bit_count<=9'd0;
            count<=5'd0;
        end
        else begin
            case(state)
                IDLE:begin
                           row_addr<=4'd0;
                           if(start)begin
                                shift_reg <= data_in;        
                                row_addr  <= 4'd1;            
                                count     <= 5'd0;
                                bit_count <= 9'd0;
                                state     <= SEND;
                           end
                     end
                SEND:begin
                        if (dout_en) begin        
                            //Increment bit_count when filter read         
                            bit_count <= bit_count + 9'd1;
                            //Read the BRAM 
                            if (read_en) begin           
                                shift_reg <= data_in;
                                row_addr  <= row_addr + 4'd1;
                                count     <= 5'd0;
                            end else begin
                                count     <= count + 5'd1;
                            end
                            //Go back to ideal state
                            if (bit_count == total_len - 1) begin   
                                state     <= IDLE;
                            end
                        end
          
                     end          
            endcase
        end
    end
    
    //Next row condition
    assign read_en = (count==5'd31) || (bit_count==acc_len-1) || (bit_count==header_len+acc_len-1);
    
    //Complete conditon
    assign done = (bit_count==total_len-1);
    
    //Sampling at OSR rate
    assign data_out=shift_reg[count];
    
    
endmodule
