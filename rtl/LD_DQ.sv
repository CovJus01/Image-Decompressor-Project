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

// This module generates the address for reading the SRAM
// in order to display the image on the screen
module LD_DQ (
   input  logic            Clock,
   input  logic            Resetn,

	output logic	[17:0] 	SRAM_address,
	output logic				SRAM_we_n,
	input	 logic	[15:0]	SRAM_read_data,
	output logic	[15:0]	SRAM_write_data,

   output logic   		   DP_we_n_a,
   output logic   [8:0]		DP_address_a,
   input  logic   [31:0]   DP_read_data_a,				// need read?
   output logic   [31:0]   DP_write_data_a,
   output logic   		   DP_we_n_b,						// need b?
   output logic   [8:0]  	DP_address_b,
   input  logic   [31:0]   DP_read_data_b, 
   output logic   [31:0]   DP_write_data_b,
	input  logic				new_block,
	output logic				finished
);

LD_DQ_state_type LD_DQ_state;

logic [15:0] read_address_counter;

logic 		q;
logic [31:0] bitstream;
logic [5:0] bitstream_counter;
logic [3:0] bit_num;
logic [3:0] bit_size;
logic [15:0] write_data;
logic [15:0] write_data_acc;
logic [11:0] write_bit_acc;
logic [8:0] write_bit;

logic [5:0] ZZ_counter;
logic [5:0] ZZ_address_offset;

logic [11:0] block_counter;
logic [11:0] total_block;

