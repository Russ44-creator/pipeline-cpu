

`include "defines.v"

module insMem(insEn, insAddr, inst);
	// ----- input ------
	input wire insEn; //insEN：控制insMem的开启与关闭
	input wire[`InsAddrWidth] insAddr; //insAddr：输入pc值，32位
	
	// ----- output -----
	output reg[`InsWidth] inst; //inst：取出的指令
	
	// instruction memory init
	reg[`InsWidth] instM[0:`InsMemUnitNum]; //18
	initial
	begin
		$readmemh("instructions.data",instM);
	end

	
	always@(*)
	begin
		if(insEn == `InsDisable) begin //0
			inst <= `ZeroWord;
		end
		else begin
			inst <= instM[insAddr[`InsMemUnitNumLog2+1:2]];
		end
	end
	
endmodule
