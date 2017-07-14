module host_ctrl
	(input clk_i,
	 input rst_i,
	 input [7:0] data_i,
	 input done_i,
	 input valid_i,
	 //input 	wb_ack,
	 output ack_o,
	 output reg ack_data,
	 output hostctrl_cpu_rst
	 //output [31:0] wb_adr,
	 //output [31:0] wb_dat,
	 //output wb_cyc,
	 //output wb_stb,
	 //output [3:0] wb_sel,
	 //output wb_we,
	 //output [2:0] wb_cti,
	 //output [1:0] wb_bte
	 );
	 
	 localparam ZERO = 2'b00, ONE = 2'b01, TWO = 2'b10, THREE = 2'b11;
	 localparam IDLE = 3'b000, WADD = 3'b001, WDATA = 3'b010, WBTX = 3'b011, WRAM = 3'b100, WACK = 3'b101;
	 reg ctrl_ack;
	 reg ctrl_cpu_rst = 0;
	 reg [2:0] ss = IDLE;
	 reg [1:0] countAddress = ZERO;
	 reg [1:0] countData = ZERO;
	 reg [31:0] address_ctrl;
	 reg [31:0] data_ctrl;
	 reg [31:0] address;
	 reg [31:0] data;
	 reg cyc;
	 reg stb;
	 reg [3:0] sel;
	 reg we;
	 reg [2:0] cti;
	 reg [1:0] bti;
	 reg waddr_ack;
	 reg wdata_ack;
	 reg waddr_start;
	 reg wdata_start;
	 
	 assign ack_o = ctrl_ack;
	 assign hostctrl_cpu_rst = ctrl_cpu_rst;
	 assign wb_adr = address;
	 assign wb_dat = data;
	 assign wb_we = we;
	 assign wb_sel = sel;
	 assign wb_cyc = cyc;
	 assign wb_stb = stb;
	 assign wb_cti = 3'h0;
	 assign wb_bte = 2'h0;
	 
	 
	 always @ (posedge clk_i) begin
		if (valid_i) begin
	   $display("host ctrl received %h\n", data_i);
		 ack_data <= 1;
		 ctrl_ack <= 1;
		 end
	 end
/*
	always @(posedge clk_i)
	begin
	  if(rst_i)  
		   ss<=IDLE;
	  else
		begin
	    ctrl_ack <= 0;
		 ack_data <= 0;
	    cyc <= 0;
	    
	    case(ss)
		  begin
	        IDLE:   begin
							if(done_i ==0)  
							 begin
							  ss<=WADDR;
		       			  ctrl_cpu_rst <= 1;
							 end
		     			 end
	  
	        WADDR:  begin
							if (!waddr_ack)
								waddr_start <=1;
							else begin
								ss <= WDATA;
								waddr_start <= 0;
								waddr_ack = 0;
							end
						 end

			 
	        WDATA:  begin
							if (!wdata_ack)
								wdata_start <=1;
							else begin
								ss <= WADDR;
								wdata_start <= 0;
								wdata_ack = 0;
							end
						 end

	        WBTX:   begin
							if (!wb_ack)
								begin
								  address <= address_ctrl;
								  data <= data_ctrl;
								  we <= 1; //ciclo scrittura
								  cyc <= 1; //inizio a mandare dati
								  stb <=1; //segnali stabili
								  sel <= 4'b1111; //32 bit
							    end
							 else
								begin
									 ss<<WACK;
									 cyc <= 0;
									 stb <= 0;
							 end
		    	 		 end

	        WACK: begin
							if (done_i==0) 
							  begin
							   ss <= WADDR;
							  end
							else 
							  begin
								ss <= IDLE;
								ctrl_cpu_rst <= 0;
			    			  end
							 ctrl_ack <= 1;
						  end
	     end
	    endcase 
	   end  
	end

 // ADDRESS MACHINE
	always @ (posedge clk_i)
	  begin
		 if(rst_i) 
		   countAddress<=ZERO;
		 else
			begin
			  if (waddr_start)
				 begin
					case (countAddress)
					  begin
						 ZERO: begin
									 if (valid_i) begin
										 address_ctrl[7:0] <= data_i[7:0];
										 countAddress <= ONE;
										 ack_data <= 1;
									 end
								 end

						 ONE:  begin
									 if (valid_i) begin
										 address_ctrl[15:8] <= data_i[7:0];
										 countAddress <= TWO;
										 ack_data <= 1;
									 end
								 end

						 TWO:  begin
									 if (valid_i) begin
										 address_ctrl[23:16] <= data_i[7:0];
										 countAddress <= THREE;
										 ack_data <= 1;
									 end
								 end

						 THREE:begin
									 if (valid_i) begin
										 address_ctrl[31:24] <= data_i[7:0];
										 waddr_ack <= 1;
										 countAddress <= ZERO;
										 ack_data <= 1;
									 end
								 end
					  end
					endcase
			    end
			end
		end

		//DATA MACHINE
		always @ (posedge clk_i)
		  begin
			if(rst_i) 
			  countData<=ZERO;
			else
			  begin
				 if (wdata_start)
				   begin
					  case (countData)
						 begin
							ZERO: begin
									  if (valid_i) begin
										 data_ctrl[31:0] <= data_i[7:0];
										 countData <= ONE;
										 ack_data <= 1;
									  end
									end

							ONE:  begin
									  if (valid_i) begin
										 data_ctrl[15:8] <= data_i[7:0];
										 countData <= TWO;
										 ack_data <= 1;
									  end
									end

							TWO:  begin
									  if (valid_i) begin
										 data_ctrl[23:16] <= data_i[7:0];
										 countData <= THREE;
										 ack_data <= 1;
									  end
									end

							THREE:begin
									  if (valid_i) begin
										 data_ctrl[31:24] <= data_i[7:0];
										 wdata_ack <= 1;
										 countData <= ZERO;
										 ack_data <= 1;
									  end
									end
					    end
				     endcase
				   end
				end
			end
*/
endmodule	
