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

// This is the top module (same as experiment4 from lab 5 - just module renamed to "project")
// It connects the UART, SRAM and VGA together.
// It gives access to the SRAM for UART and VGA
module project (
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock

		/////// pushbuttons/switches              ////////////
		input logic[3:0] PUSH_BUTTON_N_I,         // pushbuttons
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// 7 segment displays/LEDs           ////////////
		output logic[6:0] SEVEN_SEGMENT_N_O[7:0], // 8 seven segment displays
		output logic[8:0] LED_GREEN_O,            // 9 green LEDs

		/////// VGA interface                     ////////////
		output logic VGA_CLOCK_O,                 // VGA clock
		output logic VGA_HSYNC_O,                 // VGA H_SYNC
		output logic VGA_VSYNC_O,                 // VGA V_SYNC
		output logic VGA_BLANK_O,                 // VGA BLANK
		output logic VGA_SYNC_O,                  // VGA SYNC
		output logic[7:0] VGA_RED_O,              // VGA red
		output logic[7:0] VGA_GREEN_O,            // VGA green
		output logic[7:0] VGA_BLUE_O,             // VGA blue
		
		/////// SRAM Interface                    ////////////
		inout wire[15:0] SRAM_DATA_IO,            // SRAM data bus 16 bits
		output logic[19:0] SRAM_ADDRESS_O,        // SRAM address bus 18 bits
		output logic SRAM_UB_N_O,                 // SRAM high-byte data mask 
		output logic SRAM_LB_N_O,                 // SRAM low-byte data mask 
		output logic SRAM_WE_N_O,                 // SRAM write enable
		output logic SRAM_CE_N_O,                 // SRAM chip enable
		output logic SRAM_OE_N_O,                 // SRAM output logic enable
		
		/////// UART                              ////////////
		input logic UART_RX_I,                    // UART receive signal
		output logic UART_TX_O                    // UART transmit signal
);
	
logic resetn;

top_state_type top_state;

// For Push button
logic [3:0] PB_pushed;

// For VGA SRAM interface
logic VGA_enable;
logic [17:0] VGA_base_address;
logic [17:0] VGA_SRAM_address;

// For SRAM
logic [17:0] SRAM_address;
logic [15:0] SRAM_write_data;
logic SRAM_we_n;
logic [15:0] SRAM_read_data;
logic SRAM_ready;

// For UART SRAM interface
logic UART_rx_enable;
logic UART_rx_initialize;
logic [17:0] UART_SRAM_address;
logic [15:0] UART_SRAM_write_data;
logic UART_SRAM_we_n;
logic [25:0] UART_timer;

logic [6:0] value_7_segment [7:0];

// For error detection in UART
logic Frame_error;

// For disabling UART transmit
assign UART_TX_O = 1'b1;


//DPRAM

logic [8:0] DP0_addressA;
logic [8:0] DP0_addressB;
logic [31:0] DP0_dataA;
logic [31:0] DP0_dataB;
logic DP0_write_enA;
logic DP0_write_enB;
logic [31:0] DP0_read_dataA;
logic [31:0] DP0_read_dataB;

logic [8:0] DP1_addressA;
logic [8:0] DP1_addressB;
logic [31:0] DP1_dataA;
logic [31:0] DP1_dataB;
logic DP1_write_enA;
logic DP1_write_enB;
logic [31:0] DP1_read_dataA;
logic [31:0] DP1_read_dataB;

//US_CSC
logic [8:0] DP2_addressA;
logic [8:0] DP2_addressB;
logic [31:0] DP2_dataA;
logic [31:0] DP2_dataB;
logic DP2_write_enA;
logic DP2_write_enB;
logic [31:0] DP2_read_dataA;
logic [31:0] DP2_read_dataB;


logic US_CSC_SRAM_we_n;
logic [17:0] US_CSC_SRAM_address;
logic [15:0] US_CSC_SRAM_write_data;
logic US_CSC_enable;
logic US_CSC_complete;
//IDCT

logic IDCT_SRAM_we_n;
logic [17:0] IDCT_SRAM_address;
logic [15:0] IDCT_SRAM_write_data;
logic [8:0] IDCT_DP0_addressA;
logic IDCT_DP0_write_enA;
logic [31:0] IDCT_DP0_write_dataA;
logic [8:0] IDCT_DP0_addressB;
logic IDCT_DP0_write_enB;
logic [31:0] IDCT_DP0_write_dataB;
logic [8:0] IDCT_DP1_addressA;
logic IDCT_DP1_write_enA;
logic [31:0] IDCT_DP1_write_dataA;
logic [8:0] IDCT_DP1_addressB;
logic IDCT_DP1_write_enB;
logic [31:0] IDCT_DP1_write_dataB;
logic IDCT_enable;
logic IDCT_complete;


