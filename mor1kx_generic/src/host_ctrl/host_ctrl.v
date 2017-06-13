module host_ctrl
	#(parameter packet_size=8,
	  parameter address_size = 8,
          parameter data_size = 32 )
	(
	 input clk_i,
	 input rst_i,
	 input [7:0] data_i,
	 input done_i,
	 output ack_o,
	 output hostctrl_cpu_rst,
	 output [31:0] wb_adr,
	 output [31:0] wb_dat,
 	 input 	wb_ack,
	 output wb_cyc,
	 output wb_stb,
	 output [3:0] wb_sel,
	 output wb_we,
	 output [2:0] wb_cti,
	 output [1:0] wb_bte
	);

	localparam IDLE=3'b000, WADDR=3'b001, WDATA=3'b010, WBTX=3'b011, WRAM=3'b100, WACK=3'B101;
        localparam ZERO=2'b00, ONE=2'b01, TWO=2'b10, THREE=2'b11;

	reg [3:0] ss = IDLE;
	reg [1:0] countAddress = ZERO;
        reg [1:0] countData = ZERO;
        reg ctrl_ack;
	reg ctrl_cpu_rst = 0;
	reg [31:0] address_ctrl;
	reg [31:0] data_ctrl;
	reg [31:0] address;
	reg [31:0] data;
        reg cyc;
	reg stb;
	reg [3:0] sel;
	reg we;
	reg [2:0] cti;
	reg [1:0] bte;


	always@(posedge clk_i) begin
	  if(rst_i) ss<=0;
	  else
	  begin
	    ctrl_ack <= 0;
	    cyc <= 0;
	    case(ss)
	      IDLE:  begin
		       			if(!done_i) ss<=WADDR;
		       			ctrl_cpu_rst <= 1;
		     			 end
	            
	      WADDR: case (countAddress)
								ZERO: begin
								        address_ctrl[7:0] <= data_i;
												countAddress <= ONE;
								      end

								ONE:  begin
								        address_ctrl[15:8] <= data_i;
												countAddress <= TWO;
								      end

								TWO:  begin
								        address_ctrl[23:16] <= data_i;
												countAddress <= THREE;
								      end

								THREE:begin
								        address_ctrl[31:24] <= data_i;
												ss<= WBDATA;
												countAddress <= ZERO;
								      end
		     			 endcase

			 
	      WDATA: case (countData)
								ZERO: begin
								        data_ctrl[31:0] <= data_i;
												countData <= ONE;
								      end

								ONE:  begin
								        data_ctrl[15:8] <= data_i;
												countData <= TWO;
								      end

								TWO:  begin
								        data_ctrl[23:16] <= data_i;
												countData <= THREE;
								      end

								THREE:begin
								        data_ctrl[31:24] <= data_i;
												ss<= WBTX;
												countData <= ZERO;
								      end
					     endcase

	      WBTX: begin
					     we <= 1;
					     cyc <= 1;
					     stb <=1;
					     sel <= 4'b1111;
					     address <= address_ctrl;
					     data <= data_ctrl;
					     ss <=WRAM;
		    	 		end

	      WRAM: begin
					      cyc <= 0; //non trasmetto niente
					      stb <= 0; // segnali non stabili
					      if (wb_ack_mem)
						 			ss <= WACK;
		    			end

	      WACK: if (!done_i) begin
								ss <= WADDR;
					 			ctrl_ack <= 1;
							 end
							 else begin
								ss <= IDLE;
					 			ctrl_ack <= 1;
								ctrl_cpu_rst <= 0;
		    			end

	    endcase 
	  end 
	end


	assign ack_o = crtl_ack;
	assign hostctrl_cpu_rst = ctrl_cpu_rst;

	assign wb_adr = address;
	assign wb_dat = data;
  assign wb_we  = we;
  assign wb_sel = sel;
	assign wb_cyc = cyc;
	assign wb_stb = stb;
  assign wb_cti = 3'h0;
  assign wb_bte = 2'h0;


endmodule
