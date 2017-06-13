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

	wire [7:0] sram_data;
	wire sram_ack;
	wire sram_done;

	reg done = 0;
	reg ack;
	reg data;

	localparam depth = MEM_SIZE/4;

	reg [31:0] address = 32'b00;  // contatore address da passare a host controller
  reg [31:0] counter = 30'b00; //contatore address per accedere a dati di readmemh
	reg [31:0] mem [0:depth-1]; //variabile memorizzazione readmemh

	localparam ZERO=2'b00, ONE=2'b01, TWO=2'b10, THREE=2'b11;
	reg[1:0] ss = ZERO;
	reg sendData = 0; // 0 address, 1 data

	initial begin
	  $readmemh("sram.vmem", mem);
	  done <= 0;
 	end


	always @(posedge syst_clk) begin
	 if (!done) begin
	    if (!sendData) begin
		   case (ss)
		    ZERO: begin
			   sram_data <= address[7:0];
			   ss <= ONE;
			  end

		    ONE:  begin
			   sram_data <= address[15:8];
			   ss <= TWO;
			  end

		    TWO:  begin
			   sram_data <= address[23:16];
			   ss <= THREE;

			  end

		    THREE:begin
			   sram_data <= address[31:24];
			   ss <= ZERO;
			   sendData = 1;
			   address <= address + 1; //incremento e mi porto all'address successivo
			  end
		   endcase
	    end
	    else if (sendData) begin
		   case (ss)
		    ZERO: begin
			   sram_data <= mem[counter][7:0];
			   ss <= ONE;
			  end

		    ONE:  begin
			   sram_data <= mem[counter][15:8];
			   ss <= TWO;
			  end

		    TWO:  begin
			   sram_data <= mem[counter][23:16];
			   ss <= THREE;
			  end

		    THREE:begin
			   sram_data <= mem[counter][31:24];
			   ss <= ZERO;
			   sendData=0;
			   counter = counter + 1; // passo al successivo dato in memoria da trasmettere
			  end
		   endcase
	    end

          if (counter == (depth-1))
	    done <= 1;
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
