`include "defines.v"

module ctrl(
	input wire rst,
	input wire id_stall, //请求暂停信号
	//input wire ex_stall,

	output reg[5:0] stall //暂停信号

);

	always@(*)
	begin
		if(rst == `ENABLE) //1
		begin
			stall <= 6'b000000;
		end
		else
		begin
			if(id_stall == `ENABLE)
			begin
				stall <= 6'b000111;
			end
			else
			begin
				stall <= 6'b000000;
			end
		end
	end

endmodule
