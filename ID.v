/*解决冒险 对输入指令进行译码*/
`include "defines.v"

module ID(
	// ------ input ------
	input wire rst,
	input wire[`InsDataBus] inst, //上一级传来的指令
	input wire[`InsAddrWidth] pc,
	input wire[`RegDataBus] reData1_in,
	input wire[`RegDataBus] reData2_in,

	//--------------handle raw ---------------------------

	input wire ex_wrn, //EX段数据的写信号
	input wire[`RegAddrBus] ex_wrAddr,
	input wire[`RegDataBus] ex_wrData,
	
	input wire mem_wrn, //MEM段数据的写信号
	input wire[`RegAddrBus] mem_wrAddr,
	input wire[`RegDataBus] mem_wrData,

	// branch
	input wire delayslotEn, //指出当前的指令是否位于延迟槽

	// next stage inst load stall
	input wire[`ALUOpBus] last_alu_op, //指令的子类型

	//-------------------------------------------

	// ------ output -------
	output reg ren1, //送给RegFiles的rs读信号
	output reg ren2,  //送给RegFiles的rt读信号
	output reg[`RegAddrBus] reData1Addr,
	output reg[`RegAddrBus] reData2Addr,
	
	output reg[`RegAddrBus] wrDataAddr,
	output reg wrn,
	//output reg[`RegDataBus] wrData,
	
	output reg[`RegDataBus] regData1_out,
	output reg[`RegDataBus] regData2_out,

	output reg[`ALUOpBus] alu_op, //运算的子类型
	output reg[`ALUSelBus] alu_sel, //运算的类型，3位的输出端口

	// output to pc
	output reg branchEN, //分支跳转信号
	output reg[`RegDataBus] branchAddr,

	output reg next_delayslotEn,//下一条进入译码阶段的指令是否处于延迟槽

	output reg[`InsDataBus] inst_o, //往下一级传的指令
	
	output wire stall_req //请求流水线暂停信号
);

	wire[5:0] op = inst[31:26];
	wire[4:0] rs = inst[25:21];
	wire[4:0] rt = inst[20:16];
	wire[4:0] rd = inst[15:11];
	wire[4:0] shamt = inst[10:6];
	wire[5:0] func = inst[5:0];
	wire[15:0] imm = inst[15:0];
	
	reg[31:0] ext_imm; // extend imm

	// varaibles for branch instructions
	wire[`RegDataBus] pc_plus_4;
	wire[`RegDataBus] imm_sll2_ext;
	assign pc_plus_4 = pc + 4;
	assign imm_sll2_ext = {{14{imm[15]}},imm,2'b00};


	// varaibles for judge load stall
	wire pre_inst_is_load;
	assign pre_inst_is_load = (last_alu_op == `ALU_OP_LW)?1'b1:1'b0;
	
	reg reg1_stall;
	reg reg2_stall;

	// control signal settings
	always@(*)
	begin
		if(rst == `ENABLE)
		begin
			alu_op <= `alu_op_nop; //8个0
			alu_sel <= `ALU_NOP;
			wrn <= `DISABLE;  //0
			ren1 <= `DISABLE;
			ren2 <= `DISABLE;
			wrDataAddr <= 5'b00000;
			reData1Addr <= 5'b00000;
			reData2Addr <= 5'b00000;
			branchEN <= `DISABLE;
			branchAddr <= `ZeroWord;
			next_delayslotEn <= `DISABLE;
			inst_o <= `ZeroWord;
		end
		else
		begin
			// initial settings
			alu_op <= `alu_op_nop; // default: inst = nop
			alu_sel <= `ALU_NOP;
			wrn <= `DISABLE; // unable to write
			wrDataAddr <= rd;
			
			ren1 <= `DISABLE;
			ren2 <= `DISABLE;
			reData1Addr <= rs;
			reData2Addr <= rt;
			ext_imm <= `ZeroWord;
			
			branchEN <= `DISABLE;
			branchAddr <= `ZeroWord;
			next_delayslotEn <= `DISABLE;
			inst_o <= inst;
			if(delayslotEn == `DISABLE)
			begin
			case(op)
			// -------------------------------------------
			`SPECIAL: 
				begin
					case(func)
					`AND: // AND: reg[rd] = reg[rs] & reg[rt]
						begin
							if(shamt == 5'b0)
							begin
								wrn <= `ENABLE;
								ren1 <= `ENABLE;
								ren2 <= `ENABLE;
								wrDataAddr <= rd;
								reData1Addr <= rs;
								reData2Addr <= rt;
								alu_op <= `ALU_OP_AND;
								alu_sel <= `ALU_SEL_LOGIC;
							end
						end
					`OR: //OR: reg[rd] = reg[rs] | reg[rt]
						begin
							if(shamt == 5'b0)
							begin
								wrn <= `ENABLE;
								ren1 <= `ENABLE;
								ren2 <= `ENABLE;
								wrDataAddr <= rd;
								reData1Addr <= rs;
								reData2Addr <= rt;
								alu_op <= `ALU_OP_OR;
								alu_sel <= `ALU_SEL_LOGIC;
							end
						end
					`XOR: //XOR: reg[rd] = reg[rs] xor reg[rt]
						begin
							if(shamt == 5'b0)
							begin
								wrn <= `ENABLE;
								ren1 <= `ENABLE;
								ren2 <= `ENABLE;
								wrDataAddr <= rd;
								reData1Addr <= rs;
								reData2Addr <= rt;
								alu_op <= `ALU_OP_XOR;
								alu_sel <= `ALU_SEL_LOGIC;
							end
						end
					// ARITHMETIC Insts
					`ADD:
						begin
							ren1 <= `ENABLE;
							ren2 <= `ENABLE;
							wrn <= `ENABLE;
							alu_op <= `ALU_OP_ADD;
							alu_sel <= `ALU_SEL_ARITH;
						end
					`SUB:
						begin
							ren1 <= `ENABLE;
							ren2 <= `ENABLE;
							wrn <= `ENABLE;
							alu_op <= `ALU_OP_SUB;
							alu_sel <= `ALU_SEL_ARITH;
						end
					default:
						begin
						end
					endcase
				end
		

			// -------------------------------------------
			`ANDI: // ANDI: reg[rt] = reg[rs] & extend(imm)
				begin
				wrn <= `ENABLE;
				alu_op <= `ALU_OP_AND;
				alu_sel <= `ALU_LOGIC;
				ren1 <= `ENABLE;
				ren2 <= `DISABLE;
				ext_imm <= {16'b0, imm};
				wrDataAddr <= rt;
				end
			`ORI: // ORI: reg[rt] = reg[rs] | extend(imm)
				begin
				wrn <= `ENABLE;
				alu_op <= `alu_op_or;
				alu_sel <= `ALU_LOGIC;
				ren1 <= `ENABLE;
				ren2 <= `DISABLE;
				ext_imm <= {16'b0, imm};
				wrDataAddr <= rt;
				end
			`XORI: // XORI: reg[rt] = reg[rs] xor extend(imm)
				begin
				wrn <= `ENABLE;
				alu_op <= `ALU_OP_XOR;
				alu_sel <= `ALU_LOGIC;
				ren1 <= `ENABLE;
				ren2 <= `DISABLE;
				ext_imm <= {16'b0, imm};
				wrDataAddr <= rt;
				end
			`ADDI:
				begin
					ren1 <= `ENABLE;
					ren2 <= `DISABLE;
					wrn <= `ENABLE;
					wrDataAddr <= rt;
					ext_imm <= {{16{imm[15]}}, imm[15:0]};
					alu_op <= `ALU_OP_ADDI;
					alu_sel <= `ALU_SEL_ARITH;
				end
			`J:
				begin
					ren1 <= `DISABLE;
					ren2 <= `DISABLE;
					wrn <= `DISABLE;
					branchEN <= `ENABLE;
					branchAddr <= {pc_plus_4[31:28],imm,2'b00};
					next_delayslotEn <= `ENABLE;
					alu_op <= `ALU_OP_J;
					alu_sel <= `ALU_SEL_BRANCH;
				end
			`BEQ:
				begin
					ren1 <= `ENABLE;
					ren2 <= `ENABLE;
					wrn <= `DISABLE;
					alu_op <= `ALU_OP_BEQ;
					alu_sel <= `ALU_SEL_BRANCH;
					if(regData1_out == regData2_out)
					begin
						branchEN <= `ENABLE;
						branchAddr <= pc_plus_4 + imm_sll2_ext;
						next_delayslotEn <= `ENABLE;
					end
				end
			`BNE:
				begin
					ren1 <= `ENABLE;
					ren2 <= `ENABLE;
					wrn <= `DISABLE;
					alu_op <= `ALU_OP_BNE;
					alu_sel <= `ALU_SEL_BRANCH;
					if(regData1_out != regData2_out)
					begin
						branchEN <= `ENABLE;
						branchAddr <= pc_plus_4 + imm_sll2_ext;
						next_delayslotEn <= `ENABLE;
					end
				end
			`LW:
				begin
					ren1 <= `ENABLE;
					ren2 <= `DISABLE;
					wrn <= `ENABLE;
					wrDataAddr <= rt;
					alu_op <= `ALU_OP_LW;
					alu_sel <= `ALU_SEL_LOADSTORE;
				end
			`SW:
				begin
					ren1 <= `ENABLE;
					ren2 <= `ENABLE;
					wrn <= `DISABLE;
					alu_op <= `ALU_OP_SW;
					alu_sel <= `ALU_SEL_LOADSTORE;
				end
			// -------------------------------------------
			default: begin
					 end
			endcase
			// -------------------------------------------
			end
		end
	end
	

	// decide the first Reg out
	always@(*)
	begin
		reg1_stall <= `DISABLE;
		if(rst == `ENABLE)
			regData1_out <= `ZeroWord;
		else if(ren1 == `ENABLE)
		begin
			if(pre_inst_is_load == `ENABLE && ex_wrAddr == reData1Addr)
				reg1_stall <= `ENABLE;
			else if(ex_wrn == `ENABLE && ex_wrAddr == reData1Addr)
				regData1_out <= ex_wrData;
			else if(mem_wrn == `ENABLE && mem_wrAddr == reData1Addr)
				regData1_out <= mem_wrData;
			else
				regData1_out <= reData1_in;
		end
		else if(ren1 == `DISABLE)
			regData1_out <= ext_imm;
		else
			regData1_out <= `ZeroWord;
	end

	//decide the second reg out
	always@(*)
	begin
		reg2_stall <= `DISABLE;
		if(rst == `ENABLE)
			regData2_out <= `ZeroWord;
		else if(ren2 == `ENABLE)
		begin
			if(pre_inst_is_load == `ENABLE && ex_wrAddr == reData2Addr)
				reg2_stall <= `ENABLE;
			else if(ex_wrn == `ENABLE && ex_wrAddr == reData2Addr)
				regData2_out <= ex_wrData;
			else if(mem_wrn == `ENABLE && mem_wrAddr == reData2Addr)
				regData2_out <= mem_wrData;
			else
				regData2_out <= reData2_in;
		end
		else if(ren2 == `DISABLE)
			regData2_out <= ext_imm;
		else
			regData2_out <= `ZeroWord;	
	end


	assign stall_req = reg1_stall | reg2_stall;

endmodule