//LD_DQ
logic LD_DQ_SRAM_we_n;
logic [17:0] LD_DQ_SRAM_address;
logic [15:0] LD_DQ_SRAM_write_data;
logic new_block;
logic finished;
logic LD_DQ_enable;

assign resetn = ~SWITCH_I[17] && SRAM_ready;

// Push Button unit
PB_controller PB_unit (
	.Clock_50(CLOCK_50_I),
	.Resetn(resetn),
	.PB_signal(PUSH_BUTTON_N_I),	
	.PB_pushed(PB_pushed)
);

VGA_SRAM_interface VGA_unit (
	.Clock(CLOCK_50_I),
	.Resetn(resetn),
	.VGA_enable(VGA_enable),
   
	// For accessing SRAM
	.SRAM_base_address(VGA_base_address),
	.SRAM_address(VGA_SRAM_address),
	.SRAM_read_data(SRAM_read_data),
   
	// To VGA pins
	.VGA_CLOCK_O(VGA_CLOCK_O),
	.VGA_HSYNC_O(VGA_HSYNC_O),
	.VGA_VSYNC_O(VGA_VSYNC_O),
	.VGA_BLANK_O(VGA_BLANK_O),
	.VGA_SYNC_O(VGA_SYNC_O),
	.VGA_RED_O(VGA_RED_O),
	.VGA_GREEN_O(VGA_GREEN_O),
	.VGA_BLUE_O(VGA_BLUE_O)
);

// UART SRAM interface
UART_SRAM_interface UART_unit(
	.Clock(CLOCK_50_I),
	.Resetn(resetn), 
   
	.UART_RX_I(UART_RX_I),
	.Initialize(UART_rx_initialize),
	.Enable(UART_rx_enable),
   
	// For accessing SRAM
	.SRAM_address(UART_SRAM_address),
	.SRAM_write_data(UART_SRAM_write_data),
	.SRAM_we_n(UART_SRAM_we_n),
	.Frame_error(Frame_error)
);

// SRAM unit
SRAM_controller SRAM_unit (
	.Clock_50(CLOCK_50_I),
	.Resetn(~SWITCH_I[17]),
	.SRAM_address(SRAM_address),
	.SRAM_write_data(SRAM_write_data),
	.SRAM_we_n(SRAM_we_n),
	.SRAM_read_data(SRAM_read_data),		
	.SRAM_ready(SRAM_ready),
		
	// To the SRAM pins
	.SRAM_DATA_IO(SRAM_DATA_IO),
	.SRAM_ADDRESS_O(SRAM_ADDRESS_O[17:0]),
	.SRAM_UB_N_O(SRAM_UB_N_O),
	.SRAM_LB_N_O(SRAM_LB_N_O),
	.SRAM_WE_N_O(SRAM_WE_N_O),
	.SRAM_CE_N_O(SRAM_CE_N_O),
	.SRAM_OE_N_O(SRAM_OE_N_O)
);

US_CSC US_CSC_unit (
	.Clock(CLOCK_50_I),
	.Resetn(resetn), 
	.SRAM_address(US_CSC_SRAM_address),
	.SRAM_write_data(US_CSC_SRAM_write_data),
	.SRAM_we_n(US_CSC_SRAM_we_n),
	.SRAM_read_data(SRAM_read_data),
	.US_CSC_enable(US_CSC_enable),
	.US_CSC_complete(US_CSC_complete)
);

// instantiate RAM0
dual_port_RAM0 RAM_inst0 (
	.address_a ( DP0_addressA ),
	.address_b ( DP0_addressB ),
	.clock ( CLOCK_50_I ),
	.data_a ( DP0_dataA),
	.data_b ( DP0_dataB ),
	.wren_a ( DP0_write_enA ),
	.wren_b ( DP0_write_enB ),
	.q_a ( DP0_read_dataA ),
	.q_b ( DP0_read_dataB)
);

// instantiate RAM1
dual_port_RAM1 RAM_inst1 (
	.address_a ( DP1_addressA ),
	.address_b ( DP1_addressB ),
	.clock ( CLOCK_50_I ),
	.data_a ( DP1_dataA),
	.data_b ( DP1_dataB ),
	.wren_a ( DP1_write_enA ),
	.wren_b ( DP1_write_enB ),
	.q_a ( DP1_read_dataA ),
	.q_b ( DP1_read_dataB)
);

