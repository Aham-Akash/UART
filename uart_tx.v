// This file contains the UART Transmitter.  This transmitter is able
// to transmit 8 bits of serial data, one start bit, one stop bit,
// and no parity bit.  When transmit is complete o_Tx_done will be
// driven high for one clock cycle.
//
// Set Parameter CLKS_PER_BIT as follows:
// CLKS_PER_BIT = (Frequency of i_Clock)/(Frequency of UART)
// Example: 10 MHz Clock, 5MHz baud UART
// (10000000)/(50000000) = 2

module uart_tx 
	#(parameter CLKS_PER_BIT = 2) 
	(
   input       i_Clock,		
   input       i_Tx_DV,
   input [7:0] i_Tx_Byte, 
   output      o_Tx_Active,
   output      o_Tx_Done,
   output reg  o_Tx_Serial
);

   // State Definitions
   parameter s_TX_IDLE       = 2'b00;
   parameter s_TX_START_BIT  = 2'b01;
   parameter s_TX_DATA_BITS  = 2'b10;
   parameter s_TX_STOP_BIT   = 2'b11;
	
   // Internal Registers
   reg [1:0]   r_SM_Main      = 0;    			 // Current state
   reg [1:0]   r_SM_Next;                     // Next state
   reg [7:0]   r_Clock_Count  = 0;            // Clock counter
   reg [2:0]   r_Bit_Index    = 0;            // Bit index for serial-to-parallel conversion
   reg [7:0]   r_Tx_Data      = 0;            // Data to transmit
   reg         r_Tx_Done      = 0;            // Done flag
   reg         r_Tx_Active    = 0;            // Active flag

   // State Transition
   always @(posedge i_Clock) begin
      r_SM_Main <= r_SM_Next;
   end

   // Next State Logic
   always_comb begin
      case (r_SM_Main)
         s_TX_IDLE: begin
            o_Tx_Serial 	= 1'b1;  // Line idle state
            r_Tx_Done 		= 0;
            r_Clock_Count 	= 0;
            r_Bit_Index 	= 0;

            if (i_Tx_DV == 1'b1) begin
               r_Tx_Active = 1;
               r_Tx_Data 	= i_Tx_Byte;
               r_SM_Next 	= s_TX_START_BIT;
            end else begin
               r_SM_Next 	= s_TX_IDLE;
            end
         end //case: s_TX_IDLE

         s_TX_START_BIT: begin
            o_Tx_Serial = 1'b0;  // Start bit
				
            if (r_Clock_Count < CLKS_PER_BIT - 1) begin
               r_Clock_Count 	= r_Clock_Count + 1;
               r_SM_Next 		= s_TX_START_BIT;
            end 
				else begin
               r_Clock_Count 	= 0;
               r_SM_Next 		= s_TX_DATA_BITS;
            end
         end //case: s_TX_START_BIT

         s_TX_DATA_BITS: begin
            o_Tx_Serial 		= r_Tx_Data[r_Bit_Index];  // Transmit data bit
				
            if (r_Clock_Count < CLKS_PER_BIT - 1) begin
               r_Clock_Count 	= r_Clock_Count + 1;
               r_SM_Next 		= s_TX_DATA_BITS;
            end 
				else begin
               r_Clock_Count 	= 0;
               if (r_Bit_Index < 7) begin
                  r_Bit_Index = r_Bit_Index + 1;
                  r_SM_Next 	= s_TX_DATA_BITS;
               end else begin
                  r_Bit_Index = 0;
                  r_SM_Next = s_TX_STOP_BIT;
               end
            end
         end //case: s_TX_DATA_BITS

         s_TX_STOP_BIT: begin
            o_Tx_Serial 		= 1'b1;  // Stop bit
				
            if (r_Clock_Count < CLKS_PER_BIT - 1) begin
               r_Clock_Count 	= r_Clock_Count + 1;
               r_SM_Next 		= s_TX_STOP_BIT;
            end 
				else begin
               r_Tx_Done 		= 1;
               r_Clock_Count 	= 0;
               r_Tx_Active 	= 0;
               r_SM_Next 		= s_TX_IDLE;
            end
         end //case: s_TX_STOP_BIT

         default: r_SM_Next = s_TX_IDLE;
      endcase
   end

   // Output Assignments
   assign o_Tx_Active 	= r_Tx_Active;
   assign o_Tx_Done 		= r_Tx_Done;

endmodule
