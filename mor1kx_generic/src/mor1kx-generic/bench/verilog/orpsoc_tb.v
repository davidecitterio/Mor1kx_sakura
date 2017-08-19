module orpsoc_tb;

   `include "../../../mor1kx/rtl/verilog/mor1kx-defines.v"
   localparam MEM_SIZE = 32'h02000000; //Set default memory size to 32MB
   //localparam MEM_SIZE = 32'h00010000; //130 KB
   vlog_tb_utils vlog_tb_utils0();

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
      .hostctrl_ack  (sram_ack),
      .hostctrl_ack_data  (sram_ack_data),
      .hostctrl_valid(sram_valid),
		.next(sram_next)
      
);


////////////////////////////////////////////////////////////////////////
//
// Send data to host_ctrl
//
////////////////////////////////////////////////////////////////////////

wire [7:0] sram_data;
wire sram_ack;
wire sram_ack_data;
wire sram_done;
wire sram_valid;
wire sram_next;

reg done = 0;
reg [7:0] data = 8'b00000000;
reg valid = 0, next = 0;

localparam depth = 5877;

reg [31:0] mem [0:depth-1]; //variabile memorizzazione readmemh

reg [31:0] tmp_address= 0, tmp_data=0;

reg [31:0]  i = 0,j = 0, k = 0 ,h = 0;

reg sendAddress = 0, sendData = 0, wait_ack = 0, ackDataArrived = 0;
reg sendAddress_start = 0, sendData_start = 0;

//read from sram
initial begin
 $readmemh("sram.vmem", mem);
 done <= 0; 
end

always @ (posedge syst_rst) begin
	done <= 0;
	i = 0; j= 0; k= 0; h = 0;
	sendAddress = 0; sendData = 0; 
	wait_ack = 0; ackDataArrived = 0;
	sendAddress_start = 0; sendData_start = 0;
	valid = 0; next = 0;
end

always @ (posedge syst_clk) begin
		if ( !done ) 
		 begin
			if ( j<=3 )
			  begin
				 
				 tmp_address = ((i+1)<<6)+j;
				 tmp_data = mem[tmp_address];
						
				 //send address & data
				 if (!sendAddress)
					sendAddress_start = 1;

				 if (i>=15)
					 done = 1;
				 
				 if (sendAddress && sendData && sram_ack)
					begin
						j = j+1;
						$display("Address complete sent: %h \n", tmp_address);
						$display("Data Complete sent: %h \n", tmp_data);
						sendAddress = 0;
						sendData = 0;
					end
			  end
		  if (j > 3)
			begin
				i = i+4;
				j = 0;
				sendAddress_start = 0;
				sendData_start = 0;
			end			  
		 end
		 else begin
			sendAddress_start = 0;
			sendData_start = 0;
		 end
 
end

//send address
always @ (posedge syst_clk) begin
	if (sendAddress_start)
	begin
		if (h <= 24) //for (h=0; h<=24; h = h+8)
			begin
			 data = tmp_address[h+:8];
			 
			 if (ackDataArrived)
				begin
				 valid = 0;
				 h = h+8;
				 ackDataArrived = 0;
				 next = 1;
				end
			 else 
				begin
				 wait_ack = 1;
				 valid = 1;
				 next = 0;
				end
			end
		else
			begin
				sendAddress_start = 0;
				sendData_start = 1;
				sendAddress = 1;
				h = 0;
				next = 0;
			end
	end
		
	if (sendData_start)
	begin
		if (k <= 24) //for (h=0; h<=24; h = h+8)
			begin
			 data = tmp_data[k+:8];
			 valid = 1;
			 if (ackDataArrived)
				begin
				 valid = 0;
				 k = k+8;
				 ackDataArrived = 0;
				 next = 1;
				end
			 else
				begin
				 wait_ack = 1;
				 valid = 1;
				 next = 0;
				end
				
			end
		else
			begin
				sendData_start = 0;
				sendData = 1;
				k = 0;
				next = 0;
			end
	end
end

always @(posedge syst_clk) begin
	if (wait_ack)
		begin
			if (sram_ack_data)
			 begin
				ackDataArrived = 1;
				wait_ack = 0;
			 end
		end
end


/*
//read from sram
initial begin
 $readmemh("sram.vmem", mem);
 done <= 0; 
 $display("data position 8 %h.", mem[100]);
 end

//send data to host ctrl
 $display("Start reading sram.vmem\n");
 for (i = 0; !done; i= i+4)
 begin
   for (j = 0; j<=3; j = j+1)
     begin
       tmp_address = (i<<2)+j;
       tmp_data = mem[i+j];

       //send address
       for (h=0; h<=31; h = h+8)
         begin
           for (k=h; k<h+8; k=k+1)
             data[k] = tmp_address[k];
           valid = 1;
           always @(posedge syst_clk) begin

           end
           while (!sram_ack_data);
           valid = 0;
         end

       //send data
       for (h=0; h<=31; h = h+8)
         begin
            for (k=h; k<h+8; k=k+1)
              data[k] = tmp_address[k];
            valid = 1;
            while (!sram_ack_data);
            valid = 0;
         end

       if (i == depth)
          done = 1;

       while (sram_ack == 0);
     end
  end
end

*/

assign sram_done = done;
assign sram_data = data;
assign sram_valid = valid;
assign sram_next = next;



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