logic Y_UV_select;
logic U_V_select;
assign Y_UV_select = (total_block >= 12'd1200);
assign U_V_select = (total_block >= 12'd1800);

// for tb only
logic [16:0] block_row;
logic [8:0] block_col;


always_comb begin
	case (ZZ_counter)
	6'd0: ZZ_address_offset = 6'd0;
	6'd1: ZZ_address_offset = 6'd1;
	6'd2: ZZ_address_offset = 6'd8;
	6'd3: ZZ_address_offset = 6'd16;
	6'd4: ZZ_address_offset = 6'd9;
	6'd5: ZZ_address_offset = 6'd2;
	6'd6: ZZ_address_offset = 6'd3;
	6'd7: ZZ_address_offset = 6'd10;
	6'd8: ZZ_address_offset = 6'd17;
	6'd9: ZZ_address_offset = 6'd24;
	6'd10: ZZ_address_offset = 6'd32;
	6'd11: ZZ_address_offset = 6'd25;
	6'd12: ZZ_address_offset = 6'd18;
	6'd13: ZZ_address_offset = 6'd11;
	6'd14: ZZ_address_offset = 6'd4;
	6'd15: ZZ_address_offset = 6'd5;
	6'd16: ZZ_address_offset = 6'd12;
	6'd17: ZZ_address_offset = 6'd19;
	6'd18: ZZ_address_offset = 6'd26;
	6'd19: ZZ_address_offset = 6'd33;
	6'd20: ZZ_address_offset = 6'd40;
	6'd21: ZZ_address_offset = 6'd48;
	6'd22: ZZ_address_offset = 6'd41;
	6'd23: ZZ_address_offset = 6'd34;
	6'd24: ZZ_address_offset = 6'd27;
	6'd25: ZZ_address_offset = 6'd20;
	6'd26: ZZ_address_offset = 6'd13;
	6'd27: ZZ_address_offset = 6'd6;
	6'd28: ZZ_address_offset = 6'd7;
	6'd29: ZZ_address_offset = 6'd14;
	6'd30: ZZ_address_offset = 6'd21;
	6'd31: ZZ_address_offset = 6'd28;
	6'd32: ZZ_address_offset = 6'd35;
	6'd33: ZZ_address_offset = 6'd42;
	6'd34: ZZ_address_offset = 6'd49;
	6'd35: ZZ_address_offset = 6'd56;
	6'd36: ZZ_address_offset = 6'd57;
	6'd37: ZZ_address_offset = 6'd50;
	6'd38: ZZ_address_offset = 6'd43;
	6'd39: ZZ_address_offset = 6'd36;
	6'd40: ZZ_address_offset = 6'd29;
	6'd41: ZZ_address_offset = 6'd22;
	6'd42: ZZ_address_offset = 6'd15;
	6'd43: ZZ_address_offset = 6'd23;
	6'd44: ZZ_address_offset = 6'd30;
	6'd45: ZZ_address_offset = 6'd37;
	6'd46: ZZ_address_offset = 6'd44;
	6'd47: ZZ_address_offset = 6'd51;
	6'd48: ZZ_address_offset = 6'd58;
	6'd49: ZZ_address_offset = 6'd59;
	6'd50: ZZ_address_offset = 6'd52;
	6'd51: ZZ_address_offset = 6'd45;
	6'd52: ZZ_address_offset = 6'd38;
	6'd53: ZZ_address_offset = 6'd31;
	6'd54: ZZ_address_offset = 6'd39;
	6'd55: ZZ_address_offset = 6'd46;
	6'd56: ZZ_address_offset = 6'd53;
	6'd57: ZZ_address_offset = 6'd60;
	6'd58: ZZ_address_offset = 6'd61;
	6'd59: ZZ_address_offset = 6'd54;
	6'd60: ZZ_address_offset = 6'd47;
	6'd61: ZZ_address_offset = 6'd55;
	6'd62: ZZ_address_offset = 6'd62;
	6'd63: ZZ_address_offset = 6'd63;
	endcase
end 

logic [3:0] di;
assign di = ZZ_address_offset[5:3] + ZZ_address_offset[2:0];

logic [2:0] shift;

always_comb begin
	shift = 3'd0;
	if (q == 1'b0) begin 
		case (di)
		4'd0: shift = 3'd3;
		4'd1: shift = 3'd2;
		4'd2: shift = 3'd3;
		4'd3: shift = 3'd3;
		4'd4: shift = 3'd4;
		4'd5: shift = 3'd4;
		4'd6: shift = 3'd5;
		4'd7: shift = 3'd5;
		4'd8: shift = 3'd6;
		4'd9: shift = 3'd6;
		4'd10: shift = 3'd6;
		4'd11: shift = 3'd6;
		4'd12: shift = 3'd6;
		4'd13: shift = 3'd6;
		4'd14: shift = 3'd6;
		default: shift = 3'd0;
		endcase
	end 
	else begin
		case (di)
		4'd0: shift = 3'd3;
		4'd1: shift = 3'd1;
		4'd2: shift = 3'd1;
		4'd3: shift = 3'd1;
		4'd4: shift = 3'd2;
		4'd5: shift = 3'd2;
		4'd6: shift = 3'd3;
		4'd7: shift = 3'd3;
		4'd8: shift = 3'd4;
		4'd9: shift = 3'd4;
		4'd10: shift = 3'd4;
		4'd11: shift = 3'd5;
		4'd12: shift = 3'd5;
		4'd13: shift = 3'd5;
		4'd14: shift = 3'd5;
		default: shift = 3'd0;
		endcase
	end
end

always_comb begin
	write_bit = 9'h1FF;
	if (bit_size == 4'd1) begin
		write_bit = 9'b0;
	end
	else if (bit_size == 4'd4) begin
		case (bit_num)
		4'd1: write_bit = {5'd0, write_bit_acc[3:0]};
		4'd2: write_bit = {5'd0, write_bit_acc[7:4]};
		4'd3: write_bit = {5'd0, write_bit_acc[11:8]};
		default: write_bit = 9'd0;
		endcase
	end
	else if (bit_size == 4'd9) begin
		write_bit = write_bit_acc[8:0];
	end
end

always_comb begin
	write_data_acc = 16'hFFFF;
	
	if (bit_size == 4'd1) begin
		write_data_acc = write_bit;
	end
	else if (bit_size == 4'd4) begin
		if (write_bit[3] == 1'b0) 
			write_data_acc = write_bit;
		else begin
			write_data_acc = {13'h1FFF, write_bit[2:0]};
			
		end
	end 
	else if (bit_size == 4'd9) begin
		if (write_bit[8] == 1'b0) 
			write_data_acc = write_bit;
		else begin
			write_data_acc = {8'hFF, write_bit[7:0]};
			
		end
	end

end

always_comb begin
	case (shift)
	4'd1: write_data = write_data_acc << 1;
	4'd2: write_data = write_data_acc << 2;
	4'd3: write_data = write_data_acc << 3;
	4'd4: write_data = write_data_acc << 4;
	4'd5: write_data = write_data_acc << 5;
	4'd6: write_data = write_data_acc << 6;
	default: write_data = 4'hF;
	endcase
end

logic 		insert_value;
assign insert_value = (bitstream_counter <= 16);

logic [3:0] shift_value;
assign shift_value = 6'd16 - bitstream_counter;

logic [31:0] bitstream_add;
logic [15:0] bitstream_buf;

always_comb begin
	if (bitstream_buf == 8'd0) begin
		case (shift_value)
		4'd0: bitstream_add = SRAM_read_data << 0;
		4'd2: bitstream_add = SRAM_read_data << 2;
		4'd4: bitstream_add = SRAM_read_data << 4;
		4'd6: bitstream_add = SRAM_read_data << 6;
		4'd8: bitstream_add = SRAM_read_data << 8;
		4'd10: bitstream_add = SRAM_read_data << 10;
		4'd12: bitstream_add = SRAM_read_data << 12;
		4'd14: bitstream_add = SRAM_read_data << 14;
		default: bitstream_add = 31'hFFFF;
		endcase
	end 
	else begin
		case (shift_value)
		4'd0: bitstream_add = bitstream_buf << 0;
		4'd2: bitstream_add = bitstream_buf << 2;
		4'd4: bitstream_add = bitstream_buf << 4;
		4'd6: bitstream_add = bitstream_buf << 6;
		4'd8: bitstream_add = bitstream_buf << 8;
		4'd10: bitstream_add = bitstream_buf << 10;
		4'd12: bitstream_add = bitstream_buf << 12;
		4'd14: bitstream_add = bitstream_buf << 14;
		default: bitstream_add = 31'hFFFF;
		endcase
	end
end

logic zero;
logic [3:0] write_to_buf; 
logic added_value;
logic can_read;
assign can_read = write_to_buf[2];


always_ff @ (posedge Clock or negedge Resetn) begin
	if (Resetn == 1'b0) begin

		SRAM_address <= BITSTREAM_START_ADDRESS; 
		read_address_counter <= 16'd2;

		DP_address_a <= 9'd0;
		DP_we_n_a <= 1'b1;
		DP_write_data_a <= 9'd0;
		
		q <= 1'b0;
		
		bitstream <= 32'd0;
		bitstream_counter <= 6'd0;
		
		ZZ_counter <= 6'd0;
		bit_num <= 4'd0;
		bit_size <= 4'd0;
		write_bit_acc <= 12'd0;
		
		block_counter <= 12'd0;
		total_block <= 12'd0;
		
		zero <= 1'b0;
		bitstream_buf <= 16'd0;
		write_to_buf <= 4'd0;
		added_value <= 1'b0;
		
		// tb only
		block_row <= 17'd0;
		block_col <= 9'd0;
		
	end else begin
		case (LD_DQ_state)
		S_LD_DQ_IDLE: begin
			if (new_block == 1'b1) begin
				SRAM_address <= BITSTREAM_START_ADDRESS + read_address_counter;
				read_address_counter <= read_address_counter + 16'd2;
				LD_DQ_state <= S_LD_DQ_LEADIN_0;
			end
		end
		S_LD_DQ_LEADIN_0: begin
			SRAM_address <= BITSTREAM_START_ADDRESS + read_address_counter;
			read_address_counter <= read_address_counter + 16'd1;
			LD_DQ_state <= S_LD_DQ_LEADIN_1;
		end
		S_LD_DQ_LEADIN_1: begin
			SRAM_address <= BITSTREAM_START_ADDRESS + read_address_counter;
			read_address_counter <= read_address_counter + 16'd1;
			LD_DQ_state <= S_LD_DQ_LEADIN_2;
		end
		S_LD_DQ_LEADIN_2: begin
			q <= SRAM_read_data[15];
			LD_DQ_state <= S_LD_DQ_LEADIN_3;
		end
		S_LD_DQ_LEADIN_3: begin
			bitstream <= {SRAM_read_data,16'b0};
			bitstream_counter <= bitstream_counter + 6'd16;
			LD_DQ_state <= S_LD_DQ_LEADIN_4;
		end
		S_LD_DQ_LEADIN_4: begin
			bitstream <= bitstream + SRAM_read_data;
			bitstream_counter <= bitstream_counter + 6'd16;

			LD_DQ_state <= S_LD_DQ_WAIT_FOR_NEW_BLOCK;
		end
		S_LD_DQ_WAIT_FOR_NEW_BLOCK: begin
			write_to_buf <= write_to_buf << 1;
			if (bitstream_buf == 16'd0 && can_read == 1'b1) begin 
				bitstream_buf <= SRAM_read_data; // case 4
			end
			if (new_block == 1'b1) LD_DQ_state <= S_LD_DQ_LEADIN_5;
		end
		
		S_LD_DQ_LEADIN_5: begin
			SRAM_address <= BITSTREAM_START_ADDRESS + read_address_counter + added_value;
			write_to_buf <= (write_to_buf << 1) + 4'd1;
			if (added_value == 1'b1) begin
				read_address_counter <= read_address_counter + 16'd1;
			end
			else if (total_block == 12'd0) read_address_counter <= read_address_counter + 16'd1;
			LD_DQ_state <= S_LD_DQ_LEADIN_6;
		end
		S_LD_DQ_LEADIN_6: begin
			added_value <= 1'b0;
			write_to_buf <= write_to_buf << 1;
			LD_DQ_state <= S_LD_DQ_READ_HEADER;
		end
		
		
		S_LD_DQ_READ_HEADER: begin
			// read header
			DP_we_n_a <= 1'b1;
			

			SRAM_address <= BITSTREAM_START_ADDRESS + read_address_counter + added_value;
			write_to_buf <= (write_to_buf << 1) + 4'd1;
			if (added_value == 1'b1) begin
				read_address_counter <= read_address_counter + 16'd1;
			end

			
			
			if (bitstream_buf == 16'd0) begin
				if (can_read == 1'b1) begin 
					bitstream_buf <= SRAM_read_data; // case 4
				end
			end

			
			
			if (bitstream[31:30] == 2'b11) begin	//0
				// 1 4bit
				bit_num = 4'd1;
				bit_size = 4'd4;
				write_bit_acc <= bitstream[29:26];
				bitstream <= bitstream << 6;
				bitstream_counter <= bitstream_counter - 6'd6;
				
				LD_DQ_state <= S_LD_DQ_WRITE;
			end 
			else if (bitstream[31:30] == 2'b10) begin //1
				// 2 4bit
				
				bit_num = 4'd2;
				bit_size = 4'd4;
				write_bit_acc <= bitstream[29:22];
				bitstream <= bitstream << 10;
				bitstream_counter <= bitstream_counter - 6'd10;
			end
			else if (bitstream[31:30] == 2'b01) begin //2
				// fill 4bit with zeros

				bit_num <= bitstream[29:26];
				bit_size <= 4'd1;
				bitstream <= bitstream << 6;
				bitstream_counter <= bitstream_counter - 6'd6;
			end 
			else if (bitstream[31:29] == 3'b001) begin //3
				// 1 9bit
				
				bit_num = 4'd1;
				bit_size = 4'd9;
				write_bit_acc <= bitstream[28:20];
				bitstream <= bitstream << 12;
				bitstream_counter <= bitstream_counter - 6'd12;
			end
			else if (bitstream[31:28] == 4'b0001) begin //4
				// 3 4bit
				bit_num = 4'd3;
				bit_size = 4'd4;
				write_bit_acc <= bitstream[27:16];
				bitstream <= bitstream << 16;
				bitstream_counter <= bitstream_counter - 6'd16;
			end
			else if (bitstream[31:28] == 4'b0000) begin
				// fill rest with zero

				zero <= 1'b1;
				bit_num = 4'd1;
				bit_size = 4'd1;
				bitstream <= bitstream << 4;
				bitstream_counter <= bitstream_counter - 6'd4;
				
				
			end
			LD_DQ_state <= S_LD_DQ_WRITE;
		end
		S_LD_DQ_WRITE: begin
			// write values to DP and SRAM
			
			DP_we_n_a <= 1'b0;
			ZZ_counter <= ZZ_counter + 6'd1;
			DP_address_a <= ZZ_address_offset;
			bit_num <= bit_num - 4'd1;
			DP_write_data_a <= write_data;
			
			// tb purposes only
			if (DP_SRAM_SELECT == 1'b1) begin
				if (Y_UV_select == 1'b0) SRAM_address = preIDCT_START_ADDRESS + {15'd0, ZZ_address_offset[2:0]} + 
					{7'b0, ZZ_address_offset[5], 1'b0, ZZ_address_offset[5], 8'b0} + 
					{8'b0, ZZ_address_offset[4], 1'b0, ZZ_address_offset[4], 7'b0} + 
					{9'b0, ZZ_address_offset[3], 1'b0, ZZ_address_offset[3], 6'b0} + 
					{9'b0, block_col << 3} + {1'b0, block_row << 11} + {3'b0, block_row << 9};
				else if (U_V_select == 1'b0) SRAM_address = preIDCT_START_ADDRESS + {15'd0, ZZ_address_offset[2:0]} + 
					{8'b0, ZZ_address_offset[5], 1'b0, ZZ_address_offset[5], 7'b0} + 
					{9'b0, ZZ_address_offset[4], 1'b0, ZZ_address_offset[4], 6'b0} + 
					{10'b0, ZZ_address_offset[3], 1'b0, ZZ_address_offset[3], 5'b0} + 
					{9'b0, block_col << 3} + 18'd76800 + {2'b0, block_row << 10} + {4'b0, block_row << 8};
				else SRAM_address = preIDCT_START_ADDRESS + {15'd0, ZZ_address_offset[2:0]} + 
					{8'b0, ZZ_address_offset[5], 1'b0, ZZ_address_offset[5], 7'b0} + 
					{9'b0, ZZ_address_offset[4], 1'b0, ZZ_address_offset[4], 6'b0} + 
					{10'b0, ZZ_address_offset[3], 1'b0, ZZ_address_offset[3], 5'b0} + 
					{9'b0, block_col << 3} + 18'd115200 + {2'b0, block_row << 10} + {4'b0, block_row << 8};
				SRAM_write_data = write_data;
			end
			
			// add to bitstream
			if (insert_value == 1'b1) begin
				if (bitstream_buf != 16'd0)  begin
					if (can_read == 1'b1) begin 
						if (SRAM_read_data != bitstream_buf) bitstream_buf <= SRAM_read_data; // case 0
						else bitstream_buf <= 16'b0;											// case 1
					end
					else bitstream_buf <= 16'd0;
				end
				
				bitstream_counter <= bitstream_counter + 6'd16;
				bitstream <= bitstream + bitstream_add;									// case 2
				added_value <= 1'b1;
			end
			else begin 
				if (bitstream_buf == 16'd0 && can_read == 1'b1) begin 
					bitstream_buf <= SRAM_read_data; // case 4
				end
				if (write_to_buf[0] == 1'b1) added_value <= 1'b0;
			end 
			write_to_buf <= write_to_buf << 1;
			
			// check if at the end of block
			if (ZZ_counter == 6'd63) begin
				ZZ_counter <= 6'b0;
				
				if (block_col == 9'd39 && Y_UV_select == 1'b0) begin
					block_row <= block_row + 17'd1;
					block_col <= 9'd0;
				end
				else if (block_col == 9'd19 && Y_UV_select == 1'b1) begin
					block_row <= block_row + 17'd1;
					block_col <= 9'd0;
				end
				else block_col <= block_col + 9'd1;
				LD_DQ_state <= S_LD_DQ_FINISH_BLOCK; 
			end 
			else begin
				if (bit_num == 4'd1 && zero == 1'b0) LD_DQ_state <= S_LD_DQ_READ_HEADER;
			end
		end
		S_LD_DQ_FINISH_BLOCK: begin
			
			DP_we_n_a <= 1'b1;
			
			write_to_buf <= write_to_buf << 1;
			if (bitstream_buf == 16'd0 && can_read == 1'b1) begin 
				bitstream_buf <= SRAM_read_data; // case 4
			end
			
			zero <= 1'b0;
			
			if (total_block == 12'd2399) begin
				total_block <= 12'd0;
				block_counter <= 12'd0;
				block_row <= 17'd0;
				block_col <= 9'd0;
				finished <= 1'b1;
				LD_DQ_state <= S_LD_DQ_IDLE;
				end
			else if (block_counter == 12'd1199 && Y_UV_select == 1'b0) begin
				total_block <= total_block + 12'd1;
				block_counter <= 12'd0;
				block_row <= 17'd0;
				block_col <= 9'd0;
				LD_DQ_state <= S_LD_DQ_WAIT_FOR_NEW_BLOCK;
			end
			else if (block_counter == 12'd599 && Y_UV_select == 1'b1) begin
				total_block <= total_block + 12'd1;
				block_counter <= 12'd0;
				block_row <= 17'd0;
				block_col <= 9'd0;
				LD_DQ_state <= S_LD_DQ_WAIT_FOR_NEW_BLOCK;
			end
			else begin
				block_counter <= block_counter + 12'd1;
				total_block <= total_block + 12'd1;
				LD_DQ_state <= S_LD_DQ_WAIT_FOR_NEW_BLOCK;
			end
		end
		default: LD_DQ_state <= S_LD_DQ_IDLE;
		endcase
	end
end

always_comb begin
	
	SRAM_we_n = 1'b1;

	if (DP_SRAM_SELECT == 1'b1) begin
		SRAM_we_n = DP_we_n_a;
	end
end



endmodule