IDCT IDCT_unit (
	.Clock(CLOCK_50_I),
	.Resetn(resetn),
	.SRAM_we_n(IDCT_SRAM_we_n),
	.SRAM_address(IDCT_SRAM_address),
	.SRAM_write_data(IDCT_SRAM_write_data),
	.SRAM_read_data(SRAM_read_data),
	.DP0_addressA(IDCT_DP0_addressA),
	.DP0_write_enA(IDCT_DP0_write_enA),
	.DP0_write_dataA(IDCT_DP0_write_dataA),
	.DP0_read_dataA(DP0_read_dataA),
	.DP0_addressB(IDCT_DP0_addressB),
	.DP0_write_enB(IDCT_DP0_write_enB),
	.DP0_write_dataB(IDCT_DP0_write_dataB),
	.DP0_read_dataB(DP0_read_dataB),
	.DP1_addressA(IDCT_DP1_addressA),
	.DP1_write_enA(IDCT_DP1_write_enA),
	.DP1_write_dataA(IDCT_DP1_write_dataA),
	.DP1_read_dataA(DP1_read_dataA),
	.DP1_addressB(IDCT_DP1_addressB),
	.DP1_write_enB(IDCT_DP1_write_enB),
	.DP1_write_dataB(IDCT_DP1_write_dataB),
	.DP1_read_dataB(DP1_read_dataB),
	.IDCT_enable(IDCT_enable),
	.IDCT_complete(IDCT_complete)
);

//instantiate RAM2
dual_port_RAM2 RAM_inst2 (
	.address_a ( DP2_addressA ),
	.address_b ( DP2_addressB ),
	.clock ( CLOCK_50_I ),
	.data_a ( DP2_dataA),
	.data_b ( DP2_dataB ),
	.wren_a ( DP2_write_enA ),
	.wren_b ( DP2_write_enB ),
	.q_a ( DP2_read_dataA ),
	.q_b ( DP2_read_dataB)
);
	
LD_DQ LD_DQ_unit (
	.Clock(CLOCK_50_I),
	.Resetn(resetn), 
	.SRAM_address(LD_DQ_SRAM_address),
	.SRAM_we_n(LD_DQ_SRAM_we_n),
	.SRAM_write_data(LD_DQ_SRAM_write_data),
	.SRAM_read_data(SRAM_read_data),
	.DP_address_a(DP2_addressA),
	.DP_we_n_a(DP2_write_enA),
	.DP_read_data_a(DP2_read_dataA),
	.DP_write_data_a(DP2_dataA),
	.DP_address_b(DP2_addressB),
	.DP_we_n_b(DP2_write_enB),
	.DP_read_data_b(DP2_read_dataB),
	.DP_write_data_b(DP2_dataB),
	.new_block(new_block),
	.finished(finished)
);


assign SRAM_ADDRESS_O[19:18] = 2'b00;




