# activate waveform simulation

view wave

# format signal names in waveform

configure wave -signalnamewidth 1
configure wave -timeline 0
configure wave -timelineunits us

# add signals to waveform

add wave -divider -height 20 {Top-level signals}
#add wave -bin UUT/CLOCK_50_I
#add wave -bin UUT/resetn
add wave UUT/top_state
add wave -uns UUT/UART_timer

add wave -divider -height 10 {SRAM signals}
add wave -uns UUT/SRAM_address
add wave -hex UUT/SRAM_write_data
add wave -bin UUT/SRAM_we_n
add wave -hex UUT/SRAM_read_data

#add wave -divider -height 10 {VGA signals}
#add wave -bin UUT/VGA_unit/VGA_HSYNC_O
#add wave -bin UUT/VGA_unit/VGA_VSYNC_O
#add wave -uns UUT/VGA_unit/pixel_X_pos
#add wave -uns UUT/VGA_unit/pixel_Y_pos
#add wave -hex UUT/VGA_unit/VGA_red
#add wave -hex UUT/VGA_unit/VGA_green
#add wave -hex UUT/VGA_unit/VGA_blue

#add wave -divider -height 10 {M1 signals}
#add wave UUT/US_CSC_unit/US_CSC_state
#add wave -uns UUT/US_CSC_unit/write_address_counter
#add wave -uns UUT/US_CSC_unit/read_address_counter
#add wave -uns UUT/US_CSC_unit/U_buf
#add wave -uns UUT/US_CSC_unit/V_buf
#add wave -uns UUT/US_CSC_unit/U_21
#add wave -uns UUT/US_CSC_unit/U_52
#add wave -uns UUT/US_CSC_unit/U_159
#add wave -uns UUT/US_CSC_unit/V_21
#add wave -uns UUT/US_CSC_unit/V_52
#add wave -uns UUT/US_CSC_unit/V_159
#add wave -uns UUT/US_CSC_unit/Y_prime
#add wave -uns UUT/US_CSC_unit/U_prime
#add wave -uns UUT/US_CSC_unit/V_prime
#add wave -dec UUT/US_CSC_unit/Multi0_out
#add wave -dec UUT/US_CSC_unit/Multi1_out
#add wave -dec UUT/US_CSC_unit/Multi2_out
#add wave -uns UUT/US_CSC_unit/R
#add wave -uns UUT/US_CSC_unit/G
#add wave -uns UUT/US_CSC_unit/B

add wave -divider -height 10 {M2 signals}
add wave UUT/IDCT_unit/IDCT_state
add wave -bin UUT/IDCT_unit/Y_complete
add wave -uns UUT/IDCT_unit/DataBlock_I_index
add wave -uns UUT/IDCT_unit/DataBlock_J_index
add wave -uns UUT/IDCT_unit/DataBlock_I_index_buf
add wave -uns UUT/IDCT_unit/DataBlock_J_index_buf
add wave -uns UUT/IDCT_unit/SRAM_write_counterI
add wave -uns UUT/IDCT_unit/SRAM_write_counterJ
add wave -uns UUT/IDCT_unit/SRAM_read_address_counter_I
add wave -uns UUT/IDCT_unit/SRAM_read_address_counter_J

add wave -uns UUT/IDCT_unit/I_index
add wave -uns UUT/IDCT_unit/J_index
add wave -uns UUT/IDCT_unit/Matrix_counter
add wave -uns UUT/IDCT_unit/I_index_buf
add wave -uns UUT/IDCT_unit/J_index_buf
add wave -dec UUT/IDCT_unit/Sprime_T_buf0
add wave -dec UUT/IDCT_unit/Sprime_T_buf1
add wave -dec UUT/IDCT_unit/Sum_register0
add wave -dec UUT/IDCT_unit/Sum_register1
add wave -dec UUT/IDCT_unit/Sum_register2
add wave -dec UUT/IDCT_unit/Sum_register3
add wave -dec UUT/IDCT_unit/C_buf_0
add wave -dec UUT/IDCT_unit/C_buf_1
add wave -dec UUT/IDCT_unit/Multi0_out
add wave -dec UUT/IDCT_unit/Multi1_out
add wave -divider -height 10 {DP0}
add wave -uns UUT/IDCT_unit/DP0_addressA
add wave -dec UUT/IDCT_unit/DP0_write_dataA
add wave -bin UUT/IDCT_unit/DP0_write_enA
add wave -dec UUT/IDCT_unit/DP0_read_dataA
add wave -uns UUT/IDCT_unit/DP0_addressB
add wave -dec UUT/IDCT_unit/DP0_write_dataB
add wave -bin UUT/IDCT_unit/DP0_write_enB
add wave -dec UUT/IDCT_unit/DP0_read_dataB
add wave -divider -height 10 {DP1}
add wave -uns UUT/IDCT_unit/DP1_addressA
add wave -dec UUT/IDCT_unit/DP1_write_dataA
add wave -bin UUT/IDCT_unit/DP1_write_enA
add wave -dec UUT/IDCT_unit/DP1_read_dataA
add wave -uns UUT/IDCT_unit/DP1_addressB
add wave -dec UUT/IDCT_unit/DP1_write_dataB
add wave -bin UUT/IDCT_unit/DP1_write_enB
add wave -dec UUT/IDCT_unit/DP1_read_dataB


add wave -divider -height 10 {M3 signals}
add wave UUT/LD_DQ_unit/LD_DQ_state
#add wave -uns UUT/LD_DQ_unit/q
add wave -uns UUT/LD_DQ_unit/total_block
add wave -uns UUT/LD_DQ_unit/block_counter
add wave -uns UUT/LD_DQ_unit/ZZ_counter
add wave -uns UUT/LD_DQ_unit/bitstream_counter
add wave -bin UUT/LD_DQ_unit/bitstream
add wave -uns UUT/LD_DQ_unit/bit_num
add wave -uns UUT/LD_DQ_unit/bit_size
#add wave -hex UUT/LD_DQ_unit/write_bit_acc
#add wave -dec UUT/LD_DQ_unit/write_data

#add wave -uns UUT/LD_DQ_unit/write_bit
#add wave -uns UUT/LD_DQ_unit/write_data_acc


add wave -hex UUT/LD_DQ_unit/read_address_counter
add wave -bin UUT/LD_DQ_unit/added_value
add wave -hex UUT/LD_DQ_unit/write_to_buf
add wave -hex UUT/LD_DQ_unit/bitstream_buf

#add wave -uns UUT/LD_DQ_unit/block_col
#add wave -uns UUT/LD_DQ_unit/block_row

#add wave -uns UUT/LD_DQ_unit/DP_we_n_a
#add wave -hex UUT/LD_DQ_unit/DP_write_data_a
#add wave -uns UUT/LD_DQ_unit/DP_address_a
