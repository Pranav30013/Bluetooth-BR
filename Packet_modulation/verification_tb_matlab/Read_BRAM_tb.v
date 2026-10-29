`timescale 1ns / 1ps

module tb_Read_BRAM_simple#(
    parameter W=16,
    parameter OSR=8);
    
    localparam ACC_LEN = 72, HDR_LEN = 54, PAY_LEN = 240;
    localparam TOTAL   = ACC_LEN + HDR_LEN + PAY_LEN;      

    reg         clk = 0, rst = 1, start = 0;
    reg  [2:0]  OSR_count = 0;
    wire        dout_en = (OSR_count == OSR-1);                 
    wire [3:0]  row_addr;
    reg  [31:0] data_in;                                    
    wire        data_out, done;

    // BRAM model
    reg [31:0]      mem [0:15];                            
    reg exp_bits[0:TOTAL-1];                          
    integer nb, errors, first_bad;

    always #5 clk = ~clk;

    always @(posedge clk) begin
        OSR_count <= (OSR_count == OSR-1) ? 3'd0 : OSR_count + 3'd1;
        data_in  <= mem[row_addr];                          
    end

    Read_BRAM dut (
        .clk(clk), .rst(rst), .start(start),
        .data_in(data_in), .dout_en(dout_en),
        .row_addr(row_addr), .data_out(data_out), .done(done)
    );

        initial begin
        errors = 0; nb = 0; first_bad = -1;
 
        $readmemb("packet_rows", mem, 0, 12);   // 13 rows, one 32-bit row per line
        $readmemb("expected_bits",  exp_bits);     // one expected bit per line
 
        // reset, then a few idle clocks so row 0 is waiting on the BRAM output
        repeat (4) @(posedge clk);
        rst = 0;
        repeat (5) @(posedge clk);
 
        // one-clock start pulse
        @(negedge clk); start = 1;
        @(negedge clk); start = 0;
 
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
        $finish;
    end
 
    initial begin                                           // safety stop
        #300000;
        $display("TIMEOUT: done never went high");
        $finish;
    end


endmodule