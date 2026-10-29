`timescale 1ns / 1ps

module top_mod_tb;

reg clk;
reg rst_top;

reg [2:0] en;
reg wen_regbank;
reg [31:0] in;

wire [71:0] acc_code;
wire [17:0] header;
wire [53:0] header_FEC;
wire [31:0] payload;

integer T = 10;

initial clk = 0;
always #(T/2) clk = ~clk;

top_mod uut(
    .clk(clk),
    .rst_top(rst_top),
    .en(en),
    .wen_regbank(wen_regbank),
    .in(in),
    .acc_code(acc_code),
    .header(header),
    .header_FEC(header_FEC),
    .payload(payload)
);


task write_reg;

input [2:0] reg_sel;
input [31:0] data;

begin

    @(posedge clk);

    en = reg_sel;
    in = data;
    wen_regbank = 1;

    @(posedge clk);

    wen_regbank = 0;
    en = 0;

end

endtask

initial begin
    rst_top     = 1;
    en          = 0;
    in          = 0;
    wen_regbank = 0;
    repeat(3) @(posedge clk);
    rst_top = 0;

    // REG0
    // MASTER ADDRESS
    write_reg(3'b000,{8'h5A,24'h4A7D21});

    // REG1
    // SLAVE ADDRESS
    write_reg(3'b001,{8'hC3,24'h4A8D23});

    // REG2
    // TYPE = HV1 (0101)
    //        HV2 (0110)
    // reg2[8:5] = 0101
    write_reg(3'b010,32'b00000000000000000000000010100000);  //for HVI
//    write_reg(3'b010,32'b00000000000000000000000011000000);    //for HV2

    // REG3
    // logic_link = 00
    // length = 10 bytes
    // reg3[1:0] = 00
    // reg3[6:2] = 01010
    write_reg(3'b011,32'b00000000000000000000000000101000);

    // ENABLE SYSTEM
    write_reg(3'b111,32'h00000001);

    // RUN
    #(500*T);

    $finish;

end


// MONITOR
//always @(posedge clk) begin
//    $display("\n================================================");
//    $display("TIME = %0t",$time);

//    // TOP FSM
//    $display("TOP STATE         = %0d",uut.state_payload);
//    $display("READ ADDR         = %0d",uut.read_addr);
//    $display("WRITE ADDR        = %0d",uut.write_addr);
//    $display("ADDR              = %0d",uut.addr);
//    $display("COUNT             = %0d",uut.count);
//    $display("ROW               = %0d",uut.row);

//    // PAYLOAD GEN FSM
//    $display("PAYLOAD FSM       = %0d",
//              uut.payload_gen_inst.state);

//    // HANDSHAKES
//    $display("VALID             = %b",uut.valid);
//    $display("DONE_ROW          = %b",uut.done_row);

//    // MEMORY DATA
//    $display("DOUTA             = %h",uut.douta);
//    $display("PAYLOAD           = %h",payload);
//    $display("DINA              = %h",uut.dina);

//    // FEC ENABLES
//    $display("EN_13             = %b",uut.payload_gen_inst.en_13);
//    $display("EN_23             = %b",uut.payload_gen_inst.en_23);
//    $display("================================================");

//end

endmodule