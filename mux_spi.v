`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:30:37 11/13/2016 
// Design Name: 
// Module Name:    mux_spi 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module mux_spi(
	   input clk_i,
		input resetn,
		input select,
		
		//ENTRADA RPI3
		input  i_mosi,
		input  i_ss,
		input  i_sck,
		output reg o_miso,
		
		//SALIDA MATRIX-CORE
		output reg o_mosi_1,
		output reg o_ss_1,
		output reg o_sck_1,
		input  i_miso_1,
		
		//SALIDA NFC MODULE
		output reg o_mosi_2,
		output reg o_ss_2,
		output reg o_sck_2,
		input  i_miso_2
    );

always @(*)begin
  if (select)
		begin
			o_miso = i_miso_2;
			
			o_mosi_1 = i_mosi;
			o_ss_1 = i_ss;
			o_sck_1 = i_sck;
			
			o_mosi_2 = 0;
			o_ss_2 = i_ss;
			o_sck_2 = i_sck;
		end
  else
		begin
			o_miso = i_miso_2;
			
			o_mosi_2 = i_mosi;
			o_ss_2 = i_ss;
			o_sck_2 = i_sck;
			
			o_mosi_1 = 0;
			o_ss_1 = i_ss;
			o_sck_1 = i_sck;
		end
end


endmodule 