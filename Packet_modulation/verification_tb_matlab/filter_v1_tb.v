`timescale 1ns / 1ps

// Edit these two paths to your project folder (forward slashes)
`define STIM_FILE "D:/Files/Documents/bluetooth/GFSK/Verilog_code/stim_bits.mem"
`define OUT_FILE  "D:/Files/Documents/bluetooth/GFSK/Verilog_code/rtl_out.txt"

module tb_filter_v1;

    parameter  W    = 16;
    localparam SPS  = 8;      // samples per symbol; must equal the OSR of the DUT / MATLAB
    localparam NSYM = 32;     // must equal numel(bits) in compare_rtl.m
    localparam L     = NSYM*SPS;
    localparam TOTAL = L + 8; // clocks to run

    reg clk = 0, rst = 1, data_in = 0;
    wire signed [W:0] data_out;

    filter_v1 #(.W(W)) dut (
        .clk(clk), .rst(rst), .data_in(data_in), .data_out(data_out)
    );

    // 
    always #5 clk = ~clk;

    reg sym [0:NSYM-1];
    integer e, fout;

    initial begin
        $readmemb(`STIM_FILE, sym);          // one 0/1 per line, written by MATLAB
        fout = $fopen(`OUT_FILE, "w");

        rst = 1; repeat (3) @(posedge clk);
        @(negedge clk); rst = 0;             // the next posedge is edge 0 (count == 0)

        for (e = 0; e < TOTAL; e = e + 1) begin
            // new symbol every SPS clocks, changed on the falling edge
            if ((e % SPS == 0) && (e/SPS < NSYM)) data_in = sym[e/SPS];
            @(posedge clk);
            @(negedge clk);                  // data_out now reflects edge e
            $fdisplay(fout, "%0d", data_out);
        end

        $fclose(fout);
        $display("Done: %0d output samples written", TOTAL);
        $finish;
    end

endmodule