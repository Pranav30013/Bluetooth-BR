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
    wire [NTAPS-1:0] shift_reg;
    wire        dout_en ;                 
    wire [3:0]  row_addr;
    wire  [31:0] data_in;                                    
    wire        data_out, done;
    wire signed [W:0] filter_out;
    wire signed [ph_acc_width-1:0] phase_acc;

    // BRAM model
    reg exp_bits [0:TOTAL-1] ;                          
    integer nb, errors, first_bad;
    
    Top_module uut(
    .clk(clk),
    .rst(rst),
    .start(start),
    .done(done),
    .data_out(data_out));
    
    assign dout_en=uut.dout_en;
    assign row_addr=uut.row_addr;
    assign data_in=uut.data_in;
    assign filter_out=uut.filter_out;
    assign shift_reg=uut.filter_module.shift_reg;
    assign phase_acc=uut.IQ_converter_module.phase_acc;
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
        errors = 0; nb = 0; first_bad = -1; 
        $readmemb("expected_bits.mem",  exp_bits);     // one expected bit per line
 
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

//        Checking for error
        // check data_out on every tick edge (what the filter would sample) until done
        while (!done) begin
            @(posedge clk);
            if (dout_en) begin
                if (nb < TOTAL && data_out !== exp_bits[nb]) begin
                    if (first_bad < 0) first_bad = nb;
                    errors = errors + 1;
                end
                nb = nb + 1;
            end
        end
         
        $display("bits sent = %0d (expected %0d)", nb, TOTAL);
        if (nb != TOTAL) errors = errors + 1;
        if (errors == 0) $display("PASS: all %0d bits correct", TOTAL);
        else             $display("FAIL: %0d errors, first wrong bit index = %0d", errors, first_bad);
        
        //Close the log 
        $fclose(data_out_ser_int); 
        $fclose(filter_out_int);
        $fclose(phase_acc_int);
//        $finish;
    end
 
    initial begin                                           // safety stop
        #300000;
        $display("TIMEOUT: done never went high");
        $finish;
    end

endmodule
