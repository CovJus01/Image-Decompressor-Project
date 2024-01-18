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
module US_CSC (
   input  logic            Clock,
   input  logic            Resetn,

   output logic   		   SRAM_we_n,
   output logic   [17:0]   SRAM_address,
   input  logic   [15:0]   SRAM_read_data,
   output logic   [15:0]   SRAM_write_data,
	input  logic 				US_CSC_enable,
	output logic				US_CSC_complete

);

US_CSC_state_type US_CSC_state;

logic CSC_select;
logic U_V_RB_G_select;

logic [16:0] write_address_counter;
logic [15:0] read_address_counter;
logic [7:0] col_counter;

logic [7:0] U_prime, V_prime, Y_prime;

logic [7:0] Y_buf;

logic [7:0] U_buf [4:0];
logic [15:0] U_21 [4:0];
logic [15:0] U_52 [2:0];
logic [15:0] U_159;

logic [7:0] V_buf [3:0];
logic [15:0] V_21 [4:0];
logic [15:0] V_52 [2:0];
logic [15:0] V_159;

logic [7:0] R, G, B;
logic signed [31:0] R_acc, G_acc, B_acc;
logic [7:0] R_buf, B_buf;


logic signed [31:0] Multi0_op1, Multi0_op2, Multi1_op1, Multi1_op2, Multi2_op1, Multi2_op2;
logic signed [31:0] Multi0_out, Multi1_out, Multi2_out;
// logic signed [63:0] Multi0_out_long, Multi1_out_long, Multi2_out_long;

assign Multi0_out = Multi0_op1 * Multi0_op2;

assign Multi1_out = Multi1_op1 * Multi1_op2;

assign Multi2_out = Multi2_op1 * Multi2_op2;


