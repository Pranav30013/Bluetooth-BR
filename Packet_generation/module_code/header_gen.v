`timescale 1ns / 1ps

module header_gen(
    output [17:0] header,
    output [53:0] header_FEC,
    output head_gen_comp,
    input [2:0] LT_ADDR,
    input [3:0] type,
    input flow,
    input ARQN,
    input seqn,
    input glbl_reset,
    input clk,
    input [1:0] UAP_con,
    input [7:0] UAP_slave,
    input [7:0] UAP_master,
    input en_sys
    );
    
    wire [9:0] data={seqn,ARQN,flow,type,LT_ADDR};
    wire [7:0] HEC;
    
    HEC_gen HEC_gen_inst(.UAP_slave(UAP_slave),.UAP_master(UAP_master),
                         .UAP_con(UAP_con),.glbl_reset(glbl_reset),
                         .clk(clk),.data(data),.HEC(HEC),.gen_comp(gen_comp),
                         .en_sys(en_sys));
                         
    assign head_gen_comp=gen_comp;                     
    assign header=(gen_comp==1'b1)?{HEC,data}:18'b0;
    
//    always @(posedge clk)begin
//        head_gen_comp<=gen_comp;
//    end
    
    genvar i;

    generate
    for(i=0;i<18;i=i+1) begin
        assign header_FEC[3*i +: 3] = {3{header[i]}};
    end
endgenerate
    
endmodule
