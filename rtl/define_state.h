`ifndef DEFINE_STATE

parameter DP_SRAM_SELECT = 1'b1;

// for top state - we have more states than needed
typedef enum logic [3:0] {
	S_IDLE,
	S_UART_RX,
	S_US_CSC,
	S_IDCT,
	S_LD_DQ
	
} top_state_type;

typedef enum logic [4:0] {
	S_US_CSC_IDLE,
	S_US_CSC_LEADIN_NEW_ROW,
	S_US_CSC_LEADIN_DELAY_0,
	S_US_CSC_LEADIN_DELAY_1,
	S_US_CSC_LEADIN_MULTI_U_0,
	S_US_CSC_LEADIN_MULTI_U_1,
	S_US_CSC_LEADIN_MULTI_V_0,
	S_US_CSC_LEADIN_MULTI_V_1,
	S_US_CSC_LEADIN_YUV_PRIME,
	S_US_CSC_LEADIN_RB,
	S_US_CSC_WRITE_0,
	S_US_CSC_READ_Y,
	S_US_CSC_READ_U,
	S_US_CSC_WRITE_1,
	S_US_CSC_WRITE_2,
	S_US_CSC_READ_V,
	S_US_CSC_DELAY,
	S_US_CSC_END
	
} US_CSC_state_type;

parameter BITSTREAM_START_ADDRESS = 18'd0;

typedef enum logic [3:0] {
	S_LD_DQ_IDLE,
	S_LD_DQ_LEADIN_0,
	S_LD_DQ_LEADIN_1,
	S_LD_DQ_LEADIN_2,
	S_LD_DQ_LEADIN_3,
	S_LD_DQ_LEADIN_4,
	S_LD_DQ_LEADIN_5,
	S_LD_DQ_LEADIN_6,
	S_LD_DQ_WAIT_FOR_NEW_BLOCK,
	S_LD_DQ_READ_HEADER,
	S_LD_DQ_WRITE,
	S_LD_DQ_FINISH_BLOCK
	
} LD_DQ_state_type;



parameter 
	U_START_ADDRESS = 18'd38400,
	V_START_ADDRESS = 18'd57600,
	Y_START_ADDRESS = 18'd0,
	RGB_START_ADRRESS = 18'd146944;
	


typedef enum logic [5:0] {
	S_IDCT_IDLE,
	S_IDCT_LEADIN0,
	S_IDCT_LEADIN_DELAY1,
	S_IDCT_LEADIN_WRITE,
	S_IDCT_LEADIN_DELAY2,
	S_IDCT_LEADIN_DELAY3,
	S_IDCT_LEADIN_DELAY4,
	S_IDCT_S_PRIME0,
	S_IDCT_S_PRIME1,
	S_IDCT_S_PRIME2,
	S_IDCT_S_PRIME_MULTI1,
	S_IDCT_S_PRIME_MULTI2,
	S_IDCT_S_PRIME_STORE1,
	S_IDCT_S_PRIME_STORE2,
	S_IDCT_S_PRIME_DELAY1,
	S_IDCT_S_PRIME_DELAY2,
	S_IDCT_T0,
	S_IDCT_T1,
	S_IDCT_T2,
	S_IDCT_T_MULTI1,
	S_IDCT_T_MULTI2,
	S_IDCT_T_STORE1,
	S_IDCT_T_STORE2,
	S_IDCT_T_DELAY1,
	S_IDCT_T_DELAY2,
	S_IDCT_LEADOUT0,
	S_IDCT_LEADOUT1,
	S_IDCT_END
} IDCT_state_type;

parameter
	preIDCT_START_ADDRESS = 18'd76800;

typedef enum logic [1:0] {
	S_RXC_IDLE,
	S_RXC_SYNC,
	S_RXC_ASSEMBLE_DATA,
	S_RXC_STOP_BIT
} RX_Controller_state_type;

typedef enum logic [2:0] {
	S_US_IDLE,
	S_US_STRIP_FILE_HEADER_1,
	S_US_STRIP_FILE_HEADER_2,
	S_US_START_FIRST_BYTE_RECEIVE,
	S_US_WRITE_FIRST_BYTE,
	S_US_START_SECOND_BYTE_RECEIVE,
	S_US_WRITE_SECOND_BYTE
} UART_SRAM_state_type;

typedef enum logic [3:0] {
	S_VS_WAIT_NEW_PIXEL_ROW,
	S_VS_NEW_PIXEL_ROW_DELAY_1,
	S_VS_NEW_PIXEL_ROW_DELAY_2,
	S_VS_NEW_PIXEL_ROW_DELAY_3,
	S_VS_NEW_PIXEL_ROW_DELAY_4,
	S_VS_NEW_PIXEL_ROW_DELAY_5,
	S_VS_FETCH_PIXEL_DATA_0,
	S_VS_FETCH_PIXEL_DATA_1,
	S_VS_FETCH_PIXEL_DATA_2,
	S_VS_FETCH_PIXEL_DATA_3
} VGA_SRAM_state_type;

parameter 
   VIEW_AREA_LEFT = 160,
   VIEW_AREA_RIGHT = 480,
   VIEW_AREA_TOP = 120,
   VIEW_AREA_BOTTOM = 360;
	
`define DEFINE_STATE 1
`endif
