
`include "defines.v"

module pc(
	
	// ---- input -----
	input wire rst, //对部件进行复位操作
	input wire clk, //clk：时钟信号
	
	input wire branchEN, //branchEN：是否跳转信号
	input wire[`RegDataBus] branchAddr,	//branchAddr：跳转地址，32位的输入端口
	
	input wire[5:0] stall, //stall：暂停流水线控制信号，6位的输入端口
	
	// ---- output ----
	output reg[`InsAddrWidth] pc,
	output reg insEn //insEn：使能信号，判断是否关闭指令存储器，一位的输出端口
);
	

	// judge <rst> state
	always@(posedge clk)
	begin
		if(rst == `RstEnable) 
		begin
			insEn <= `InsDisable;
			pc <= `ZeroWord;
		end
		else
		begin
			insEn <= `InsEnable;
		end
	end
	
	always@(posedge clk)
	begin
		if(insEn == `DISABLE) //0
			pc <= `ZeroWord;
		else
		begin
			if(stall[0] == `DISABLE) //若为1，关闭PC
			begin
				if(branchEN == `ENABLE)
					pc <= branchAddr;
				else
				pc <= pc + 4;
			end

		end
	
	end
endmodule
