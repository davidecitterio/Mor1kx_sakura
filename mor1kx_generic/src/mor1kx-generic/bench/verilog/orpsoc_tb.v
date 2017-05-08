module orpsoc_tb;

   localparam MEM_SIZE = 32'h02000000; //Set default memory size to 32MB

   vlog_tb_utils vlog_tb_utils0();
   
   
   
initial
   begin
   $dumpfile("out.vcd");
   $dumpvars(0,orpsoc_tb);
   $dumpvars(0,orpsoc_tb.dut.mor1kx0.mor1kx_cpu);
   end

//    ////////////////////////////////////////////////////////////////////////
//    //
//    // JTAG VPI interface
//    //
//    ////////////////////////////////////////////////////////////////////////
//
//   wire tms;
//    wire tck;
//   wire tdi;
//    wire tdo;

//   reg enable_jtag_vpi;
//    initial enable_jtag_vpi = $test$plusargs("enable_jtag_vpi");

//    jtag_vpi jtag_vpi0
//    (
//        .tms		(tms),
//        .tck		(tck),
//        .tdi		(tdi),
//        .tdo		(tdo),
//        .enable		(enable_jtag_vpi),
//        .init_done	(orpsoc_tb.dut.wb_rst)
//    );


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
// Generic main RAM
//
////////////////////////////////////////////////////////////////////////
wire [31:0] mem_adr;
wire [31:0] mem_dat;
wire [3:0] mem_sel;
wire mem_we;
wire mem_cyc;
wire mem_stb;
wire [2:0] mem_cti;
wire [1:0] mem_bte;
wire [31:0] mem_dat_o;
wire mem_ack_o;
wire mem_err_o;


wb_ram #(
	.depth	(MEM_SIZE/4)
) wb_bfm_memory0 (
	//Wishbone Master interface
	.wb_clk_i	(syst_clk),
	.wb_rst_i	(syst_rst),
	.wb_adr_i	(mem_adr),
	.wb_dat_i	(mem_dat),
	.wb_sel_i	(mem_sel),
	.wb_we_i	(mem_we),
	.wb_cyc_i	(mem_cyc),
	.wb_stb_i	(mem_stb),
	.wb_cti_i	(mem_cti),
	.wb_bte_i	(mem_bte),
	.wb_dat_o	(mem_dat_o),
	.wb_ack_o	(mem_ack_o),
	.wb_err_o	(mem_err_o)
);


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
   orpsoc_top
     #(.MEM_SIZE (MEM_SIZE))
   dut
     (.wb_clk_i (syst_clk),
      .wb_rst_i (syst_rst),
      .tms_pad_i (tms),
      .tck_pad_i (tck),
      .tdi_pad_i (tdi),
      .tdo_pad_o (tdo),
      .mem_adr(mem_adr),
      .mem_dat(mem_dat),
      .mem_sel(mem_sel),
      .mem_we(mem_we),
      .mem_cyc(mem_cyc),
      .mem_stb(mem_stb),
      .mem_cti(mem_cti),
      .mem_bte(mem_bte),
      .mem_dat_i(mem_dat_o),
      .mem_ack_i(mem_ack_o),
      .mem_err_i(mem_err_o)
   );

endmodule