always_comb begin
if (col_counter == 8'b0) begin						// lead in 
	Multi0_op1 = 32'd21;
	Multi1_op1 = 32'd52;

	if (CSC_select == 1'b0) Multi2_op1 = 32'd159;
	else Multi2_op1 = 32'd21;

	
	if (U_V_RB_G_select == 1'b0) begin 
		if (CSC_select == 1'b0) begin
			Multi0_op2 = U_buf[0];
			Multi1_op2 = U_buf[0];
			Multi2_op2 = U_buf[0];
		end
		else begin
			Multi0_op2 = U_buf[1];
			Multi1_op2 = U_buf[1];
			Multi2_op2 = U_buf[2];
		end
	end
	else begin
		if (CSC_select == 1'b0) begin
			Multi0_op2 = V_buf[0];
			Multi1_op2 = V_buf[0];
			Multi2_op2 = V_buf[0];
		end
		else begin
			Multi0_op2 = V_buf[1];
			Multi1_op2 = V_buf[1];
			Multi2_op2 = V_buf[2];
		end
	end
end
else begin										// common case

	if (CSC_select == 1'b0) begin 				// use for upsampling
		Multi0_op1 = 32'd21;
		Multi1_op1 = 32'd52;
		Multi2_op1 = 32'd159;
		
		if (U_V_RB_G_select == 1'b0) begin			// multiply U data
			Multi0_op2 = U_buf[2];
			Multi1_op2 = U_buf[1];
			Multi2_op2 = U_buf[0];
		end
		else begin											// multiply V data
			Multi0_op2 = V_buf[2];
			Multi1_op2 = V_buf[1];
			Multi2_op2 = V_buf[0];
		end
	end
	else begin											// use for colourspace conversion
		Multi0_op1 = Y_prime-8'd16;
		Multi1_op1 = U_prime-8'd128;
		Multi2_op1 = V_prime-8'd128;
		
		Multi0_op2 = 32'd76284;
		if (U_V_RB_G_select == 1'b0) begin			// Get R and B data
			Multi1_op2 = 32'd132251;
			Multi2_op2 = 32'd104595;
		end
		else begin											// Get G data
			Multi1_op2 = -32'd25624;
			Multi2_op2 = -32'd53281;
		end
	end

end
end


logic signed [31:0] U_acc, V_acc;
logic [7:0] U, V;

assign U_acc = U_21[0] - U_52[0] + U_159 + Multi2_out - Multi1_out + Multi0_out + 32'd128;
assign V_acc = V_21[0] - V_52[0] + V_159 + Multi2_out - Multi1_out + Multi0_out + 32'd128;

assign U = U_acc[31] ? 8'b0 : ((U_acc[30:16] > 1'b0) ? 8'hff : U_acc[15:8]);
assign V = V_acc[31] ? 8'b0 : ((V_acc[30:16] > 1'b0) ? 8'hff : V_acc[15:8]);


assign R_acc = Multi0_out + Multi2_out;
assign G_acc = Multi0_out + Multi1_out + Multi2_out;
assign B_acc = Multi0_out + Multi1_out;

assign R = R_acc[31] ? 8'b0 : ((R_acc[30:24] > 1'b0) ? 8'hff : R_acc[23:16]);
assign G = G_acc[31] ? 8'b0 : ((G_acc[30:24] > 1'b0) ? 8'hff : G_acc[23:16]);
assign B = B_acc[31] ? 8'b0 : ((B_acc[30:24] > 1'b0) ? 8'hff : B_acc[23:16]);


integer i;

always_ff @ (posedge Clock or negedge Resetn) begin
	if (Resetn == 1'b0) begin
		CSC_select <= 1'b0;
		U_V_RB_G_select <= 1'b0;
		write_address_counter <= 17'b0;
		read_address_counter <= 16'b0;
		col_counter <= 8'b0;
		
		US_CSC_complete <= 1'b0;
		
		Y_prime <= 8'b0;		
		U_prime <= 8'b0;
		V_prime <= 8'b0;
		
		for (i=0; i < 5; i=i+1) U_21[i] <= 16'b0;
		for (i=0; i < 3; i=i+1) U_52[i] <= 16'b0;
		U_159 <= 8'b0;
		for (i=0; i < 5; i=i+1) V_21[i] <= 16'b0;
		for (i=0; i < 3; i=i+1) V_52[i] <= 16'b0;
		V_159 <= 8'b0;
		
		for (i=0; i < 5; i=i+1) U_buf[i] <= 8'b0;
		for (i=0; i < 4; i=i+1) V_buf[i] <= 8'b0;
		
	end else begin
		case (US_CSC_state)
		S_US_CSC_IDLE: begin
			if (US_CSC_enable == 1'b1) begin
				write_address_counter <= 17'b0;
				read_address_counter <= 16'b0;
				US_CSC_state <= S_US_CSC_LEADIN_NEW_ROW;
			end
		end
		S_US_CSC_LEADIN_NEW_ROW: begin							//0
			SRAM_address <= U_START_ADDRESS + (read_address_counter >> 1);
			SRAM_we_n <= 1'b1;
			US_CSC_state <= S_US_CSC_LEADIN_DELAY_0;
		end
		S_US_CSC_LEADIN_DELAY_0: begin							//1
			SRAM_address <= U_START_ADDRESS + (read_address_counter >> 1) + 1'b1;
			US_CSC_state <= S_US_CSC_LEADIN_DELAY_1;
		end
		S_US_CSC_LEADIN_DELAY_1: begin							//2
			SRAM_address <= V_START_ADDRESS + (read_address_counter >> 1);
			US_CSC_state <= S_US_CSC_LEADIN_MULTI_U_0;
		end
		S_US_CSC_LEADIN_MULTI_U_0: begin						//3
			SRAM_address <= V_START_ADDRESS + (read_address_counter >> 1) + 1'b1;
			
			CSC_select <= 1'b0;
			U_V_RB_G_select <= 1'b0;
			
			U_buf[0] <= SRAM_read_data[15:8];
			U_buf[1] <= SRAM_read_data[7:0];
			
			US_CSC_state <= S_US_CSC_LEADIN_MULTI_U_1;
		end
		S_US_CSC_LEADIN_MULTI_U_1: begin						//4
			SRAM_address <= Y_START_ADDRESS + read_address_counter;
			
			CSC_select <= 1'b1;
			// U_V_RB_G_select <= 1'b0;
			
			U_buf[2] <= SRAM_read_data[15:8];
			U_buf[3] <= SRAM_read_data[7:0];
			
			U_21[0] <= Multi0_out[15:0];
			U_21[1] <= Multi0_out[15:0];
			U_21[2] <= Multi0_out[15:0];
			U_52[0] <= Multi1_out[15:0];
			U_52[1] <= Multi1_out[15:0];
			U_159 <= Multi2_out[15:0];
			
			US_CSC_state <= S_US_CSC_LEADIN_MULTI_V_0;
		end 
		S_US_CSC_LEADIN_MULTI_V_0: begin						//5
		
			CSC_select <= 1'b0;
			U_V_RB_G_select <= 1'b1;
			
			V_buf[0] <= SRAM_read_data[15:8];
			V_buf[1] <= SRAM_read_data[7:0];
			
			U_21[3] <= Multi0_out;
			U_52[2] <= Multi1_out;
			U_21[4] <= Multi2_out;
			
			US_CSC_state <= S_US_CSC_LEADIN_MULTI_V_1;
		end 
		S_US_CSC_LEADIN_MULTI_V_1: begin								//6
			
			CSC_select <= 1'b1;
			//U_V_RB_G_select <= 1'b0;
			
			V_buf[2] <= SRAM_read_data[15:8];
			V_buf[3] <= SRAM_read_data[7:0];
									
			V_21[0] <= Multi0_out[15:0];
			V_21[1] <= Multi0_out[15:0];
			V_21[2] <= Multi0_out[15:0];
			V_52[0] <= Multi1_out[15:0];
			V_52[1] <= Multi1_out[15:0];
			V_159 <= Multi2_out[15:0];
			
			US_CSC_state <= S_US_CSC_LEADIN_YUV_PRIME;
		end 
		S_US_CSC_LEADIN_YUV_PRIME: begin								//7

			//CSC_select <= 1'b1;
			U_V_RB_G_select <= 1'b0;
			
			U_prime <= U_buf[0];
			V_prime <= V_buf[0];
			Y_prime <= SRAM_read_data[15:8];

			Y_buf = SRAM_read_data[7:0];
			
			col_counter <= col_counter + 8'b1;
			read_address_counter <= read_address_counter + 16'b1;
			
			V_21[3] <= Multi0_out;
			V_52[2] <= Multi1_out;
			V_21[4] <= Multi2_out;

			
			US_CSC_state <= S_US_CSC_LEADIN_RB;
		end 
		S_US_CSC_LEADIN_RB: begin										//8
			
			U_V_RB_G_select <= 1'b1;

			R_buf <= R;
			B_buf <= B;
			
			US_CSC_state <= S_US_CSC_WRITE_0;
		end
		S_US_CSC_WRITE_0: begin											//9
		
			SRAM_we_n <= 1'b0;
			SRAM_address <= RGB_START_ADRRESS + write_address_counter;
			write_address_counter <= write_address_counter + 17'b1;
			SRAM_write_data <= {R_buf, G};

			CSC_select <= 1'b0;
			U_V_RB_G_select <= 1'b0;		

			for (i=1; i<5;i=i+1) U_buf[i-1] <= U_buf[i];
			U_buf[4] <= 8'b0;
			
			US_CSC_state <= S_US_CSC_READ_Y;
		end
		S_US_CSC_READ_Y: begin 											//10
			
			SRAM_we_n <= 1'b1;
			SRAM_address <= Y_START_ADDRESS + read_address_counter; 
			
			//CSC_select <= 1'b0;
			U_V_RB_G_select <= 1'b1;		

			for (i=1; i<5;i=i+1) U_21[i-1] <= U_21[i];
			U_21[4] <= Multi0_out[15:0];			
			for (i=1; i<3;i=i+1) U_52[i-1] <= U_52[i];
			U_52[2] <= Multi1_out[15:0];
			U_159 <= Multi2_out[15:0];
			
			V_buf[0] <= V_buf[1];
			V_buf[1] <= V_buf[2];
			if (read_address_counter[0] == 1'b1) begin
				V_buf[2] <= V_buf[3];
				V_buf[3] <= 8'b0;
			end
			else begin
				if (col_counter == 8'd158 || col_counter == 8'd160) begin
					V_buf[2] <= V_buf[2];
					V_buf[3] <= V_buf[2];
				end
				else begin
					V_buf[2] <= SRAM_read_data[15:8];
					V_buf[3] <= SRAM_read_data[7:0];
				end
			end
			

			U_prime <= U;
			Y_prime <= Y_buf;
			
			US_CSC_state <= S_US_CSC_READ_U;
		end
		S_US_CSC_READ_U: begin											//11
			
			if (read_address_counter[0] == 16'b1) begin
				// SRAM_we_n <= 1'b1;
				SRAM_address <= U_START_ADDRESS + (read_address_counter >> 1) + 16'd2; 
			end
			
			CSC_select <= 1'b1;
			U_V_RB_G_select <= 1'b0;		
			
			for (i=1; i<5;i=i+1) V_21[i-1] <= V_21[i];
			V_21[4] <= Multi0_out[15:0];
			for (i=1; i<3;i=i+1) V_52[i-1] <= V_52[i];
			V_52[2] <= Multi1_out[15:0];
			V_159 <= Multi2_out[15:0];
			
			V_prime <= V;
			
			US_CSC_state <= S_US_CSC_WRITE_1;
		end
		S_US_CSC_WRITE_1: begin 										//12
			
			// CSC_select <= 1'b1;
			U_V_RB_G_select <= 1'b1;

			SRAM_we_n <= 1'b0;
			SRAM_address <= RGB_START_ADRRESS + write_address_counter;
			write_address_counter <= write_address_counter + 17'b1;
			SRAM_write_data <= {B_buf, R};
			
			B_buf <= B;
			
			US_CSC_state <= S_US_CSC_WRITE_2;
		end
		S_US_CSC_WRITE_2: begin 										//13
		
			// CSC_select <= 1'b1;
			// U_V_RB_G_select <= 1'b1;

			// SRAM_we_n <= 1'b0;
			SRAM_address <= RGB_START_ADRRESS + write_address_counter;
			write_address_counter <= write_address_counter + 17'b1;
			SRAM_write_data <= {G, B_buf};
			
			Y_prime <= SRAM_read_data[15:8];
			U_prime <= U_buf[0];
			V_prime <= V_buf[0];
			
			Y_buf <= SRAM_read_data[7:0];			
		
			US_CSC_state <= S_US_CSC_READ_V;
		end
		S_US_CSC_READ_V: begin 											//14
			
			SRAM_we_n <= 1'b1;
			if (read_address_counter[0] == 1'b1) begin
				SRAM_address <= V_START_ADDRESS + (read_address_counter >> 1) + 16'd2;
			end
			
			// CSC_select <= 1'b1;
			U_V_RB_G_select <= 1'b0;
			
			if (col_counter == 8'd157 || col_counter == 8'd159) begin //lead out
				U_buf[3] <= U_buf[2];
				U_buf[4] <= U_buf[2];
			end
			else begin
				if (read_address_counter[0] == 1'b1) begin 
					U_buf[3] <= SRAM_read_data[15:8];
					U_buf[4] <= SRAM_read_data[7:0];
				end
			end
			
			US_CSC_state <= S_US_CSC_DELAY;
		end
		S_US_CSC_DELAY: begin 											//15
		
			// CSC_select <= 1'b1;
			U_V_RB_G_select <= 1'b1;
			
			R_buf <= R;
			B_buf <= B;
			
			if (col_counter == 8'd160) begin
				col_counter <= 8'b0;
				US_CSC_state <= S_US_CSC_LEADIN_NEW_ROW;
				
				if (write_address_counter == 17'd115200)
					US_CSC_state <= S_US_CSC_END;
				
			end
			else begin
				col_counter <= col_counter + 8'b1;
				read_address_counter <= read_address_counter + 16'b1;
				US_CSC_state <= S_US_CSC_WRITE_0;
			end
		end
		S_US_CSC_END: begin
			US_CSC_complete <= 1'b1;
		end
		
		
		default: US_CSC_state <= S_US_CSC_IDLE;
		endcase
	end
end

endmodule