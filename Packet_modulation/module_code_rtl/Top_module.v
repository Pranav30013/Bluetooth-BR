`timescale 1ns / 1ps

module Top_module#(
    parameter W=16,
    parameter OSR=8,
    parameter integer ph_acc_width=24
    )(
    input clk,rst,start,
    output done,data_out,done_2,complete_3
    );
    
    // output of the Serialiser module
    wire [3:0] row_addr;
//    wire data_out,done;
    
    // input of the Seriliser module
    wire [31:0] data_in;
    wire dout_en;
    
    // output of Filter
    wire signed [W:0] filter_out;
    
    // output of the IQ_converter
    wire signed [ph_acc_width-1:0] phase_acc;
    
    //generating dout_en at the OSR rate
    reg  [2:0]  OSR_count ;
    assign dout_en = (OSR_count == OSR-1); 
    
    //OSR_rate count
    always @(posedge clk) begin
        if(rst || start)begin
            OSR_count<=3'd0;
        end
        else begin
            OSR_count <= (OSR_count == OSR-1) ? 3'd0 : OSR_count + 3'd1;
        end
    end
    
    //generation of complete
    reg complete_1,complete_2,complete_3;
    always @(posedge clk)begin
        complete_1<=done_2;
        complete_2<=complete_1;
        complete_3<=complete_2;
    end
    
    //enable for the filter and IQ converter
    reg enable;
    
    always @(posedge clk)begin
        if(rst) enable<=1'b0;
        else enable<=enable^start^done_2;
    end
    
    
    //The serializer block
    Read_BRAM read_bram_module(
    .clk(clk),
    .start(start),
    .rst(rst),
    .row_addr(row_addr),
    .data_out(data_out),
    .done(done),
    .done_2(done_2),
    .data_in(data_in),
    .dout_en(dout_en));
    
    //The BRAM 
    blk_mem_gen_0 blk_mem_module(
    .clka(clk),
    .addra(row_addr),
    .douta(data_in),
    .ena(1'b1),
    .wea(1'b0),
    .dina(32'b0));
    
    filter_v1 filter_module(
    .clk(clk),
    .rst(rst),
    .start(start),
    .dout_en(dout_en),
    .data_in(data_out),
    .data_out(filter_out),
    .enable(enable)
    );
    
    IQ_converter IQ_converter_module(
    .clk(clk),
    .rst(rst),
    .start(start),
    .filter_output(filter_out),
    .phase_acc(phase_acc),
    .enable(enable)
    );
    
endmodule
