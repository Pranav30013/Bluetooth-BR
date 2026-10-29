`timescale 1ns / 1ps
/////////////////////////////////////////////////////////////////////////////////

module top_module_tb#(
    parameter W=16,
    parameter integer ph_acc_width=24
    )();
    `include "gauss_coeff.vh"
    localparam ACC_LEN = 72, HDR_LEN = 54, PAY_LEN = 240;
    localparam TOTAL   = ACC_LEN + HDR_LEN + PAY_LEN;      
       
    reg         clk = 0, rst = 1, start = 0;
    reg  [2:0]  OSR_count = 0;
    wire [NTAPS-1:0] shift_reg_filt;
    wire [31:0] shift_reg_ser;
    wire        dout_en ;                 
    wire [3:0]  row_addr;
    wire  [31:0] blk_ram_out;                                    
    wire        data_out, done;
    wire signed [W:0] filter_out;
    wire signed [ph_acc_width-1:0] phase_acc;
    wire enable;
    wire [8:0] bit_count_packet;
    wire [4:0] bit_count_row;
    wire done_2;
    wire complete;
        
    Top_module uut(
    .clk(clk),
    .rst(rst),
    .start(start),
    .done(done),
    .done_2(done_2),
    .complete_3(complete),
    .data_out(data_out));
    
    assign shift_reg_ser=uut.read_bram_module.shift_reg;
    assign dout_en=uut.dout_en;
    assign row_addr=uut.row_addr;
    assign blk_ram_out=uut.data_in;
    assign filter_out=uut.filter_out;
    assign shift_reg_filt=uut.filter_module.shift_reg;
    assign phase_acc=uut.IQ_converter_module.phase_acc;
    assign enable=uut.enable;
    assign bit_count_packet=uut.read_bram_module.bit_count;
    assign bit_count_row=uut.read_bram_module.count;
    
    integer data_out_ser_int;
    integer filter_out_int;
    integer phase_acc_int;
    reg log_start=1'b0;
    
    //log the output of serializer
    always@(negedge clk)begin
        if(log_start)begin 
            $fdisplay(data_out_ser_int,"%0b",data_out);
            $fflush(data_out_ser_int);
        end
    end
    
    //log the output of Filter
    always@(negedge clk)begin
        if(log_start)begin 
            $fdisplay(filter_out_int,"%0d",filter_out);
            $fflush(filter_out_int);
        end
    end
    
    
    //log the output of Phase_acc
    always@(negedge clk)begin
        if(log_start)begin 
            $fdisplay(phase_acc_int,"%0d",phase_acc);
            $fflush(phase_acc_int);
        end
    end
    
    always #5 clk = ~clk;
    
        initial begin
        data_out_ser_int = $fopen("D:/Files/Documents/bluetooth/GFSK/Verilog_code/serializer_out.txt","w");
        filter_out_int = $fopen("D:/Files/Documents/bluetooth/GFSK/Verilog_code/Filter_out.txt","w"); 
        phase_acc_int = $fopen("D:/Files/Documents/bluetooth/GFSK/Verilog_code/Phase_acc.txt","w")  ;     

        // reset, then a few idle clocks so row 0 is waiting on the BRAM output
        repeat (4) @(posedge clk);
        rst = 0;
        repeat (5) @(posedge clk);
 
        // one-clock start pulse
        @(negedge clk)begin 
            start <= 1;
            log_start<=1'b1;
        end
        
        @(negedge clk); start = 0;
    end
    
    //Close the log 
    always @(posedge clk)begin
        if(complete)begin
            $fclose(data_out_ser_int); 
            $fclose(filter_out_int);
            $fclose(phase_acc_int);
            $finish;
        end
    end
 
    initial begin                                           // safety stop
        #300000000;
        $display("TIMEOUT: done never went high");
        $finish;
    end

endmodule
