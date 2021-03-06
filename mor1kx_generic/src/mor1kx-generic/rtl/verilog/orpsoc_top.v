`include "../../../mor1kx/rtl/verilog/mor1kx-defines.v"

module orpsoc_top
  #(parameter MEM_SIZE = 32'h02000000)
(
	  `ifdef SYNTHESIS
	        output[`OR1K_INSN_WIDTH-1:0]   decode_insn_to_tb,
	  `endif
		input wb_clk_i,
		input wb_rst_i,
		output tdo_pad_o,
		input tms_pad_i,
		input tck_pad_i,
		input tdi_pad_i,
		output [31:0] wb_m2s_mem_adr_sim,
		output [31:0] wb_m2s_mem_dat_sim,
		output [3:0] wb_m2s_mem_sel_sim,
		output wb_m2s_mem_we_sim,
		output wb_m2s_mem_cyc_sim,
		output wb_m2s_mem_stb_sim,
		output [2:0] wb_m2s_mem_cti_sim,
		output [1:0] wb_m2s_mem_bte_sim,
		input [31:0] wb_s2m_mem_dat_sim,
		input wb_s2m_mem_ack_sim,
		input wb_s2m_mem_err_sim,
      //host_ctrl in/out
		input [7:0] hostctrl_data,
		input  hostctrl_done,
		output hostctrl_ack,
      output hostctrl_ack_data,
      input  hostctrl_valid,
	   input  next);

localparam wb_aw = 32;
localparam wb_dw = 32;

////////////////////////////////////////////////////////////////////////
//
// Wishbone interconnect
//
////////////////////////////////////////////////////////////////////////
wire wb_clk = wb_clk_i;
wire wb_rst = wb_rst_i;

