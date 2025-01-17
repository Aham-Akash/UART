// This file contains the UART Receiver.  This receiver is able to
// receive 8 bits of serial data, one start bit, one stop bit,
// and no parity bit.  When receive is complete o_Rx_Done will be
// driven high for one clock cycle.
// 
// Set Parameter CLKS_PER_BIT as follows:
// CLKS_PER_BIT = (Frequency of i_Clock)/(Frequency of UART)
// Example: 10 MHz Clock, 115200 baud UART
// (10000000)/(115200) = 87

module uart_rx 
	#(parameter CLKS_PER_BIT = 87) 
	(
   input           i_Clock,
   input           i_Rx_Serial,
   output          o_Rx_Active,
   output          o_Rx_Done,
   output [7:0]    o_Rx_Byte
);

   // Internal Registers
   reg [1:0]   r_SM_Main      = 0;   			// Present state
   reg [1:0]   r_SM_Next;                    // Next state
   reg [7:0]   r_Clock_Count  = 0;           // Clock counter
   reg [2:0]   r_Bit_Index    = 0;           // Bit index for serial-to-parallel conversion
   reg [7:0]   r_Rx_Data      = 0;           // Received byte
   reg         r_Rx_Done      = 0;           // Done flag
   reg         r_Rx_Active    = 0;           // Active flag
	
   // State Definitions
   parameter s_RX_IDLE       = 2'b00;
   parameter s_RX_START_BIT  = 2'b01;
   parameter s_RX_DATA_BITS  = 2'b10;
   parameter s_RX_STOP_BIT   = 2'b11;

   // State Transition
   always @(posedge i_Clock) begin
      r_SM_Main <= r_SM_Next;
   end

   // Next State and Combinational Logic
   always_comb begin
      case (r_SM_Main)
         s_RX_IDLE: begin
            r_Rx_Done 	= 0;
            r_Rx_Data 	= 0;
            r_Rx_Active = 1;
				
            if (i_Rx_Serial == 0) 
               r_SM_Next = s_RX_START_BIT;
            else 
               r_SM_Next = s_RX_IDLE;
         end //case: s_RX_IDLE

         s_RX_START_BIT: begin
            if (r_Clock_Count < CLKS_PER_BIT - 1) begin
               r_Clock_Count 	= r_Clock_Count + 1;
               r_SM_Next 		= s_RX_START_BIT;
            end
            else begin
               r_Clock_Count = 0;
               r_SM_Next 		= s_RX_DATA_BITS;
            end
         end //case: s_RX_START_BIT

         s_RX_DATA_BITS: begin
            r_Rx_Data[r_Bit_Index] 	= i_Rx_Serial;
				
            if (r_Clock_Count < CLKS_PER_BIT - 1) begin
               r_Clock_Count 			= r_Clock_Count + 1;
               r_SM_Next 				= s_RX_DATA_BITS;
            end
            else begin
               r_Clock_Count 			= 0;
               if (r_Bit_Index < 7) begin
                  r_Bit_Index 		= r_Bit_Index + 1;
                  r_SM_Next 			= s_RX_DATA_BITS;
               end
               else begin
                  r_Bit_Index 		= 0;
                  r_SM_Next 			= s_RX_STOP_BIT;
               end
            end
         end //case: s_RX_DATA_BITS

         s_RX_STOP_BIT: begin
            if (i_Rx_Serial == 1) begin
               if (r_Clock_Count < CLKS_PER_BIT - 1) begin
                  r_Clock_Count 	= r_Clock_Count + 1;
                  r_SM_Next 		= s_RX_STOP_BIT;
               end
               else begin
                  r_Clock_Count 	= 0;
                  r_Rx_Active 	= 0;
                  r_Rx_Done 		= 1;
                  r_SM_Next 		= s_RX_IDLE;
               end
            end
         end //case: s_RX_STOP_BIT

         default: r_SM_Next = s_RX_IDLE;
      endcase
   end

   // Output Assignments
   assign o_Rx_Byte 		= r_Rx_Data;
   assign o_Rx_Active 	= r_Rx_Active;
   assign o_Rx_Done 		= r_Rx_Done;

endmodule 