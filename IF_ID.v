
`include "defines.v"

module IF_ID(
	// INPUT
	input wire rst, //对部件进行复位操作
	input wire clk,
	input wire[`InsAddrWidth] if_pc, //来自insMem部件的pc信号
	input wire[`InsWidth] if_ins, //来自insMen部件的指令代码信号
	input wire[5:0] stall, //暂停流水线控制信号

	//OUTPUT
	output reg[`InsAddrWidth] id_pc, //传给ID段的pc信号
	output reg[`InsWidth] id_ins //传给ID段的指令代码
);

	always@(posedge clk)
	begin
		if(rst == `RstEnable)
		begin
			id_pc <= `ZeroWord;
			id_ins <= `ZeroWord;
		end
		else
		begin
			if(stall[1] == `ENABLE && stall[2] == `DISABLE)//LW互锁
			begin
				id_pc <= `ZeroWord;
				id_ins <= `ZeroWord;
			end
			else if(stall[1] == `DISABLE)
			begin
				id_pc <= if_pc;
				id_ins <= if_ins;
			end
		end
	end

endmodule
