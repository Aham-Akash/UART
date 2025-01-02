// This file contains the UART Receiver.  This receiver is able to
// receive 8 bits of serial data, one start bit, one stop bit,
// and no parity bit.  When receive is complete o_Rx_DV will be
// driven high for one clock cycle.
// 
// Set Parameter CLKS_PER_BIT as follows:
// CLKS_PER_BIT = (Frequency of i_Clock)/(Frequency of UART)
// Example: 10 MHz Clock, 115200 baud UART
// (10000000)/(115200) = 87

module uart_rx 
  #(parameter CLKS_PER_BIT = 87)
  (
   input        i_Clock,
   input        i_Rx_Serial,
	output		 o_Rx_Active,
	//output		 o_Rx_Done,
   output       o_Rx_DV,
   output [7:0] o_Rx_Byte
   );
	
	
	 parameter s_IDLE=3'b000;
	 parameter s_RX_START_BIT=3'b001;
	 parameter s_RX_DATA_BITS=3'b010;
	 parameter s_RX_STOP_BIT=3'b011;
	 parameter s_CLEANUP=3'b100;
	 
	 reg [2:0] 	  r_SM_Main		 = 0;
	 reg [7:0]    r_Clock_Count = 0;
	 reg [2:0]    r_Bit_Index   = 0;
	 reg [7:0]	  r_Rx_Data     = 0;
	 reg          r_Rx_Done     = 0;
	 reg          r_Rx_Active   = 0;
	 
	 always @ (posedge i_Clock) 
	 begin
		case(r_SM_MAin) 
			begin
				s_IDLE: 
				begin
						o_Rx_DV       <= 0;         
						r_RX_Done     <= 0;
						r_Clock_Count <= 0;
						r_Bit_Index   <= 0;
						r_Rx_Active   <= 1;
						
						if(i_Rx_Serial==0)
							r_SM_Main <= s_START_BIT;
						else
							r_SM_Main <= s_IDLE;
				end // case: s_IDLE
							
				s_RX_START_BIT: 
				begin
							// Wait CLKS_PER_BIT-1 clock cycles for start bit to finish
							if (r_Clock_Count < CLKS_PER_BIT-1)
							  begin
								 r_Clock_Count <= r_Clock_Count + 1;
								 r_SM_Main     <= s_RX_START_BIT;
							  end
							else
							  begin
								 r_Clock_Count <= 0;
								 r_SM_Main     <= s_RX_DATA_BITS;
							  end
				end // case: s_START_BIT
						  
				s_RX_DATA_BITS: 
				begin
							r_Rx_Data[r_Bit_Index] <= i_Rx_Serial;
							
							if(r_Clock_Count < CLKS_PER_BIT-1)
								begin
									r_CLock_Count = r_Clock_Count + 1;
									r_SM_Main <= s_RX_DATA_BITS;
								end
							
							else
								begin
									r_Clock_Count <= 0;
									
									if(r_Bit_Index < 7)
										begin
											r_Bit_Index = r_Bit_INdex + 1;
											r_SM_Main <= s_RX_DATA_BITS;
										end
									
									else
										begin
											r_Bit_Index <= 0;
											r_SM_Main <= s_STOP_BIT;
										end
								end
				
				end // case: s_DATA_BIT 
				
				s_STOP_BIT: 
				begin
					if (i_Rx_Serial ==1)
					begin
						if(r_CLock_Count < CLKS_PER_BIT-1)
						begin
							r_CLock_Count = r_Clock_Count + 1;
							r_SM_Main <= s_RX_STOP_BIT;
						end
						
						else
						begin
							r_CLock_Count =  0;
							r_SM_Main <= s_RX_CLEANUP;
							r_Rx_Done <= 1;
							r_Rx_Active <= 0;
						end
					end
				
				end //case: s_STOP_BIT
				
				s_CLEANUP:
				begin
					r_Rx_Done <= 0;
					r_SM_Main <= s_IDLE;
				end //case: s_CLEANUP
				
				default:
					r_SM_Main <= s_IDLE;
			
			end
			endcase
	 end	
	 
	 assign o_Rx_Active = r_Rx_Active;
	 assign o_Rx_DV   = r_Rx_Done;
	
	
	endmodule 