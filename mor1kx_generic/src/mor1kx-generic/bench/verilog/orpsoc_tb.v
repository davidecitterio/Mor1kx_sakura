module orpsoc_tb;
   
   `include "../../../mor1kx/rtl/verilog/mor1kx-defines.v"
   localparam MEM_SIZE = 32'h02000000; //Set default memory size to 32MB
   //localparam MEM_SIZE = 32'h00010000; //130 KB
   vlog_tb_utils vlog_tb_utils0();
   
/*initial
   begin
   $dumpfile("out.vcd");
   $dumpvars(0,orpsoc_tb);
   //$dumpvars(0,orpsoc_tb.dut.mor1kx0.mor1kx_cpu);
   end
*/
//    ////////////////////////////////////////////////////////////////////////
//    //
//    // JTAG VPI interface
//    //
//    ////////////////////////////////////////////////////////////////////////
//
//    wire tms;
//    wire tck;
//    wire tdi;
//    wire tdo;
//
//    reg enable_jtag_vpi;
//    initial enable_jtag_vpi = $test$plusargs("enable_jtag_vpi");
//
//    jtag_vpi jtag_vpi0
//    (
//        .tms		(tms),
//        .tck		(tck),
//        .tdi		(tdi),
//        .tdo		(tdo),
//        .enable		(enable_jtag_vpi),
//        .init_done	(orpsoc_tb.dut.wb_rst)
//    );
//
//   ////////////////////////////////////////////////////////////////////////
//   //
//   // ELF program loading
//   //
//   ////////////////////////////////////////////////////////////////////////
//   integer mem_words;
//   integer i;
//   reg [31:0] mem_word;
//   reg [1023:0] elf_file;
//
//   initial begin
//      if ($test$plusargs("clear_ram")) begin
//	 $display("Clearing RAM");
//	 for(i=0; i < MEM_SIZE/4; i = i+1)
//	   orpsoc_tb.dut.wb_bfm_memory0.ram0.mem[i] = 32'h00000000;
//      end
//
//      if($value$plusargs("elf_load=%s", elf_file)) begin
//	 $elf_load_file(elf_file);
//
//	 mem_words = $elf_get_size/4;
//	 $display("Loading %d words", mem_words);
//	 for(i=0; i < mem_words; i = i+1)
//	   orpsoc_tb.dut.wb_bfm_memory0.ram0.mem[i] = $elf_read_32(i*4);
//      end else
//	$display("No ELF file specified");
//
//   end

   ////////////////////////////////////////////////////////////////////////
   //
   // Clock and reset generation
   //
   ////////////////////////////////////////////////////////////////////////
   reg syst_clk = 1;
   reg syst_rst = 1;

   always #10 syst_clk <= ~syst_clk;
   initial #100 syst_rst <= 0;



   ////////////////////////////////////////////////////////////////////////
   //
   // Pump data into memory
   //
   ////////////////////////////////////////////////////////////////////////
	
	wire [31:0] sram_data;
	wire sram_ack;
	wire sram_done;

	reg done = 0;
	reg ack;
	reg data;

	integer               sram    ; // file handler
	char               scan    ; // file handler
	logic   signed [21:0] captured_data;
	`define NULL 0    

	initial begin
	  sram = $fopen("hello.sram", "r");
	  if (sram == NULL) begin
	    $display("file handle was NULL");
	    $finish;
	  end
	end

	always @(posedge clk) begin
	  scan = $fscanf(sram, "%c", captured_data); 
	  if (!$feof(sram)) begin
	    //LEGGO E INVIO 8 BIT ALLA VOLTA
	    //ASPETTO ACK

	    if ($feof(sram)) done <= 1;
	  end
	end
	
	assign sram_data = data;
	assign sram_done = done;


   ////////////////////////////////////////////////////////////////////////
   //
   // mor1kx monitor
   //
   ////////////////////////////////////////////////////////////////////////
   mor1kx_monitor #(.LOG_DIR(".")) i_monitor();

   ////////////////////////////////////////////////////////////////////////
   //
   // DUT
   //
   ////////////////////////////////////////////////////////////////////////
   wire [31:0] wb_m2s_mem_adr_sim;
   wire [31:0] wb_m2s_mem_dat_sim;
   wire [3:0] wb_m2s_mem_sel_sim;
   wire wb_m2s_mem_we_sim;
   wire wb_m2s_mem_cyc_sim;
   wire wb_m2s_mem_stb_sim;
   wire [2:0] wb_m2s_mem_cti_sim;
   wire [1:0] wb_m2s_mem_bte_sim;
   wire [31:0] wb_s2m_mem_dat_sim;
   wire wb_s2m_mem_ack_sim;
   wire wb_s2m_mem_err_sim;
 `ifdef SYNTHESIS 
   wire [`OR1K_INSN_WIDTH-1:0] decode_insn_i;
 `endif

   orpsoc_top
  `ifndef SYNTHESIS
     #(.MEM_SIZE (MEM_SIZE))
  `endif
   dut
     (
  `ifdef SYNTHESIS
      .decode_insn_to_tb (decode_insn_i),
  `endif
      .wb_clk_i (syst_clk),
      .wb_rst_i (syst_rst),
      .tms_pad_i (tms),
      .tck_pad_i (tck),
      .tdi_pad_i (tdi),
      .tdo_pad_o (tdo),
      .wb_m2s_mem_adr_sim (wb_m2s_mem_adr_sim),
      .wb_m2s_mem_dat_sim (wb_m2s_mem_dat_sim),
      .wb_m2s_mem_sel_sim (wb_m2s_mem_sel_sim),
      .wb_m2s_mem_we_sim (wb_m2s_mem_we_sim),
      .wb_m2s_mem_cyc_sim (wb_m2s_mem_cyc_sim),
      .wb_m2s_mem_stb_sim (wb_m2s_mem_stb_sim),
      .wb_m2s_mem_cti_sim (wb_m2s_mem_cti_sim),
      .wb_m2s_mem_bte_sim (wb_m2s_mem_bte_sim),
      .wb_s2m_mem_dat_sim (wb_s2m_mem_dat_sim),
      .wb_s2m_mem_ack_sim (wb_s2m_mem_ack_sim),
      .wb_s2m_mem_err_sim (wb_s2m_mem_err_sim),
      .hostctrl_data (sram_data),
      .hostctrl_done (sram_done),
      .hostctrl_ack  (sram_ack)
);

   ////////////////////////////////////////////////////////////////////////
   //
   // RAM (only for simulation)
   //
   ////////////////////////////////////////////////////////////////////////
   wb_ram #(
	   .depth (MEM_SIZE/4)
   ) wb_bfm_memory0 (
	//Wishbone Master interface
	.wb_clk_i	(syst_clk),
	.wb_rst_i	(syst_rst),
	.wb_adr_i	(wb_m2s_mem_adr_sim[$clog2(MEM_SIZE)-3:0]),
	.wb_dat_i	(wb_m2s_mem_dat_sim),
	.wb_sel_i	(wb_m2s_mem_sel_sim),
	.wb_we_i	(wb_m2s_mem_we_sim),
	.wb_cyc_i	(wb_m2s_mem_cyc_sim),
	.wb_stb_i	(wb_m2s_mem_stb_sim),
	.wb_cti_i	(wb_m2s_mem_cti_sim),
	.wb_bte_i	(wb_m2s_mem_bte_sim),
	.wb_dat_o	(wb_s2m_mem_dat_sim),
	.wb_ack_o	(wb_s2m_mem_ack_sim),
	.wb_err_o	(wb_s2m_mem_err_sim)
   );


  
endmodule
