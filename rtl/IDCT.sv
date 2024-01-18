/*
Copyright by Henry Ko and Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"


module IDCT (
   input  logic            Clock,
   input  logic            Resetn,

   output logic   		   SRAM_we_n,
   output logic   [17:0]   SRAM_address,
   input  logic signed [15:0]   SRAM_read_data,
   output logic   [15:0]   SRAM_write_data,
   
   output logic 	[8:0] 	DP0_addressA,
   output logic 			DP0_write_enA,
	output logic signed	[31:0]	DP0_write_dataA,
	input logic signed	[31:0]	DP0_read_dataA,
	output logic 	[8:0] 	DP0_addressB,
   output logic 			DP0_write_enB,
	output logic signed [31:0]	DP0_write_dataB,
	input logic signed	[31:0]	DP0_read_dataB,
	
	output logic 	[7:0] 	DP1_addressA,
   output logic 			DP1_write_enA,
	output logic signed	[31:0]	DP1_write_dataA,
	input logic signed	[31:0]	DP1_read_dataA,
	output logic 	[7:0] 	DP1_addressB,
   output logic 			DP1_write_enB,
	output logic signed	[31:0]	DP1_write_dataB,
	input logic signed	[31:0]	DP1_read_dataB,
   
	input  logic 				IDCT_enable,
	output logic				IDCT_complete

);

IDCT_state_type IDCT_state;


logic [5:0] I_index;
logic[5:0] J_index;
logic [5:0] I_index_buf;
logic[5:0] J_index_buf;
logic[5:0] DataBlock_I_index;
logic[5:0] DataBlock_J_index;
logic[5:0] DataBlock_I_index_buf;
logic[5:0] DataBlock_J_index_buf;
logic[9:0] Matrix_counter;
logic[6:0] Sprime_write_counter;
logic[6:0] S_write_counter;
logic T_tog;
logic LEADOUT_TOG;
logic First_pass_complete;
logic Y_complete;

logic [3:0] SRAM_write_counterI;
logic [3:0] SRAM_write_counterJ;

logic [17:0] SRAM_read_address_counter_I;
logic [17:0] SRAM_read_address_counter_J;

logic signed [15:0] C_buf_0;
logic signed [15:0] C_buf_1;
logic C_buff_sel;

logic signed [15:0] Sprime_T_buf0;
logic signed [15:0] Sprime_T_buf1;
logic signed [31:0] Sum_register0;
logic signed [31:0] Sum_register1;
logic signed [31:0] Sum_register2;
logic signed [31:0] Sum_register3;

logic signed [31:0] Multi0_op1, Multi0_op2, Multi1_op1, Multi1_op2;
logic signed [31:0] Multi0_out, Multi1_out;

assign Multi0_out = Multi0_op1 * Multi0_op2;

assign Multi1_out = Multi1_op1 * Multi1_op2;


always_comb begin
	
	if(T_tog == 1'b0) begin
		if(C_buff_sel == 1'b1) begin
			Multi0_op1 = Sprime_T_buf1;
			Multi0_op2 = C_buf_0;
			Multi1_op1 = Sprime_T_buf1;	
			Multi1_op2 = C_buf_1;
			
		end
		else begin
			Multi0_op1 = Sprime_T_buf0;
			Multi0_op2 = DP0_read_dataA;
			Multi1_op1 = Sprime_T_buf0;	
			Multi1_op2 = DP0_read_dataB;
		end
	end
	else begin
		if(C_buff_sel == 1'b1) begin
			Multi0_op1 = C_buf_1;
			Multi0_op2 = Sprime_T_buf0;
			Multi1_op1 = C_buf_1;	
			Multi1_op2 = Sprime_T_buf1;
			
		end
		else begin
			Multi0_op1 = DP0_read_dataA;
			Multi0_op2 = Sprime_T_buf0;
			Multi1_op1 = DP0_read_dataA;	
			Multi1_op2 = Sprime_T_buf1;
		end
	end
end


always_ff @ (posedge Clock or negedge Resetn) begin
	if (Resetn == 1'b0) begin	
		First_pass_complete <= 1'b0;
		
	end 
	else begin
		case(IDCT_state)
		
		S_IDCT_IDLE: begin
			if(IDCT_enable == 1'b1) begin 
			I_index <= 5'd0;
			J_index <= 5'd0;
			DataBlock_I_index <= 5'd0;
			DataBlock_J_index <= 5'd0;
			Matrix_counter <= 3'd0;
			Sum_register0 <= 32'd0;
			Sum_register1 <= 32'd0;
			Sum_register2 <= 32'd0;
			Sum_register3 <= 32'd0;
			SRAM_read_address_counter_I <= 7'd0;
			SRAM_read_address_counter_J <= 7'd0;
			SRAM_write_counterI <= 3'd0;
			SRAM_write_counterJ <= 3'd0;
			Sprime_write_counter <= 7'd0;
			DP0_write_enA <= 1'b0;
			DP0_addressA <= 7'd0;
			T_tog <= 1'b0;
			LEADOUT_TOG <= 1'b0;
			C_buf_0 <= 31'd0;
			C_buf_1 <= 31'd0;
			IDCT_state <= S_IDCT_LEADIN0;
			end
		end
		
		//---------------------------LEAD IN---------------------------
		//-------------------------------------------------------------
		
		S_IDCT_LEADIN0: begin 		//0		

			
			SRAM_address <= preIDCT_START_ADDRESS + (SRAM_read_address_counter_I << 8) + (SRAM_read_address_counter_I << 6);
			SRAM_read_address_counter_J <= SRAM_read_address_counter_J + 1'd1;
			SRAM_we_n <= 1'b1;
			
			//Write S' into DP after first cycle
			if(SRAM_read_address_counter_I > 0) begin
				DP0_addressA <= DP0_addressA + 1'd1;
				DP0_write_dataA <= SRAM_read_data;
			end
			IDCT_state <= S_IDCT_LEADIN_DELAY1;
		end
		
		S_IDCT_LEADIN_DELAY1: begin  		//1
			
			SRAM_address <= SRAM_address + 1'd1;
			SRAM_read_address_counter_J <= SRAM_read_address_counter_J + 1'd1;
			
			//Write S' into DP after first cycle
			if(SRAM_read_address_counter_I > 0) begin
				DP0_addressA <= DP0_addressA + 1'd1;
				if(SRAM_read_data[15] == 1'b1)
					DP0_write_dataA <= {16'hFFFF,SRAM_read_data};
				else
					DP0_write_dataA <= {16'h0000,SRAM_read_data};
			end
			IDCT_state <= S_IDCT_LEADIN_WRITE;
		end
		
		S_IDCT_LEADIN_WRITE: begin  		//2-7
			
			SRAM_address <= SRAM_address + 1'd1;
			SRAM_read_address_counter_J <= SRAM_read_address_counter_J + 1'd1;
			
			//Write to S' into DP
			if(DP0_write_enA == 1'b0) 
				DP0_write_enA <= 1'b1;
			else if(SRAM_read_address_counter_I == 1'd0 && SRAM_read_address_counter_J < 2'd3)
				DP0_write_enA <= 1'b1;
			else
				DP0_addressA <= DP0_addressA + 1'd1;
			if(SRAM_read_data[15] == 1'b1)
				DP0_write_dataA <= {16'hFFFF,SRAM_read_data};
			else
				DP0_write_dataA <= {16'h0000,SRAM_read_data};
			
			//If J counter reaches 6 we move back into first CC unless on last row of S'
			if (SRAM_read_address_counter_J == 3'd6) begin 
				SRAM_read_address_counter_J <= 3'd0;
				SRAM_read_address_counter_I <= SRAM_read_address_counter_I+1'd1;
				
				if(SRAM_read_address_counter_I == 3'd7)
					IDCT_state <= S_IDCT_LEADIN_DELAY2;
				else
					IDCT_state <= S_IDCT_LEADIN0;
					
			end
			
		end
		
		S_IDCT_LEADIN_DELAY2: begin
			DP0_addressA <= DP0_addressA + 1'd1;
			if(SRAM_read_data[15] == 1'b1)
				DP0_write_dataA <= {16'hFFFF,SRAM_read_data};
			else
				DP0_write_dataA <= {16'h0000,SRAM_read_data};
			IDCT_state <= S_IDCT_LEADIN_DELAY3;
		end
		
		S_IDCT_LEADIN_DELAY3: begin
			DP0_addressA <= DP0_addressA + 1'd1;
			if(SRAM_read_data[15] == 1'b1)
				DP0_write_dataA <= {16'hFFFF,SRAM_read_data};
			else
				DP0_write_dataA <= {16'h0000,SRAM_read_data};
			IDCT_state <= S_IDCT_LEADIN_DELAY4;
		end
		
		S_IDCT_LEADIN_DELAY4: begin
			DP0_addressA <= DP0_addressA + 1'd1;
			if(SRAM_read_data[15] == 1'b1)
				DP0_write_dataA <= {16'hFFFF,SRAM_read_data};
			else
				DP0_write_dataA <= {16'h0000,SRAM_read_data};
			IDCT_state <= S_IDCT_S_PRIME0;
		end
		
		
		//---------------------------S'C calculation and S transfer into SRAM---------------------------
		//----------------------------------------------------------------------------------------------
		
		S_IDCT_S_PRIME0: begin //0
			
			DP0_write_enA <= 1'b0;
			DP0_write_enB <= 1'b0;
			DP1_write_enA <= 1'b0;
			DP1_write_enB <= 1'b0;
			DP0_addressA <= (I_index << 3) + Matrix_counter;
			DP0_addressB <= ((I_index + 1'd1) << 3) + Matrix_counter;
			
			if(First_pass_complete == 1'b1) begin 
				DP1_write_enA <= 1'b0;
				DP1_write_enB <= 1'b0;
				DP1_addressA <= S_write_counter;
				DP1_addressB <= S_write_counter +1'd1;
				S_write_counter <= S_write_counter + 2'd2;
			end
			
			
			
			IDCT_state <= S_IDCT_S_PRIME1;
		end
		
		S_IDCT_S_PRIME1: begin //1
			DP0_addressA <= 8'd64 + J_index + (Matrix_counter << 3);
			DP0_addressB <= 8'd64 + J_index + (Matrix_counter << 3) + 1'd1;
			Matrix_counter <= Matrix_counter + 1'd1;
			IDCT_state <= S_IDCT_S_PRIME2;
		end
		
		S_IDCT_S_PRIME2: begin 	
			DP0_addressA <= (I_index << 3) + Matrix_counter;
			DP0_addressB <= ((I_index + 1'd1) << 3) + Matrix_counter;
			Sprime_T_buf0 <= DP0_read_dataA;
			Sprime_T_buf1 <= DP0_read_dataB;
			C_buff_sel <= 1'b0;	
			IDCT_state <= S_IDCT_S_PRIME_MULTI1;
		end
		
		
		S_IDCT_S_PRIME_MULTI1: begin 						//2,4,... 16
			DP0_addressA <= 8'd64 + J_index + (Matrix_counter << 3);
			DP0_addressB <= 8'd64 + J_index + (Matrix_counter << 3)+ 1'd1;
			C_buf_0 <= DP0_read_dataA;
			C_buf_1 <= DP0_read_dataB;
			DP1_write_enA <= 1'b0;
			DP1_write_enB <= 1'b0;
			C_buff_sel <= 1'b1;
			Matrix_counter <= Matrix_counter + 1'd1;
			Sum_register0 <= Sum_register0 + Multi0_out;
			Sum_register1 <= Sum_register1 + Multi1_out;
		
			if(First_pass_complete == 1'b1 && Matrix_counter > 2'd2)
				SRAM_we_n <= 1'b1;
			if(First_pass_complete == 1'b1 && J_index > 1'd0)begin
				DP1_addressA <= S_write_counter;
				DP1_addressB <= S_write_counter + 1'd1;
				S_write_counter <= S_write_counter + 2'd2;
			end
			
			IDCT_state <= S_IDCT_S_PRIME_MULTI2;
		end
		
		S_IDCT_S_PRIME_MULTI2: begin 						//3,5 ... 17
		
			
			if(Matrix_counter == 4'd8) begin
				//After first 4 cycles
				if(J_index == 3'd6) begin
				
					//After 16 cycles
					if(I_index ==  3'd6) begin
						IDCT_state <= S_IDCT_S_PRIME_DELAY1;
					end
					else begin
						DP0_addressA <= ((I_index + 2'd2)<< 3);
						DP0_addressB <= ((I_index + 2'd3) << 3);
						J_index <= 3'd0;
						I_index <= I_index + 2'd2;
						IDCT_state <= S_IDCT_S_PRIME_STORE1;
					end
				end
				//After every cycle
				else begin
					J_index <= J_index + 2'd2;
					DP0_addressA <= (I_index << 3);
					DP0_addressB <= ((I_index + 1'd1) << 3);
					IDCT_state <= S_IDCT_S_PRIME_STORE1;
				end
				J_index_buf <= J_index;
				I_index_buf <= I_index;
				C_buff_sel <= 1'b0;
				SRAM_we_n <= 1'b1;
				Matrix_counter <= 3'd0;
			end
			else begin 
				DP0_addressA <= (I_index << 3) + Matrix_counter;
				DP0_addressB <= ((I_index + 1'd1) << 3) + Matrix_counter;
				
				Sprime_T_buf0 <= DP0_read_dataA;
				Sprime_T_buf1 <= DP0_read_dataB;
				
				Sum_register2 <= Sum_register2 + Multi0_out;
				Sum_register3 <= Sum_register3 + Multi1_out;
				
				C_buff_sel <= 1'b0;

				
				if(First_pass_complete == 1'b1) begin
					if (Matrix_counter > 2'd2) 
					
						if(J_index > 1'd0)begin
							if(Matrix_counter > 2'd4)
								SRAM_we_n <= 1'b0;
						end
						else 
							SRAM_we_n <= 1'b0;
					if(Matrix_counter < 4'd8) begin
						if(Y_complete == 1'b1)
							SRAM_address <= 16'd38400 + ((DataBlock_I_index_buf <<3) << 4 ) + ((DataBlock_I_index_buf <<3) << 6) + (DataBlock_J_index_buf << 2) +SRAM_write_counterJ + (SRAM_write_counterI << 4) + (SRAM_write_counterI << 6);
						else
							SRAM_address <= ((DataBlock_I_index_buf <<3) << 5 ) + ((DataBlock_I_index_buf <<3) << 7) + (DataBlock_J_index_buf << 2) +SRAM_write_counterJ + (SRAM_write_counterI << 5) + (SRAM_write_counterI << 7);
						SRAM_write_data <= {DP1_read_dataA[7:0], DP1_read_dataB[7:0]};
					end
					if(Matrix_counter < 4'd8 && Matrix_counter > 2'd3) begin	
						if(Matrix_counter < 3'd7) begin
							DP1_addressA <= S_write_counter;
							DP1_addressB <= S_write_counter + 1'd1;
							S_write_counter <= S_write_counter + 2'd2;
						end
						if(SRAM_write_counterJ == 3'd3) begin
							SRAM_write_counterJ <= 3'd0;
							SRAM_write_counterI <= SRAM_write_counterI + 1'd1;
							if(SRAM_write_counterI == 4'd7) begin
								IDCT_state <= S_IDCT_END;
							end
						end
						else begin
							SRAM_write_counterJ <= SRAM_write_counterJ + 1'd1;
						end
					end
				end
					
				else begin
					SRAM_write_counterJ <= SRAM_write_counterJ + 1'd1;
				end

				
				IDCT_state <= S_IDCT_S_PRIME_MULTI1;
			end
		end
		
		S_IDCT_S_PRIME_STORE1: begin 						//18
			//Preping for next multi
			DP0_addressA <= 8'd64 + J_index + (Matrix_counter << 3);
			DP0_addressB <= 8'd64 + J_index + (Matrix_counter << 3)+ 1'd1;
			C_buf_0 <= DP0_read_dataA;
			C_buf_1 <= DP0_read_dataB;
			C_buff_sel <= 1'b1;
			Matrix_counter <= Matrix_counter +1'd1;
			
			//Storing SUM 1 and 2
			DP1_write_enA <= 1'b1;
			DP1_write_enB <= 1'b1;
			DP1_addressA <= (I_index_buf << 3) + J_index_buf;
			DP1_addressB <= (I_index_buf << 3) + J_index_buf + 1'd1;
			DP1_write_dataA <= (Sum_register0 + Multi0_out)	>>> 8;
			DP1_write_dataB <= (Sum_register1 + Multi1_out) >>> 8;
			IDCT_state <= S_IDCT_S_PRIME_STORE2;
		end
		
		S_IDCT_S_PRIME_STORE2: begin 						//19
			//Preping for next multi
			DP0_addressA <= (I_index << 3) + Matrix_counter;
			DP0_addressB <= ((I_index + 1'd1) << 3) + Matrix_counter;
			Sprime_T_buf0 <= DP0_read_dataA;
			Sprime_T_buf1 <= DP0_read_dataB;
			C_buff_sel <= 1'b0;
			
			//Storing SUM 3 and 4
			DP1_addressA <= (I_index_buf + 1 << 3) + J_index_buf;
			DP1_addressB <= (I_index_buf + 1 << 3) + J_index_buf + 1'd1;
			DP1_write_dataA <= (Sum_register2 + Multi0_out) >>> 8;
			DP1_write_dataB <= (Sum_register3 + Multi1_out) >>> 8;
			
			
			Sum_register0 <= 31'd0;
			Sum_register1 <= 31'd0;
			Sum_register2 <= 31'd0;
			Sum_register3 <= 31'd0;
			IDCT_state <= S_IDCT_S_PRIME_MULTI1;
			
		end
		
		S_IDCT_S_PRIME_DELAY1: begin
		
			DP1_write_enA <= 1'b1;
			DP1_write_enB <= 1'b1;
			DP1_addressA <= (I_index_buf << 3) + J_index_buf;
			DP1_addressB <= (I_index_buf << 3) + J_index_buf + 1'd1;
			DP1_write_dataA <= (Sum_register0 + Multi0_out)	>>> 8;
			DP1_write_dataB <= (Sum_register1 + Multi1_out) >>> 8;
			
			IDCT_state <= S_IDCT_S_PRIME_DELAY2;
		end
		
		S_IDCT_S_PRIME_DELAY2: begin
		
			DP1_addressA <= (I_index_buf + 1 << 3) + J_index_buf;
			DP1_addressB <= (I_index_buf + 1 << 3) + J_index_buf + 1'd1;
			DP1_write_dataA <= (Sum_register2 + Multi0_out) >>> 8;
			DP1_write_dataB <= (Sum_register3 + Multi1_out) >>> 8;
			Matrix_counter <= 3'd0;
			I_index <= 3'd0;
			J_index <= 3'd0;
			
			if(Y_complete == 1'b1) begin
				DataBlock_J_index <= DataBlock_J_index + 1'd1;
					
				if(DataBlock_J_index == 6'd19) begin
					DataBlock_J_index <= 6'd0;
					DataBlock_I_index <= DataBlock_I_index + 1'd1;
				end
					
			end
				
			else begin 
				DataBlock_J_index <= DataBlock_J_index + 1'd1;
				if(DataBlock_J_index == 6'd39) begin
					DataBlock_J_index <= 6'd0;
					DataBlock_I_index <= DataBlock_I_index + 1'd1;
					if(DataBlock_I_index == 7'd29) begin
						Y_complete <= 1'b1;
						DataBlock_I_index <= 7'd0;
					end
				end
				
			end
			SRAM_read_address_counter_I <= 4'd0;
			SRAM_read_address_counter_J <= 4'd0;
			DataBlock_I_index_buf <= DataBlock_I_index;
			DataBlock_J_index_buf <= DataBlock_J_index;
			T_tog <= 1'b1;
			IDCT_state <= S_IDCT_T0;
			
		end
		
		
		//------------------------------CtT Calculation and SRAM store S'--------------------------------------
		//----------------------------------------------------------------------------------------------
		
		
		S_IDCT_T0: begin //0
			
			DP0_write_enA <= 1'b0;
			DP0_write_enB <= 1'b0;
			DP1_write_enA <= 1'b0;
			DP1_write_enB <= 1'b0;
			DP1_addressA <= J_index + (Matrix_counter << 3);
			DP1_addressB <= J_index + (Matrix_counter << 3)+ 1'd1;

			if(SRAM_read_address_counter_I < 4'd8) begin			
				if(Y_complete == 1'b1) begin
					SRAM_address <= (preIDCT_START_ADDRESS << 1) + (SRAM_read_address_counter_I << 7) + (SRAM_read_address_counter_I << 5) + ((DataBlock_I_index << 3) << 5) + ((DataBlock_I_index << 3) << 7) + (DataBlock_J_index << 3);
				end
				else begin
					SRAM_address <= preIDCT_START_ADDRESS + SRAM_read_address_counter_J + (SRAM_read_address_counter_I << 6) + (SRAM_read_address_counter_I << 8) + ((DataBlock_I_index << 3) << 6) + ((DataBlock_I_index << 3) << 8) + (DataBlock_J_index << 3);
				end
				SRAM_read_address_counter_J <= SRAM_read_address_counter_J + 1'd1;
				if(SRAM_read_address_counter_J == 4'd7) begin
						SRAM_read_address_counter_I <= SRAM_read_address_counter_I + 1'd1;
						SRAM_read_address_counter_J <= 3'd0;
				end
			end
			IDCT_state <= S_IDCT_T1;
			
		end
		
		S_IDCT_T1: begin //1
			DP0_addressA <= 7'd64 + I_index + (Matrix_counter << 3);
			DP0_addressB <= 7'd64 + I_index + (Matrix_counter << 3)+ 1'd1;
			Matrix_counter <= Matrix_counter + 1'd1;
			
			if(SRAM_read_address_counter_I < 4'd8) begin			
				if(Y_complete == 1'b1) begin
				SRAM_address <= (preIDCT_START_ADDRESS << 1) + (SRAM_read_address_counter_I << 7) + (SRAM_read_address_counter_I << 5) + ((DataBlock_I_index << 3) << 5) + ((DataBlock_I_index << 3) << 7) + (DataBlock_J_index << 3);
				end
				else begin
				SRAM_address <= preIDCT_START_ADDRESS + SRAM_read_address_counter_J + (SRAM_read_address_counter_I << 6) + (SRAM_read_address_counter_I << 8) + ((DataBlock_I_index << 3) << 6) + ((DataBlock_I_index << 3) << 8) + (DataBlock_J_index << 3);
				end
				
				SRAM_read_address_counter_J <= SRAM_read_address_counter_J + 1'd1;
				
				if(SRAM_read_address_counter_J == 4'd7) begin
						SRAM_read_address_counter_I <= SRAM_read_address_counter_I + 1'd1;
						SRAM_read_address_counter_J <= 3'd0;
				end
			end
			IDCT_state <= S_IDCT_T2;
		end
		
		S_IDCT_T2: begin 						//2,4,... 16
			DP1_addressA <= J_index + (Matrix_counter << 3);
			DP1_addressB <= J_index + (Matrix_counter << 3)+ 1'd1;
			Sprime_T_buf0 <= DP1_read_dataA;
			Sprime_T_buf1 <= DP1_read_dataB;
			C_buff_sel <= 1'b0;
			if(SRAM_read_address_counter_I < 4'd8 ) begin
				if(Y_complete == 1'b1) begin
				SRAM_address <= (preIDCT_START_ADDRESS << 1) + (SRAM_read_address_counter_I << 7) + (SRAM_read_address_counter_I << 5) + ((DataBlock_I_index << 3) << 5) + ((DataBlock_I_index << 3) << 7) + (DataBlock_J_index << 3);
				end
				else begin
				SRAM_address <= preIDCT_START_ADDRESS + SRAM_read_address_counter_J + (SRAM_read_address_counter_I << 6) + (SRAM_read_address_counter_I << 8) + ((DataBlock_I_index << 3) << 6) + ((DataBlock_I_index << 3) << 8) + (DataBlock_J_index << 3);
				end
				
				SRAM_read_address_counter_J <= SRAM_read_address_counter_J + 1'd1;
				
				if(SRAM_read_address_counter_J == 4'd7 ) begin
						SRAM_read_address_counter_I <= SRAM_read_address_counter_I + 1'd1;
						SRAM_read_address_counter_J <= 3'd0;
				end
					
			end
			IDCT_state <= S_IDCT_T_MULTI1;
		end
		
		S_IDCT_T_MULTI1: begin 						//2,4,... 16
			DP0_addressA <= 7'd64 + I_index + (Matrix_counter << 3);
			DP0_addressB <= 7'd64 + I_index + (Matrix_counter << 3)+ 1'd1;
			C_buf_0 <= DP0_read_dataA;
			C_buf_1 <= DP0_read_dataB;
			C_buff_sel <= 1'b1;
			Matrix_counter <= Matrix_counter + 1'd1;
			Sum_register0 <= Sum_register0 + Multi0_out;
			Sum_register1 <= Sum_register1 + Multi1_out;
			
			
			if(I_index < 3'd4) begin
				if(Matrix_counter < 3'd4) begin
					if(Y_complete == 1'b1) begin
					SRAM_address <= (preIDCT_START_ADDRESS << 1) + (SRAM_read_address_counter_I << 7) + (SRAM_read_address_counter_I << 5) + ((DataBlock_I_index << 3) << 5) + ((DataBlock_I_index << 3) << 7) + (DataBlock_J_index << 3);
					end
					else begin
					SRAM_address <= preIDCT_START_ADDRESS + SRAM_read_address_counter_J + (SRAM_read_address_counter_I << 6) + (SRAM_read_address_counter_I << 8) + ((DataBlock_I_index << 3) << 6) + ((DataBlock_I_index << 3) << 8) + (DataBlock_J_index << 3);
					end
					
					SRAM_read_address_counter_J <= SRAM_read_address_counter_J + 1'd1;
					if(SRAM_read_address_counter_J == 4'd7) begin
							SRAM_read_address_counter_I <= SRAM_read_address_counter_I + 1'd1;
							SRAM_read_address_counter_J <= 3'd0;
					end
				end
				DP0_write_enA <= 1'b0;
				DP0_write_enB <= 1'b0;
				if(SRAM_read_data[15] == 1'b1)
					DP0_write_dataA <= {16'hFFFF,SRAM_read_data};
				else
					DP0_write_dataA <= {16'h0000,SRAM_read_data};
			end
			
			
			IDCT_state <= S_IDCT_T_MULTI2;
		end
		
		S_IDCT_T_MULTI2: begin 						//3,5 ... 17
		
			
			if(Matrix_counter == 4'd8) begin
				//After first 4 cycles
				if(J_index == 3'd6) begin
				
					//After 16 cycles
					if(I_index ==  3'd6) begin
						IDCT_state <= S_IDCT_T_DELAY1;
					end
					else begin
						J_index <= 3'd0;
						I_index <= I_index + 2'd2;
						IDCT_state <= S_IDCT_T_STORE1;
					end
				end
				//After every cycle
				else begin
					J_index <= J_index + 2'd2;
					IDCT_state <= S_IDCT_T_STORE1;
				end
				
				C_buff_sel <= 1'b0;
				J_index_buf <= J_index;
				I_index_buf <= I_index;
				Matrix_counter <= 3'd0;
				
				
				
				
			end
			
			else begin 
				DP1_addressA <= J_index + (Matrix_counter << 3);
				DP1_addressB <= J_index + (Matrix_counter << 3)+ 1'd1;
				
				Sprime_T_buf0 <= DP1_read_dataA;
				Sprime_T_buf1 <= DP1_read_dataB;
				
				
				
				C_buff_sel <= 1'b0;
				
				//Writing SRAM into DP
				if(I_index < 3'd4) begin
					if(Matrix_counter < 3'd4) begin
						if(Y_complete == 1'b1) begin
							SRAM_address <= (preIDCT_START_ADDRESS << 1) + (SRAM_read_address_counter_I << 7) + (SRAM_read_address_counter_I << 5) + ((DataBlock_I_index << 3) << 5) + ((DataBlock_I_index << 3) << 7) + (DataBlock_J_index << 3);
						end
						else begin
							SRAM_address <= preIDCT_START_ADDRESS + SRAM_read_address_counter_J + (SRAM_read_address_counter_I << 6) + (SRAM_read_address_counter_I << 8) + ((DataBlock_I_index << 3) << 6) + ((DataBlock_I_index << 3) << 8) + (DataBlock_J_index << 3);
						end
						
						
						SRAM_read_address_counter_J <= SRAM_read_address_counter_J + 1'd1;
						
						if(SRAM_read_address_counter_J == 4'd7) begin
							SRAM_read_address_counter_I <= SRAM_read_address_counter_I + 1'd1;
							SRAM_read_address_counter_J <= 3'd0;
						end
					end
					if(SRAM_read_address_counter_I == 4'd7 && SRAM_read_address_counter_J == 4'd7)	begin
						DP0_write_enA <= 1'b0;
						DP0_write_enB <= 1'b0;
						Sprime_write_counter <= 1'd0;
					end
					else begin
					
						if(Matrix_counter < 3'd6) begin
							DP0_write_enA <= 1'b1;
							DP0_write_enB <= 1'b1;
							DP0_write_dataB<= SRAM_read_data;
							DP0_addressA <= Sprime_write_counter;
							DP0_addressB <= Sprime_write_counter + 1'd1;
							Sprime_write_counter <= Sprime_write_counter + 2'd2;
						end
					end
				end
				IDCT_state <= S_IDCT_T_MULTI1;
			end
			
			Sum_register2 <= Sum_register2 + Multi0_out;
			Sum_register3 <= Sum_register3 + Multi1_out;
			
			
			
			
			
		end
		
		S_IDCT_T_STORE1: begin 						//18
			
			//Storing SUM 2 and 3
			DP1_write_enA <= 1'b1;
			DP1_write_enB <= 1'b1;
			DP1_addressA <= 7'd64 + (I_index_buf << 3) + J_index_buf;
			DP1_addressB <= 7'd64 + (I_index_buf << 3) + J_index_buf + 1'd1;
			C_buf_0 <= DP0_read_dataA;
			C_buf_1 <= DP0_read_dataB;
			C_buff_sel <= 1'b1;
			DP1_write_dataA <= (Sum_register0 + Multi0_out) >> 16;
			DP1_write_dataB <= (Sum_register1 + Multi1_out) >> 16;
			IDCT_state <= S_IDCT_T_STORE2;
		end
		
		S_IDCT_T_STORE2: begin 						//18
			
			//Storing SUM 2 and 3
			DP1_addressA <= 7'd64 + (I_index_buf + 1'd1 << 3) + J_index_buf;
			DP1_addressB <= 7'd64 + (I_index_buf + 1'd1 << 3) + J_index_buf + 1'd1;
			DP1_write_dataA <= (Sum_register2 + Multi0_out) >> 16;
			DP1_write_dataB <= (Sum_register3 + Multi1_out) >> 16;
			Sum_register0 <= 31'd0;
			Sum_register1 <= 31'd0;
			Sum_register2 <= 31'd0;
			Sum_register3 <= 31'd0;
			IDCT_state <= S_IDCT_T0;
		end
		
		
		S_IDCT_T_DELAY1: begin
		
			DP1_write_enA <= 1'b1;
			DP1_write_enB <= 1'b1;
			DP1_addressA <= 7'd64 + (I_index_buf << 3) + J_index_buf;
			DP1_addressB <= 7'd64 + (I_index_buf << 3) + J_index_buf + 1'd1;
			C_buf_0 <= DP0_read_dataA;
			C_buf_1 <= DP0_read_dataB;
			C_buff_sel <= 1'b1;
			DP1_write_dataA <= (Sum_register0 + Multi0_out) >>> 16;
			DP1_write_dataB <= (Sum_register1 + Multi1_out) >>> 16;
			IDCT_state <= S_IDCT_T_DELAY2;
		end
		
		
		S_IDCT_T_DELAY2: begin
		
			DP1_addressA <= 7'd64 + (I_index_buf + 1'd1 << 3) + J_index_buf;
			DP1_addressB <= 7'd64 + (I_index_buf + 1'd1 << 3) + J_index_buf + 1'd1;
			DP1_write_dataA <= (Sum_register2 + Multi0_out) >>> 16;
			DP1_write_dataB <= (Sum_register3 + Multi1_out) >>> 16;
			Sum_register0 <= 31'd0;
			Sum_register1 <= 31'd0;
			Sum_register2 <= 31'd0;
			Sum_register3 <= 31'd0;
			
			SRAM_write_counterI <= 1'd0;
			SRAM_write_counterJ <= 1'd0;
			if(First_pass_complete == 1'b0)
				First_pass_complete <= 1'b1;
			if(DataBlock_I_index_buf == 7'd59 && DataBlock_J_index_buf == 5'd19) begin
				IDCT_state <= S_IDCT_LEADOUT0;
			end
			
			else begin
				I_index <= 3'd0;
				J_index <= 3'd0;
				S_write_counter <= 7'd64;
				T_tog <= 1'b0;
				IDCT_state <= S_IDCT_S_PRIME0;
			end
		end
		
		
		
		//------------------------------------------LEADOUT----------------------------------------
		//-----------------------------------------------------------------------------------------
		
		S_IDCT_LEADOUT0:  begin
			DP1_write_enA <= 1'b0;
			DP1_write_enB <= 1'b0;
			DP1_addressA <= 7'd64;
			DP1_addressB <= 7'd65;
			IDCT_state <= S_IDCT_LEADOUT1;
		end
		
		S_IDCT_LEADOUT1:  begin
			if(LEADOUT_TOG == 1'b1) begin
				SRAM_we_n <= 1'b0;
				SRAM_address <= 16'd38400 + ((DataBlock_I_index_buf <<3) << 4 ) + ((DataBlock_I_index_buf <<3) << 6) + (DataBlock_J_index_buf << 2) +SRAM_write_counterJ + (SRAM_write_counterI << 4) + (SRAM_write_counterI << 6);
				SRAM_write_data <= {DP1_read_dataA[7:0], DP1_read_dataB[7:0]};
				DP1_addressA <= DP1_addressA + 2'd2;
				DP1_addressB <= DP1_addressB + 2'd2;
				if(SRAM_write_counterJ == 3'd3) begin
					SRAM_write_counterJ <= 3'd0;
					SRAM_write_counterI <= SRAM_write_counterI + 1'd1;
					if(SRAM_write_counterI == 4'd7) begin
						IDCT_state <= S_IDCT_END;
					end
				end
				else begin
					SRAM_write_counterJ <= SRAM_write_counterJ + 1'd1;
				end
			end
			else
				LEADOUT_TOG <= 1'b1;

		end 
		
		
		S_IDCT_END: begin
			SRAM_we_n <= 1'b1;
			IDCT_complete <= 1'b1;
		end
		
		default: IDCT_state <=  S_IDCT_IDLE;
		endcase
	end
end

endmodule