always @(posedge CLOCK_50_I or negedge resetn) begin
	if (~resetn) begin
		top_state <= S_IDLE;
		
		UART_rx_initialize <= 1'b0;
		UART_rx_enable <= 1'b0;
		UART_timer <= 26'd0;
		
		LD_DQ_enable <= 1'b0;
		new_block <= 1'b0;
		VGA_enable <= 1'b1;
		US_CSC_enable <= 1'b0;
	end else begin

		// By default the UART timer (used for timeout detection) is incremented
		// it will be synchronously reset to 0 under a few conditions (see below)
		UART_timer <= UART_timer + 26'd1;

		case (top_state)
		S_IDLE: begin
			VGA_enable <= 1'b1;  
			if (~UART_RX_I) begin
				// Start bit on the UART line is detected
				UART_rx_initialize <= 1'b1;
				UART_timer <= 26'd0;
				VGA_enable <= 1'b0;
				top_state <= S_UART_RX;
			end
		end

		S_UART_RX: begin
			// The two signals below (UART_rx_initialize/enable)
			// are used by the UART to SRAM interface for 
			// synchronization purposes (no need to change)
			UART_rx_initialize <= 1'b0;
			UART_rx_enable <= 1'b0;
			if (UART_rx_initialize == 1'b1) 
				UART_rx_enable <= 1'b1;

			// UART timer resets itself every time two bytes have been received
			// by the UART receiver and a write in the external SRAM can be done
			if (~UART_SRAM_we_n) 
				UART_timer <= 26'd0;

			// Timeout for 1 sec on UART (detect if file transmission is finished)
			if (UART_timer == 26'd49999999) begin
				top_state <= S_IDCT;
				UART_timer <= 26'd0;
			end
		end

/* 	S_LD_DQ_IDCT: begin
			LD_DQ_enable <= 1'b1;
			new_block <= 1'b1;
			if (finished == 1'b1) begin
				LD_DQ_enable <= 1'b0;
				new_block <= 1'b0;
				top_state <= S_US_CSC; */

		S_IDCT: begin
			IDCT_enable <= 1'b1;
			if (IDCT_complete == 1'b1) begin
				IDCT_enable <= 1'b0;
				top_state <= S_IDLE;
			end
		end
		S_US_CSC: begin
			US_CSC_enable <= 1'b1;
			if (US_CSC_complete == 1'b1) begin
				US_CSC_enable <= 1'b0;
				top_state <= S_IDLE;
			end
		end 
		
		
		
		default: top_state <= S_IDLE;

		endcase
	end
end









// for this design we assume that the RGB data starts at location 0 in the external SRAM
// if the memory layout is different, this value should be adjusted 
// to match the starting address of the raw RGB data segment
assign VGA_base_address = 18'd146944;

// Give access to SRAM for UART, VGA, US/ CSC at appropriate time
always_comb begin
	SRAM_address = VGA_SRAM_address;
	SRAM_write_data = 16'd0;
	SRAM_we_n = 1'b1;
	DP0_addressA = 1'b0;
	DP0_dataA = 1'b0;
	DP0_write_enA = 1'b0;
	DP0_addressB = 1'b0;
	DP0_dataB = 1'b0;
	DP0_write_enB = 1'b0;
	DP1_addressA = 1'b0;
	DP1_dataA = 1'b0;
	DP1_write_enA = 1'b0;
	DP1_addressB = 1'b0;
	DP1_dataB = 1'b0;
	DP1_write_enB = 1'b0;
	if (top_state == S_UART_RX) begin
		SRAM_address = UART_SRAM_address;
		SRAM_write_data = UART_SRAM_write_data;
		SRAM_we_n = UART_SRAM_we_n;
	end
	else if (top_state == S_US_CSC) begin
		SRAM_address = US_CSC_SRAM_address;
		SRAM_write_data = US_CSC_SRAM_write_data;
		SRAM_we_n = US_CSC_SRAM_we_n;
	end
	else if (top_state == S_IDCT) begin
		SRAM_address = IDCT_SRAM_address;
		SRAM_write_data = IDCT_SRAM_write_data;
		SRAM_we_n = IDCT_SRAM_we_n;
		DP0_addressA = IDCT_DP0_addressA;
		DP0_dataA = IDCT_DP0_write_dataA;
		DP0_write_enA = IDCT_DP0_write_enA;
		DP0_addressB = IDCT_DP0_addressB;
		DP0_dataB = IDCT_DP0_write_dataB;
		DP0_write_enB = IDCT_DP0_write_enB;
		DP1_addressA = IDCT_DP1_addressA;
		DP1_dataA = IDCT_DP1_write_dataA;
		DP1_write_enA = IDCT_DP1_write_enA;
		DP1_addressB = IDCT_DP1_addressB;
		DP1_dataB = IDCT_DP1_write_dataB;
		DP1_write_enB = IDCT_DP1_write_enB;
		
	end
	else if (top_state == S_LD_DQ) begin
		SRAM_address = LD_DQ_SRAM_address;
		SRAM_write_data = LD_DQ_SRAM_write_data;
		SRAM_we_n = LD_DQ_SRAM_we_n;
	end
	
end 


// 7 segment displays
convert_hex_to_seven_segment unit7 (
	.hex_value(SRAM_read_data[15:12]), 
	.converted_value(value_7_segment[7])
);

convert_hex_to_seven_segment unit6 (
	.hex_value(SRAM_read_data[11:8]), 
	.converted_value(value_7_segment[6])
);

convert_hex_to_seven_segment unit5 (
	.hex_value(SRAM_read_data[7:4]), 
	.converted_value(value_7_segment[5])
);

convert_hex_to_seven_segment unit4 (
	.hex_value(SRAM_read_data[3:0]), 
	.converted_value(value_7_segment[4])
);

convert_hex_to_seven_segment unit3 (
	.hex_value({2'b00, SRAM_address[17:16]}), 
	.converted_value(value_7_segment[3])
);

convert_hex_to_seven_segment unit2 (
	.hex_value(SRAM_address[15:12]), 
	.converted_value(value_7_segment[2])
);

convert_hex_to_seven_segment unit1 (
	.hex_value(SRAM_address[11:8]), 
	.converted_value(value_7_segment[1])
);

convert_hex_to_seven_segment unit0 (
	.hex_value(SRAM_address[7:4]), 
	.converted_value(value_7_segment[0])
);

assign   
   SEVEN_SEGMENT_N_O[0] = value_7_segment[0],
   SEVEN_SEGMENT_N_O[1] = value_7_segment[1],
   SEVEN_SEGMENT_N_O[2] = value_7_segment[2],
   SEVEN_SEGMENT_N_O[3] = value_7_segment[3],
   SEVEN_SEGMENT_N_O[4] = value_7_segment[4],
   SEVEN_SEGMENT_N_O[5] = value_7_segment[5],
   SEVEN_SEGMENT_N_O[6] = value_7_segment[6],
   SEVEN_SEGMENT_N_O[7] = value_7_segment[7];

assign LED_GREEN_O = {resetn, VGA_enable, ~SRAM_we_n, Frame_error, UART_rx_initialize, PB_pushed};

endmodule
