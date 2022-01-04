
`include "defines.v"

module EX_MEM(
	// input
	input wire clk,
	input wire rst,
	input wire wrn_i,
	input wire[`RegAddrBus] wrAddr_i,
	input wire[`RegDataBus] result_i,


	input wire[5:0] stall,

	// mem
	input wire[`ALUOpBus] alu_op_i,
	input wire[`RegDataBus] mem_addr_i,
	input wire[`RegDataBus] mem_data_i,

	
	//output
	output reg wrn_o, //写回使能信号
	output reg[`RegAddrBus] wrAddr_o,
	output reg[`RegDataBus] result_o,


	//mem
	output reg[`ALUOpBus] alu_op_o,
	output reg[`RegDataBus] mem_addr_o,
	output reg[`RegDataBus] mem_data_o
);


	always@(posedge clk)
	begin
		if(rst == `ENABLE)
		begin
			wrn_o <= `DISABLE;
			wrAddr_o <= 5'b00000;
			result_o <= `ZeroWord;
			alu_op_o <= `ALU_OP_NOP;
			mem_addr_o <= `ZeroWord;
			mem_data_o <= `ZeroWord;
		end
		else
		begin
			if(stall[3] == `ENABLE && stall[4] == `DISABLE)
			begin
				wrn_o <= `DISABLE;
				wrAddr_o <= 5'b00000;
				result_o <= `ZeroWord;
				alu_op_o <= `ALU_OP_NOP;
				mem_addr_o <= `ZeroWord;
				mem_data_o <= `ZeroWord;
			end
			else if(stall[3] == `DISABLE)
			begin
				wrn_o <= wrn_i;
				wrAddr_o <= wrAddr_i;
				result_o <= result_i;
				alu_op_o <= alu_op_i;
				mem_addr_o <= mem_addr_i;
				mem_data_o <= mem_data_i;
			end
		end
	end

endmodule
