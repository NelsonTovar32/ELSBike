/*
 * Copyright 2016 <Admobilize>
 * MATRIX Labs  [http://creator.matrix.one]
 * This file is part of MATRIX Creator HDL for Spartan 6
 *
 * MATRIX Creator HDL is like free software: you can redistribute 
 * it and/or modify it under the terms of the GNU General Public License 
 * as published by the Free Software Foundation, either version 3 of the 
 * License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful, but 
 * WITHOUT ANY WARRANTY; without even the implied warranty of 
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU 
 * General Public License for more details.

 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

module system 
#(
  parameter   bootram_file     = "image1.ram",
  parameter   everloop_file    = "image2.ram",
  parameter   GPIO_WIDTH       = 1

)(
  input  clk_50,
  input  resetn,
  input  control, //Control de multiplexor de SPI
  
  /* RASPBERRY's LCD interface */
  //RPI-FPGA (LCD)
  input e_i,
  input rs_i,
  input [3:0]data_lcd_i,
  //FPGA-LCD
  output e_o,
  output rs_o,
  output [3:0]data_lcd_o,

  /* RASPBERRY's SPI interface */
  input  mosi,
  input  ss,
  input  sck,
  output miso,
  
  /* RASPBERRY's UART interface */
  input       UART_RX_PI,     
  output      UART_TX_PI,

  /* NFC's SPI interface */
  input  nfc_miso,
  output nfc_mosi,
  output nfc_cs,
  output nfc_sck,
  output nfc_rst,		//Conectado con PI_RST(IN)
  input  nfc_irq,     //Conectado con IRQ_NFC(OUT) 
  
  /* Everloop */
  output everloop_ctl,
      
  /* MCU SAM */
  input  mcu_nwe,
  input  mcu_ncs,
  input  mcu_nrd,
  input  [10:0] mcu_addr, //TODO(andres.calderon): parameterize
  inout  [7:0]  mcu_sram_data, //TODO(andres.calderon): parameterize
 
  /* IR */
  output IRQ_NFC,   //Conectado con nfc_irq(in)
  input PI_RST,		//Conectado con nfc_rst(out)

  /* GPIO */
  inout [GPIO_WIDTH-1:0] gpio_io,
  
  //UART - MODULO BLUETOOTH HC-05 
  input       Z_RX,        
  output      Z_TX,

  
  /* Debug */
  output  debug_led
);

//Set up lEDBUG
assign debug_led  = control;//~RX_IR

//Set up UART-HC-05
assign Z_TX   = UART_RX_PI;
assign UART_TX_PI = Z_RX;

//Set up LCD bridge
assign e_o = e_i;
assign rs_o = rs_i;
assign data_lcd_o = data_lcd_i;

wire clk;
wire nclk;
wire clk_25;

creator_dcm dcm
(
  .clkin(clk_50),

  .clk_out_200(clk),
  .nclk_out_200(nclk),
  .clk_out_25()
);

wire mosi_0;
wire ss_0;
wire sck_0;
wire miso_0;

//---------------------------------------------------------------------------
// MULTIPLEXOR SPI INTERFACE 
//---------------------------------------------------------------------------

mux_spi mux_connector(
	.clk_i(clk),
	.resetn(resetn),
	.select(control),
	//RPI-SPI-INTERFACE
	.i_mosi(mosi),
	.i_ss(ss),
	.i_sck(sck),
	.o_miso(miso),		
	//SALIDA MATRIX-CORE
	.o_mosi_1(mosi_0),
	.o_ss_1(ss_0),
	.o_sck_1(sck_0),
	.i_miso_1(miso_0),
	//SALIDA NFC MODULE
	.o_mosi_2(nfc_mosi),
	.o_ss_2(nfc_cs),
	.o_sck_2(nfc_sck),
	.i_miso_2(nfc_miso)
);

	    

//------------------------------------------------------------------
// Whishbone Wires
//------------------------------------------------------------------
wire         gnd   =  1'b0;
wire   [1:0] gnd2  =  4'h0;
wire  [15:0] gnd16 = 16'h0000;
wire  [13:0] gnd14 = 14'h0000;
 
wire [13:0]  spi0_adr,
             mcu_bram_adr,
             uart0_adr,
             uart1_adr,
             bram0_adr,
             gpio0_adr,
             spi1_adr,
             everloop_adr;


wire [15:0]  spi0_dat_r,
             spi0_dat_w,
             mcu_bram_r,
             mcu_bram_w,
             uart0_dat_r,
             uart0_dat_w,
             uart1_dat_r,
             uart1_dat_w,
             bram0_dat_r,
             bram0_dat_w,
             gpio0_dat_r,
             gpio0_dat_w,
             spi1_dat_r,
             spi1_dat_w,
             everloop_dat_r,
             everloop_dat_w;


wire [1:0]   spi0_sel,
             mcu_bram_sel,
             uart0_sel,
             uart1_sel,
             bram0_sel,
             gpio0_sel,
             spi1_sel,
             everloop_sel;

wire         spi0_we,
             mcu_bram_we,
             uart0_we,
             uart1_we,
             bram0_we,
             gpio0_we,
             spi1_we,
             everloop_we;


