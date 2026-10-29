`timescale 1ns / 1ps


module top_mod(
    input clk,
    input rst_top,
    input [2:0] en,
    input wen_regbank,
    input [31:0] in,
    output [71:0] acc_code,
    output [17:0] header,
    output [53:0] header_FEC,
    output [31:0] payload
    );
    
    integer T=10;
    reg [4:0] read_addr, write_addr;
    reg [23:0] lap;
    reg [7:0] UAP_master;
    reg [7:0] UAP_slave;
    reg [1:0] UAP_con;
    reg [2:0] LT_ADDR;
    reg [3:0] type;
    reg flow;
    reg seqn;
    reg ARQN;
    reg [1:0] logic_link;
    reg [31:0] payload_reg;
    reg [31:0] acc_dina;
    reg [31:0] head_dina;
    reg en_sys_reg;
    
    //State variable
    reg state_head=0;
    reg [1:0] state_acc=2'b0;
    reg [1:0] state_payload=2'b0;
    reg [4:0] acc_addr;
    reg [4:0] head_addr;
    reg [4:0] payload_addr;
    reg [5:0] length;
    reg [5:0] count;
    reg acc_gen_comp_reg;
    reg head_gen_comp_reg; 
    reg acc_code_comp;
    reg header_code_comp;
    
    //STATES for PAYLOAD
    localparam READ  = 2'd0;
    localparam WAIT  = 2'd1;
    localparam WRITE  = 2'd2;
                         
    
    
    wire [31:0] douta;
    wire [31:0] data=(state_payload == READ)?douta:0;
    wire [31:0] reg0;wire [31:0] reg1;
    wire [31:0] reg2;wire [31:0] reg3;
    wire [31:0] reg4;wire [31:0] reg5;
    wire [31:0] reg6;wire  [31:0] reg7;
    wire done_row;
    wire en_sys=reg7[0];
    wire [5:0] row=(length + 3) >> 2;
    wire acc_gen_comp;
    wire head_gen_comp;    
    wire valid;
    wire payload_gen_comp=(count>row);
    wire payload_write = (state_payload == WRITE);
    
    wire payload_mem_access =((state_payload == READ) || (state_payload == WAIT) ||(state_payload == WRITE))&&(en_sys);
    wire [31:0] dina=(acc_gen_comp_reg==1)?acc_dina:
                     (head_gen_comp_reg==1)?head_dina:
                     (state_payload==WRITE)?payload_reg:32'b0;
                     
    wire [4:0] addr=(acc_gen_comp_reg==1)?acc_addr:
                     (head_gen_comp_reg==1)?head_addr:payload_addr;
                     
    wire payload_module_en=en_sys&(~payload_gen_comp);
    wire acc_module_en=en_sys&(~acc_code_comp);
    wire header_module_en=en_sys&(~header_code_comp);
    
    
    //Goes high after packet generation is complete
    wire packet_complete=acc_code_comp & header_code_comp & payload_gen_comp;

    always @(posedge clk)begin 
           if(rst_top) begin
                  lap<=0;
                  LT_ADDR<=0;
                  type<=0;
                  flow<=0;
                  ARQN<=0;
                  seqn<=0;
                  UAP_master<=0;
                  UAP_slave<=0;
                  UAP_con<=0;
                  state_head<=0;
                  acc_code_comp<=0;
                  header_code_comp<=0;
            end    
            else if(en_sys==1)begin 
                     en_sys_reg=en_sys; 
                     if(reg2[0]==1)lap<=reg0[23:0];
                     else if(reg2[0]==0) lap<=reg1[23:0];    
                     UAP_master <= reg0[31:24];                               
                     UAP_slave <= reg1[31:24];  
                     UAP_con<=reg2[13:12];
                     LT_ADDR<=reg2[4:2];                             
                     type<=reg2[8:5];                             
                     flow<=reg2[9];                             
                     ARQN<=reg2[10];                             
                     seqn<=reg2[11];                           
            end       
    end
    
    //FSM for writting header in MEM at ROW-3 ,ROW-4
    always @(posedge clk) begin
        if(head_gen_comp ==1) begin
            case(state_head)
                1'b0: begin  
                        head_gen_comp_reg<=head_gen_comp;
                        head_dina<=header_FEC[31:0];
                        head_addr<=5'd3;
                        state_head<=1'b1;       
                       end
                1'b1: begin  
                        head_dina<={22'b0, header_FEC[53:32]};
                        head_addr<=5'd4;                        
                        state_head<=1'b0;
                        header_code_comp <=1'b1;
                       end  
            endcase
        end
        else begin
            head_gen_comp_reg<=1'b0;
        end
     end
     
    //FSM for writting ACCESS CODE in MEM at ROW-0 ,ROW-1,ROW-2
    always @(posedge clk) begin
        if(acc_gen_comp ==1) begin
            case(state_acc)
                2'b00: begin  
                        acc_gen_comp_reg<=acc_gen_comp;                
                        acc_dina<=acc_code[31:0];
                        acc_addr<=5'd0;
                        state_acc<=2'b01;       
                       end
                2'b01: begin  
                        acc_dina<=acc_code[63:32];
                        acc_addr<=5'd1;                        
                        state_acc<=2'b10; 
                       end
                2'b10: begin  
                        acc_dina<={24'b0, acc_code[71:64]};
                        acc_addr<=5'd2;                        
                        state_acc<=2'b00; 
                        acc_code_comp<=1'b1;
                       end    
            endcase
        end
        else begin
            acc_gen_comp_reg<=1'b0;
        end
     end


    //For payload 
    always @(posedge clk) begin
        if(rst_top)begin
            logic_link<=0;
            read_addr<=5'd5;
            write_addr<=5'd15;
            state_payload<=READ;
            count<=0;
            length<=0;
        end
        else if(en_sys)begin
            payload_reg<=payload;
            logic_link<=reg3[1:0];
            length<=reg3[6:2];
            case(state_payload)
                READ:begin
                         if(!acc_gen_comp_reg && !head_gen_comp_reg)begin
                            payload_addr<=read_addr;
                            state_payload<=WAIT;                                          
                            read_addr<=read_addr+1;      
                         end         
                     end 
                WAIT:begin
                        if(valid==1) state_payload<=WRITE;
                        payload_addr<=write_addr;
                    end
                WRITE:begin
                        if(!acc_gen_comp && !head_gen_comp )begin
                            if(done_row)begin 
                                state_payload<=READ;
                                count<=count+1; 
                                write_addr<=addr+1;
                            end
                            else begin
                               payload_addr<=addr+1;
                            end
                         end   
                      end
            endcase 
        end
    end
    
    Acc_gen Acc_gen_inst(.lap(lap),.clk(clk),
                        .rst_top(rst_top),
                        .acc_code_len(reg2[1]),
                        .en_sys(acc_module_en),
                        .acc_gen_comp(acc_gen_comp),.acc_code(acc_code));
                        
    header_gen header_gen_inst(.UAP_master(UAP_master),.UAP_slave(UAP_slave)
                               ,.UAP_con(UAP_con),.LT_ADDR(LT_ADDR)
                               ,.type(type),.flow(flow)
                               ,.ARQN(ARQN),.seqn(seqn),.clk(clk),
                               .glbl_reset(rst_top),.header(header)
                               ,.en_sys(header_module_en)
                               ,.header_FEC(header_FEC)
                               ,.head_gen_comp(head_gen_comp)); 

                             
    reg_bank reg_bank_inst(.clk(clk),.wen(wen_regbank)
                           ,.in(in)
                           ,.en(en),.rst_top(rst_top)
                           ,.reg0(reg0),.reg1(reg1)
                           ,.reg2(reg2),.reg3(reg3)
                           ,.reg4(reg4),.reg5(reg5)
                           ,.reg6(reg6),.reg7(reg7));
                           
    MEM memory_inst(.clka(clk),.rsta(0),
              .ena(head_gen_comp_reg||acc_gen_comp_reg || payload_mem_access),.wea(head_gen_comp_reg||acc_gen_comp_reg || payload_write),
              .addra(addr),.dina(dina),
              .douta(douta),.rsta_busy()
     );   
     
     
     payload_gen payload_gen_inst(.clk(clk),.glbl_reset(rst_top)
                                  ,.logic_link(logic_link),.type(type),.data(douta)
                                  ,.en_sys(payload_module_en),.out(payload),.done_row(done_row),.valid(valid));         
     
           
       
endmodule
