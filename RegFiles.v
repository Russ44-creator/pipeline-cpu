/*
用在ID段的数据读取和WB段的数据写回
*/
`include "defines.v"

module RegFiles(
	// INPUT
	input wire rst,
	input wire clk,

	input wire wrn, //控制写回的使能信号
	input wire[`RegAddrBus] wrDataAddr, //WB段要写回的数据地址
	input wire[`RegDataBus] wrData, //WB段需要写回的数据

	input wire ren1, //控制读rs寄存器的使能信号
	input wire[`RegAddrBus] reData1Addr, //译码时需要读取的rs寄存器地址
	
	input wire ren2, //控制读rt寄存器的使能信号
	input wire[`RegAddrBus] reData2Addr, //rt寄存器地址

	// OUTPUT
	output reg[`RegDataBus] reData1, //读取的rs寄存器的数据
	output reg[`RegDataBus] reData2 //读取的rt寄存器的数据
);


	// define all registers
	reg[`RegDataBus] regFiles[0:`RegFilesNum-1];
	
	integer i;
	// init all registers to be zero
	initial
	begin
		for(i = 0; i < `RegFilesNum; i = i + 1)
			regFiles[i] = `ZeroWord;
	end
	
	
	// write operation
	always@(posedge clk)
	begin
		if(rst == `RstDisable && wrn == `WriteEnable && wrDataAddr !=  `RegFilesNumLog2'b0)
		begin
			regFiles[wrDataAddr] <= wrData;
		end	
	end


	// read operation1
	always@(*)
	begin
		if(rst == `ENABLE)
			reData1 <= `ZeroWord;
		else if(wrn == `ENABLE && wrDataAddr == reData1Addr && ren1 == `ENABLE)
			reData1 <= wrData;
		else if(ren1 == `ENABLE)
			reData1 <= regFiles[reData1Addr];
		else
			reData1 <= `ZeroWord;
	end
	
	// read operation2
	always@(*)
	begin
		if(rst == `ENABLE)
			reData2 <= `ZeroWord;
		else if(wrn == `ENABLE && wrDataAddr == reData2Addr && ren2 == `ENABLE)
			reData2 <= wrData;
		else if(ren2 == `ENABLE)
			reData2 <= regFiles[reData2Addr];
		else
			reData2 <= `ZeroWord;
	end
endmodule