wire         spi0_cyc,
             mcu_bram_cyc,
             uart0_cyc,
             uart1_cyc,
             bram0_cyc,
             gpio0_cyc,
             spi1_cyc,
             everloop_cyc;


wire         spi0_stb,
             mcu_bram_stb,
             uart0_stb,
             uart1_stb,
             bram0_stb,
             gpio0_stb,
             spi1_stb,
             everloop_stb;


//---------------------------------------------------------------------------
// Wishbone Interconnect
//---------------------------------------------------------------------------
conbus #(
  .s_addr_w(4),
  .s0_addr(4'b0000),  // bram          00 0000 0000 0000 0x0000
  .s1_addr(4'b0010),  // uart0         00 1000 0000 0000 0x0800
  .s2_addr(4'b0100),  // uart1         01 0000 0000 0000 0x1000
  .s3_addr(4'b0110),  // mic_array     01 1000 0000 0000 0x1800
  .s4_addr(4'b1000),  // everloop0     10 0000 0000 0000 0x2000
  .s5_addr(4'b1010),  // gpio0         10 1000 0000 0000 0x2800
  .s6_addr(4'b1100),  // spi0          11 0000 0000 0000 0x3000
  .s7_addr(4'b1110)   // mcu_bram      11 1000 0000 0000 0x3800
) conbus0(
  .sys_clk(clk),
  .sys_rst(resetn),
  // Master0
  .m0_dat_i(spi0_dat_r),
  .m0_dat_o(spi0_dat_w),
  .m0_adr_i(spi0_adr),
  .m0_we_i (spi0_we),
  .m0_sel_i(gnd2  ),
  .m0_cyc_i(spi0_cyc),
  .m0_stb_i(spi0_stb),
  .m0_cti_i(3'b000),
  // Master1
  .m1_dat_i(gnd16),
  .m1_adr_i(gnd14),
  .m1_sel_i(gnd2),
  .m1_cyc_i(gnd),
  .m1_stb_i(gnd),
  // Master2
  .m2_dat_i(gnd16),
  .m2_adr_i(gnd14),
  .m2_sel_i(gnd2),
  .m2_cyc_i(gnd),
  .m2_stb_i(gnd),
  // Master3
  .m3_dat_i(gnd16),
  .m3_adr_i(gnd14),
  .m3_sel_i(gnd2),
  .m3_cyc_i(gnd),
  .m3_stb_i(gnd),
  // Master4
  .m4_dat_i(gnd16),
  .m4_adr_i(gnd14),
  .m4_sel_i(gnd2),
  .m4_cyc_i(gnd),
  .m4_stb_i(gnd),
  // Master5
  .m5_dat_i(gnd16),
  .m5_adr_i(gnd14),
  .m5_sel_i(gnd2),
  .m5_cyc_i(gnd),
  .m5_stb_i(gnd),
  // Master6
  .m6_dat_i(gnd16),
  .m6_adr_i(gnd14),
  .m6_sel_i(gnd2),
  .m6_cyc_i(gnd),
  .m6_stb_i(gnd),

  // Slave0  bram
  .s0_dat_i(bram0_dat_r),
  .s0_dat_o(bram0_dat_w),
  .s0_adr_o(bram0_adr),
  .s0_sel_o(bram0_sel),
  .s0_we_o(bram0_we),
  .s0_cyc_o(bram0_cyc),
  .s0_stb_o(bram0_stb),

  // Slave1
  .s1_dat_i(uart0_dat_r),
  .s1_dat_o(uart0_dat_w),
  .s1_adr_o(uart0_adr),
  .s1_sel_o(uart0_sel),
  .s1_we_o(uart0_we),
  .s1_cyc_o(uart0_cyc),
  .s1_stb_o(uart0_stb),
	
  // Slave2
  .s2_dat_i(uart1_dat_r),
  .s2_dat_o(uart1_dat_w),
  .s2_adr_o(uart1_adr),
  .s2_sel_o(uart1_sel),
  .s2_we_o(uart1_we),
  .s2_cyc_o(uart1_cyc),
  .s2_stb_o(uart1_stb),

  // Slave3  mic_array
  .s3_dat_i(),
  .s3_dat_o(),
  .s3_adr_o(),
  .s3_sel_o(),
  .s3_we_o(),
  .s3_cyc_o(),
  .s3_stb_o(),

  // Slave4  mic_array
  .s4_dat_i(everloop_dat_r),
  .s4_dat_o(everloop_dat_w),
  .s4_adr_o(everloop_adr),
  .s4_sel_o(everloop_sel),
  .s4_we_o(everloop_we),
  .s4_cyc_o(everloop_cyc),
  .s4_stb_o(everloop_stb),

  // Slave5
  .s5_dat_i(gpio0_dat_r),
  .s5_dat_o(gpio0_dat_w),
  .s5_adr_o(gpio0_adr),
  .s5_sel_o(gpio0_sel),
  .s5_we_o(gpio0_we),
  .s5_cyc_o(gpio0_cyc),
  .s5_stb_o(gpio0_stb),

  /*/ Slave6
  .s6_dat_i(spi1_dat_r),
  .s6_dat_o(spi1_dat_w),
  .s6_adr_o(spi1_adr),
  .s6_sel_o(spi1_sel),
  .s6_we_o(spi1_we),
  .s6_cyc_o(spi1_cyc),
  .s6_stb_o(spi1_stb),*/
  
    // Slave6
  .s6_dat_i(),
  .s6_dat_o(),
  .s6_adr_o(),
  .s6_sel_o(),
  .s6_we_o(),
  .s6_cyc_o(),
  .s6_stb_o(),


  // Slave7
  .s7_dat_i(mcu_bram_r),
  .s7_dat_o(mcu_bram_w),
  .s7_adr_o(mcu_bram_adr),
  .s7_sel_o(mcu_bram_sel),
  .s7_we_o(mcu_bram_we),
  .s7_cyc_o(mcu_bram_cyc),
  .s7_stb_o(mcu_bram_stb)
);


//---------------------------------------------------------------------------
// RASPBERRY's SPI INTERFACE 
//---------------------------------------------------------------------------
spi2ad_bus #(
  .ADDR_WIDTH(14),
  .DATA_WIDTH(16)
)  spi0(
  .clk(clk), 
  .resetn(resetn),

  .mosi(mosi_0), 
  .ss(ss_0), 
  .sck(sck_0), 
  .miso(miso_0),

  .data_bus_out(spi0_dat_r),  
  .data_bus_in(spi0_dat_w), 
  .addr_bus(  spi0_adr),
  .strobe(    spi0_stb),
  .cycle(     spi0_cyc),
  .wr(        spi0_we)
);


//---------------------------------------------------------------------------
// Block RAM
//---------------------------------------------------------------------------
wb_bram #(
  .adr_width(10),
  .mem_file_name(bootram_file)
) bram0 (
  .clk_i(clk),

  .wb_adr_i(bram0_adr),
  .wb_dat_o(bram0_dat_r),
  .wb_dat_i(bram0_dat_w),
  .wb_sel_i(bram0_sel),
  .wb_stb_i(bram0_stb),
  .wb_cyc_i(bram0_cyc),
  .wb_we_i(bram0_we)
);


wb_mcu_bram mcu_bram0(
  //Wishbone interface
  .clk_i(clk), 
  .wb_adr_i(mcu_bram_adr),
  .wb_dat_o(mcu_bram_r),
  .wb_dat_i(mcu_bram_w),
  .wb_sel_i(mcu_bram_sel),
  .wb_stb_i(mcu_bram_stb),
  .wb_cyc_i(mcu_bram_cyc),
  .wb_we_i(mcu_bram_we),

   //MCU SAM
  .mcu_clk(nclk),
  .mcu_nwe(mcu_nwe),
  .mcu_ncs(mcu_ncs),
  .mcu_nrd(mcu_nrd),
  .mcu_addr(mcu_addr),
  .mcu_sram_data(mcu_sram_data)
);


//---------------------------------------------------------------------------
// Everloop
//---------------------------------------------------------------------------
//wire debug_led_out;

//assign everloop_ctl = (debug_led_out) ? 1'bz : 1'b0;

wb_everloop#(
.mem_file_name(everloop_file)  
) everloop0(
  
  .clk(clk),.nrst(resetn),
     
  // Wishbone interface
  .wb_stb_i(everloop_stb),
  .wb_cyc_i(everloop_cyc),
  .wb_we_i(everloop_we),
  .wb_adr_i(everloop_adr),
  .wb_sel_i(everloop_sel),
  .wb_dat_i(everloop_dat_w),
  .wb_dat_o(everloop_dat_r) ,
  .everloop_ctl(everloop_ctl) 
);

//---------------------------------------------------------------------------
// GPIO
//---------------------------------------------------------------------------

wb_gpio#(
  .GPIO_WIDTH(GPIO_WIDTH)
) gpio0(
  
  .clk(clk),
  .rst(resetn),
  
  .wb_stb_i(gpio0_stb),
  .wb_cyc_i(gpio0_cyc),
  .wb_we_i(gpio0_we),
  
  .wb_adr_i(gpio0_adr),
  .wb_dat_i(gpio0_dat_w),
  .wb_dat_o(gpio0_dat_r),
  .gpio_io(gpio_io)
);

//---------------------------------------------------------------------------
// NFC's SPI interface
//---------------------------------------------------------------------------

assign IRQ_NFC = nfc_irq; 
assign nfc_rst = PI_RST; 
/*wb_spi spi1 (
	.clk(      clk        ),
	.reset(    resetn     ),
	//
	.wb_adr_i( spi1_adr   ),
	.wb_dat_i( spi1_dat_w ),
	.wb_dat_o( spi1_dat_r ),
	.wb_stb_i( spi1_stb   ),
	.wb_cyc_i( spi1_cyc   ),
	.wb_we_i(  spi1_we    ),
	.spi_sck(  nfc_sck    ),
	.spi_mosi( nfc_mosi   ),
	.spi_miso( nfc_miso   ),
	.spi_cs(   nfc_cs     ),
	.spi_rst(  nfc_rst    )
);*/
endmodule 