`include "wb_intercon.vh"

`ifdef SYNTHESIS
   wire [`OR1K_INSN_WIDTH-1:0]   decode_insn_i;
   assign decode_insn_to_tb = decode_insn_i;
`endif



////////////////////////////////////////////////////////////////////////
//
// Debug Interface
//
////////////////////////////////////////////////////////////////////////
wire [31:0]	or1k_dbg_dat_i;
wire [31:0]	or1k_dbg_adr_i;
wire		or1k_dbg_we_i;
wire		or1k_dbg_stb_i;
wire		or1k_dbg_ack_o;
wire [31:0]	or1k_dbg_dat_o;

wire		or1k_dbg_stall_i;
wire		or1k_dbg_ewt_i;
wire [3:0]	or1k_dbg_lss_o;
wire [1:0]	or1k_dbg_is_o;
wire [10:0]	or1k_dbg_wp_o;
wire		or1k_dbg_bp_o;
wire		or1k_dbg_rst;


adbg_top dbg_if0 (
	// OR1K interface
	.cpu0_clk_i	(wb_clk),
	.cpu0_rst_o	(or1k_dbg_rst),
	.cpu0_addr_o	(or1k_dbg_adr_i),
	.cpu0_data_o	(or1k_dbg_dat_i),
	.cpu0_stb_o	(or1k_dbg_stb_i),
	.cpu0_we_o	(or1k_dbg_we_i),
	.cpu0_data_i	(or1k_dbg_dat_o),
	.cpu0_ack_i	(or1k_dbg_ack_o),
	.cpu0_stall_o	(or1k_dbg_stall_i),
	.cpu0_bp_i	(or1k_dbg_bp_o),

	// TAP interface
	.tck_i		(tck_pad_i),
	.tdi_i		(jtag_tap_tdo),
	.tdo_o		(dbg_if_tdo),
	.rst_i		(wb_rst),
	.capture_dr_i	(jtag_tap_capture_dr),
	.shift_dr_i	(jtag_tap_shift_dr),
	.pause_dr_i	(jtag_tap_pause_dr),
	.update_dr_i	(jtag_tap_update_dr),
	.debug_select_i	(dbg_if_select),

	// Wishbone debug master
	.wb_clk_i	(wb_clk),
	.wb_dat_i	(wb_s2m_dbg_dat),
	.wb_ack_i	(wb_s2m_dbg_ack),
	.wb_err_i	(wb_s2m_dbg_err),

	.wb_adr_o	(wb_m2s_dbg_adr),
	.wb_dat_o	(wb_m2s_dbg_dat),
	.wb_cyc_o	(wb_m2s_dbg_cyc),
	.wb_stb_o	(wb_m2s_dbg_stb),
	.wb_sel_o	(wb_m2s_dbg_sel),
	.wb_we_o	(wb_m2s_dbg_we),
	.wb_cti_o	(wb_m2s_dbg_cti),
	.wb_bte_o	(wb_m2s_dbg_bte)
);


////////////////////////////////////////////////////////////////////////
//
// HOST CONTROLLER
//
////////////////////////////////////////////////////////////////////////

wire hostctrl_cpu_rst;

host_ctrl host0(
	.clk_i 	(wb_clk),
	.rst_i 	(wb_rst),
	.hostctrl_cpu_rst(hostctrl_cpu_rst),
	.data_i	(hostctrl_data), //8 bit alla volta
	.done_i	(hostctrl_done), //finito di mandare dati
	.ack_o	(hostctrl_ack), //ack scritto in memoria
   .ack_data (hostctrl_ack_data), //ack ricevuti 8 bit
	.next (next), //procedere alla ricezione del dato successivo
   .valid_i (hostctrl_valid), //ho inviato una parola valida
	.wb_adr	(wb_m2s_hostctrl_adr),
	.wb_dat	(wb_m2s_hostctrl_dat),
	.wb_ack	(wb_s2m_hostctrl_ack),
	.wb_cyc	(wb_m2s_hostctrl_cyc),
	.wb_stb	(wb_m2s_hostctrl_stb),
	.wb_sel	(wb_m2s_hostctrl_sel),
	.wb_we	(wb_m2s_hostctrl_we),
	.wb_cti	(wb_m2s_hostctrl_cti),
	.wb_bte	(wb_m2s_hostctrl_bte)
);


////////////////////////////////////////////////////////////////////////
//
// mor1kx cpu
//
////////////////////////////////////////////////////////////////////////

wire [31:0]	or1k_irq;
wire		or1k_clk;
wire		or1k_rst;

assign or1k_clk = wb_clk;
assign or1k_rst = wb_rst | or1k_dbg_rst ;

mor1kx #(
	.FEATURE_DEBUGUNIT			("ENABLED"),
	.FEATURE_CMOV				("ENABLED"),
	.FEATURE_INSTRUCTIONCACHE	(`IS_ICACHE),
	.OPTION_ICACHE_BLOCK_WIDTH	(5),
	.OPTION_ICACHE_SET_WIDTH	(8),
	.OPTION_ICACHE_WAYS			(2),
	.OPTION_ICACHE_LIMIT_WIDTH	(32),
	.FEATURE_IMMU				(`IS_IMMU),
	.FEATURE_DATACACHE			(`IS_DCACHE),
	.OPTION_DCACHE_BLOCK_WIDTH	(5),
	.OPTION_DCACHE_SET_WIDTH	(8),
	.OPTION_DCACHE_WAYS			(2),
	.OPTION_DCACHE_LIMIT_WIDTH	(32),
	.FEATURE_DMMU				(`IS_DMMU),
	.OPTION_RF_NUM_SHADOW_GPR	(1),
	.IBUS_WB_TYPE				("B3_REGISTERED_FEEDBACK"),
	.DBUS_WB_TYPE				("B3_REGISTERED_FEEDBACK"),
	.OPTION_CPU0				(`CPU_NAME),
	.OPTION_RESET_PC			(32'h00000100)
) mor1kx0 (
`ifdef SYNTHESIS
    .traceport_exec_insn_o (decode_insn_i),
`endif
	.iwbm_adr_o			(wb_m2s_or1k_i_adr),
	.iwbm_stb_o			(wb_m2s_or1k_i_stb),
	.iwbm_cyc_o			(wb_m2s_or1k_i_cyc),
	.iwbm_sel_o			(wb_m2s_or1k_i_sel),
	.iwbm_we_o			(wb_m2s_or1k_i_we),
	.iwbm_cti_o			(wb_m2s_or1k_i_cti),
	.iwbm_bte_o			(wb_m2s_or1k_i_bte),
	.iwbm_dat_o			(wb_m2s_or1k_i_dat),

	.dwbm_adr_o			(wb_m2s_or1k_d_adr),
	.dwbm_stb_o			(wb_m2s_or1k_d_stb),
	.dwbm_cyc_o			(wb_m2s_or1k_d_cyc),
	.dwbm_sel_o			(wb_m2s_or1k_d_sel),
	.dwbm_we_o			(wb_m2s_or1k_d_we ),
	.dwbm_cti_o			(wb_m2s_or1k_d_cti),
	.dwbm_bte_o			(wb_m2s_or1k_d_bte),
	.dwbm_dat_o			(wb_m2s_or1k_d_dat),

	.clk				(or1k_clk),
	.rst				(or1k_rst),

	.iwbm_err_i			(wb_s2m_or1k_i_err),
	.iwbm_ack_i			(wb_s2m_or1k_i_ack),
	.iwbm_dat_i			(wb_s2m_or1k_i_dat),
	.iwbm_rty_i			(wb_s2m_or1k_i_rty),

	.dwbm_err_i			(wb_s2m_or1k_d_err),
	.dwbm_ack_i			(wb_s2m_or1k_d_ack),
	.dwbm_dat_i			(wb_s2m_or1k_d_dat),
	.dwbm_rty_i			(wb_s2m_or1k_d_rty),

	.irq_i				(or1k_irq),

	.du_addr_i			(or1k_dbg_adr_i[15:0]),
	.du_stb_i			(or1k_dbg_stb_i),
	.du_dat_i			(or1k_dbg_dat_i),
	.du_we_i			(or1k_dbg_we_i),
	.du_dat_o			(or1k_dbg_dat_o),
	.du_ack_o			(or1k_dbg_ack_o),
	.du_stall_i			(or1k_dbg_stall_i),
	.du_stall_o			(or1k_dbg_bp_o)
);

////////////////////////////////////////////////////////////////////////
//
// Generic main RAM
//
////////////////////////////////////////////////////////////////////////
/*wb_ram #(
	.depth	(MEM_SIZE/4)
) wb_bfm_memory0 (
	//Wishbone Master interface
	.wb_clk_i	(wb_clk_i),
	.wb_rst_i	(wb_rst_i),
	.wb_adr_i	(wb_m2s_mem_adr[$clog2(MEM_SIZE)-3:0]),
	.wb_dat_i	(wb_m2s_mem_dat),
	.wb_sel_i	(wb_m2s_mem_sel),
	.wb_we_i	(wb_m2s_mem_we),
	.wb_cyc_i	(wb_m2s_mem_cyc),
	.wb_stb_i	(wb_m2s_mem_stb),
	.wb_cti_i	(wb_m2s_mem_cti),
	.wb_bte_i	(wb_m2s_mem_bte),
	.wb_dat_o	(wb_s2m_mem_dat),
	.wb_ack_o	(wb_s2m_mem_ack),
	.wb_err_o	(wb_s2m_mem_err)
);*/

   assign wb_m2s_mem_adr_sim = wb_m2s_mem_adr;
   assign wb_m2s_mem_dat_sim = wb_m2s_mem_dat;
   assign wb_m2s_mem_sel_sim = wb_m2s_mem_sel;
   assign wb_m2s_mem_we_sim = wb_m2s_mem_we;
   assign wb_m2s_mem_cyc_sim = wb_m2s_mem_cyc;
   assign wb_m2s_mem_stb_sim = wb_m2s_mem_stb;
   assign wb_m2s_mem_cti_sim = wb_m2s_mem_cti;
   assign wb_m2s_mem_bte_sim = wb_m2s_mem_bte;
   assign wb_s2m_mem_dat = wb_s2m_mem_dat_sim;
   assign wb_s2m_mem_ack = wb_s2m_mem_ack_sim;
   assign wb_s2m_mem_err = wb_s2m_mem_err_sim;
   assign wb_s2m_mem_rty = 1'b0;

wire uart_irq;

uart_top #(
	.debug	(0),
	.SIM	(1)
) uart16550 (
	//Wishbone Master interface
	.wb_clk_i	(wb_clk_i),
	.wb_rst_i	(wb_rst_i),
	.wb_adr_i	(wb_m2s_uart_adr[2:0]),
	.wb_dat_i	(wb_m2s_uart_dat),
	.wb_sel_i	(4'h0),
	.wb_we_i	(wb_m2s_uart_we),
	.wb_cyc_i	(wb_m2s_uart_cyc),
	.wb_stb_i	(wb_m2s_uart_stb),
	.wb_dat_o	(wb_s2m_uart_dat),
	.wb_ack_o	(wb_s2m_uart_ack),
        .int_o		(uart_irq),
	.srx_pad_i	(1'b0),
	.stx_pad_o	(),
	.rts_pad_o	(),
	.cts_pad_i	(1'b0),
	.dtr_pad_o	(),
	.dsr_pad_i	(1'b0),
	.ri_pad_i	(1'b0),
	.dcd_pad_i	(1'b0)
);
   assign wb_s2m_uart_err = 1'b0;
   assign wb_s2m_uart_rty = 1'b0;

////////////////////////////////////////////////////////////////////////
//
// CPU Interrupt assignments
//
////////////////////////////////////////////////////////////////////////
assign or1k_irq[0] = 0;
assign or1k_irq[1] = 0;
assign or1k_irq[2] = uart_irq;
assign or1k_irq[3] = 0;
assign or1k_irq[4] = 0;
assign or1k_irq[5] = 0;
assign or1k_irq[6] = 0;
assign or1k_irq[7] = 0;
assign or1k_irq[8] = 0;
assign or1k_irq[9] = 0;
assign or1k_irq[10] = 0;
assign or1k_irq[11] = 0;
assign or1k_irq[12] = 0;
assign or1k_irq[13] = 0;
assign or1k_irq[14] = 0;
assign or1k_irq[15] = 0;
assign or1k_irq[16] = 0;
assign or1k_irq[17] = 0;
assign or1k_irq[18] = 0;
assign or1k_irq[19] = 0;
assign or1k_irq[20] = 0;
assign or1k_irq[21] = 0;
assign or1k_irq[22] = 0;
assign or1k_irq[23] = 0;
assign or1k_irq[24] = 0;
assign or1k_irq[25] = 0;
assign or1k_irq[26] = 0;
assign or1k_irq[27] = 0;
assign or1k_irq[28] = 0;
assign or1k_irq[29] = 0;
assign or1k_irq[30] = 0;

endmodule
