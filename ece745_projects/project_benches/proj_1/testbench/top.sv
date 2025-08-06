`timescale 1ns / 10ps
import macrro::*;
//typedef enum {i2c_write, i2c_read} i2c_op_t; 
//`include "../../../verification_ip/interface_packages/i2c_pkg/src/i2c_if.sv"
module top();

parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;
parameter int I2C_ADDR_WIDTH = 7;
parameter int I2C_DATA_WIDTH = 8;
parameter int I2C_ADDRESS = 8'h22;

parameter int NUM_I2C_BUSSES = 1;

bit  clk;
bit  rst = 1'b1;
wire cyc;
wire stb;
wire we;
tri1 ack;
wire [WB_ADDR_WIDTH-1:0] adr;
wire [WB_DATA_WIDTH-1:0] dat_wr_o;
wire [WB_DATA_WIDTH-1:0] dat_rd_i;
wire irq;
tri  [NUM_I2C_BUSSES-1:0] scl;
tri  [NUM_I2C_BUSSES-1:0] sda;

bit [I2C_DATA_WIDTH-1:0] r_d [];


bit [I2C_ADDR_WIDTH-1:0] addr;
bit [I2C_DATA_WIDTH-1:0] data [];

i2c_op_t op;
bit [I2C_DATA_WIDTH-1:0] write_data [];
bit [7:0] read_data;
// ****************************************************************************
// Clock generator
initial begin
	clk=0;
end
always #5 clk=~clk;

// ****************************************************************************
// Reset generator
initial begin
	#113 rst =0;
end


// ****************************************************************************
// Monitor Wishbone bus and display transfers in the transcript
bit [WB_ADDR_WIDTH-1:0] mon_addr;
bit [WB_DATA_WIDTH-1:0] mon_data;
bit mon_we;
initial begin
	@(negedge rst);
	repeat (15);
	@(posedge clk);
	forever begin
		wb_bus.master_monitor(mon_addr,mon_data,mon_we);
		/*$display("Addr");
		$display(mon_addr);
		$display("Data");
		$display(mon_data);
		$display("Write Enable");
		$display(mon_we);*/
	end
	
end

task automatic repeated_start_wr (input int x,input int alt);

	//I2C Enable
	wb_bus.master_write(8'h0,192);
	//1
	wb_bus.master_write(8'h1,5);
	//2
	wb_bus.master_write(8'h2,6);
	//3
	wait(irq);
	wb_bus.master_read(8'h2,read_data);
	
	wb_bus.master_write(8'h2,4);
	
	wait(irq);
	wb_bus.master_read(8'h2,read_data);
	
	wb_bus.master_write(8'h1,8'h44);
	
	wb_bus.master_write(8'h2,1);
	
	wait(irq);
	wb_bus.master_read(8'h2,read_data);
	
	//repeat(2)
	if(alt == 0)
	begin
		for(int i=0;i<32;i++)
		begin
		wb_bus.master_write(8'h1,i);
		
		wb_bus.master_write(8'h2,1);
			
		wait(irq);
		wb_bus.master_read(8'h2,read_data);
		end
	end
	else
	begin
		wb_bus.master_write(8'h1,x);
		
		wb_bus.master_write(8'h2,1);
			
		wait(irq);
		wb_bus.master_read(8'h2,read_data);
	end
	
	//repeated start
	wb_bus.master_write(8'h2,4);	
	wait(irq);
	wb_bus.master_read(8'h2,read_data);
	
	wb_bus.master_write(8'h1,8'h44);
	wb_bus.master_write(8'h2,1);
	wait(irq);
	wb_bus.master_read(8'h2,read_data);
	
	if(alt == 0)
	begin
		for(int i=0;i<32;i++)
		begin
		wb_bus.master_write(8'h1,i);
		
		wb_bus.master_write(8'h2,1);
			
		wait(irq);
		wb_bus.master_read(8'h2,read_data);
		end
	end
	else
	begin
		wb_bus.master_write(8'h1,x);
		
		wb_bus.master_write(8'h2,1);
			
		wait(irq);
		wb_bus.master_read(8'h2,read_data);
	end
	
	wb_bus.master_write(8'h2,5);
		
	wait(irq);
	wb_bus.master_read(8'h2,read_data);
	repeat(20)
	@(posedge clk);
endtask

task automatic Writing_to_I2C (input int x,input int alt);

	wb_bus.master_write(8'h0,192); // Enable the IICMB core after power-up
	
	wb_bus.master_write(8'h1,5); // This is the ID of desired I2C bus
	
	wb_bus.master_write(8'h2,6); // Set Bus Command
	
	wait(irq); 							
	wb_bus.master_read(8'h2,read_data); 
	
	wb_bus.master_write(8'h2,4); //Set Start Command
	
	wait(irq);
	wb_bus.master_read(8'h2,read_data);
	
	wb_bus.master_write(8'h1,8'h44); // Slave address
	
	wb_bus.master_write(8'h2,1); // Write command
	
	wait(irq);
	wb_bus.master_read(8'h2,read_data);
	
	//Write Data
	if(alt == 0)
	begin
		for(int i=0;i<32;i++)
		begin
		wb_bus.master_write(8'h1,i);
		
		wb_bus.master_write(8'h2,1);
			
		wait(irq);
		wb_bus.master_read(8'h2,read_data);
		end
	end
	else
	begin
		wb_bus.master_write(8'h1,x);
		
		wb_bus.master_write(8'h2,1);
			
		wait(irq);
		wb_bus.master_read(8'h2,read_data);
	end
	
	
	wb_bus.master_write(8'h2,5); // Stop Command
		
	wait(irq);
	wb_bus.master_read(8'h2,read_data);
	
	repeat(20)
	@(posedge clk);
endtask

task automatic Reading_from_I2C (input int alt,input int nack);

	wb_bus.master_write(8'h0,192); // Enable the IICMB core after power-up
	
	wb_bus.master_write(8'h1,5); // This is the ID of desired I2C bus
	
	wb_bus.master_write(8'h2,6); // Set Bus Command
	
	wait(irq);
	wb_bus.master_read(8'h2,read_data);
	
	wb_bus.master_write(8'h2,4); // Set start command
	
	wait(irq);
	wb_bus.master_read(8'h2,read_data);
	
	wb_bus.master_write(8'h1,8'h45); // Slave Address
	
	wb_bus.master_write(8'h2,1); // Write Command
	
	wait(irq);
	wb_bus.master_read(8'h2,read_data);
	
	//Reading Data
	if(alt==0)
		begin
			for(int i=0;i<31;i++)
			begin
				wb_bus.master_write(8'h2,2);
						
				wait(irq);
				wb_bus.master_read(8'h2,read_data);
				
				wb_bus.master_read(8'h1,read_data);
				//$display("DATA READ");
				//$display(read_data);
			end
			wb_bus.master_write(8'h2,3);
			
			wait(irq);
			wb_bus.master_read(8'h2,read_data);
			wb_bus.master_read(8'h1,read_data);
		end
		
	else
		begin
		
		if(nack == 0)
			begin
				//$display("Into alternate");
				wb_bus.master_write(8'h2,2);
						
				wait(irq);
				wb_bus.master_read(8'h2,read_data);
				
				wb_bus.master_read(8'h1,read_data);
				//$display("DATA READ");
				//$display(read_data);
			end
		else
			begin
				wb_bus.master_write(8'h2,3);
				
				wait(irq);
				wb_bus.master_read(8'h2,read_data);
				wb_bus.master_read(8'h1,read_data);
			end
		end
	// wb_bus.master_write(8'h2,3);
			
	// wait(irq);
	// wb_bus.master_read(8'h2,read_data);
	
	// wb_bus.master_read(8'h1,read_data);
	//$display("DATA READ");
	//$display(read_data);
	
	wb_bus.master_write(8'h2,5); // Set Stop command
	wait(irq);
	wb_bus.master_read(8'h2,read_data);
	
	repeat(20)
	@(posedge clk);
endtask
// ****************************************************************************

bit complete_transfer;
// Define the flow of the simulation
initial begin
	automatic int alternate = 0;
	automatic int send_nack=0;
	int wr_data;
	bit rep_start;
	bit r_start;
	bit x;
	bit [I2C_DATA_WIDTH-1:0] exp[$];
	bit [I2C_DATA_WIDTH-1:0] act[$];
	r_d = new[32];
	for(int i=0;i<32;i++)
	begin
		r_d[i]=100+i;
	end
	@(negedge rst);
	repeat (15)
	@(posedge clk);
    fork
        begin
			
			  $display("------------Incrementing 32 Writes------------");
			  // ----------------Writes------------------------------
			  Writing_to_I2C(wr_data,alternate); 
			  $display("------------Incrementing 32 Reads------------");
			  // ----------------Reads------------------------------
			  Reading_from_I2C(alternate,send_nack);
			  $display("------------Repeated Start test sequence------------");
			    repeated_start_wr(wr_data,alternate);
			r_d.delete();
			
			
			//-----------------Alternate Writes and Reads------------------------
			$display("------------Alternate Writes and Reads------------");
			alternate =1;
			for(int i=0;i<64;i++)
			begin
				r_d = new[1];
				r_d[0]=63-i;
				exp.push_back(r_d[0]);
				wr_data=i+64;
				Writing_to_I2C(wr_data,alternate);
				//begin
					send_nack=1;
					Reading_from_I2C(alternate,send_nack);
			end
			// end
		end
		
        begin
		
			forever
			begin
			    if(rep_start == 0)
				i2c_bus.start_cond(x);
				i2c_bus.wait_for_i2c_transfer(rep_start,op, write_data);
				
				if(op == 1 && rep_start==0)
				i2c_bus.provide_read_data(rep_start,r_d,complete_transfer);
			end
		end
		begin
			forever
			begin
			if(r_start==0)
			begin
			i2c_bus.start_cond(x);
			$display ("Start Detected at time %0t",$time);
			end
			i2c_bus.monitor(r_start,addr,op,data);
			
			foreach(data[i])
			act.push_back(data[i]);
			end
			
		end
	//join
    join_any
	disable fork;
	/*foreach(exp[i])
	begin
	$display("EXPECTED");
	$display(exp[i]);
	end
	foreach(act[i])
	begin
	$display("ACTUAL");
	$display(act[i]);
		if(act[i]!=exp[i])
		begin
			$error("EXPECTED ACT NOT MATCHING");
			$display("exp");
			$display(exp[i]);
			$display(act[i]);
		end
	end*/
        #50000;
	$finish;
end

// ****************************************************************************
// Instantiate the Wishbone master Bus Functional Model
wb_if       #(
      .ADDR_WIDTH(WB_ADDR_WIDTH),
      .DATA_WIDTH(WB_DATA_WIDTH)
      )
wb_bus (
  // System sigals
  .clk_i(clk),
  .rst_i(rst),
  // Master signals
  .cyc_o(cyc),
  .stb_o(stb),
  .ack_i(ack),
  .adr_o(adr),
  .we_o(we),
  // Slave signals
  .cyc_i(),
  .stb_i(),
  .ack_o(),
  .adr_i(),
  .we_i(),
  // Shred signals
  .dat_o(dat_wr_o),
  .dat_i(dat_rd_i)
  );

// ****************************************************************************
// Instantiate the I2C BFM
i2c_if       #(
      .I2C_ADDR_WIDTH(I2C_ADDR_WIDTH),
      .I2C_DATA_WIDTH(I2C_DATA_WIDTH), .ADDRESS(I2C_ADDRESS)
      )
i2c_bus (
  // System sigals
  .scl(scl),
  .sda(sda)
);
// ****************************************************************************
// Instantiate the DUT - I2C Multi-Bus Controller
\work.iicmb_m_wb(str) #(.g_bus_num(NUM_I2C_BUSSES)) DUT
  (
    // ------------------------------------
    // -- Wishbone signals:
    .clk_i(clk),         // in    std_logic;                            -- Clock
    .rst_i(rst),         // in    std_logic;                            -- Synchronous reset (active high)
    // -------------
    .cyc_i(cyc),         // in    std_logic;                            -- Valid bus cycle indication
    .stb_i(stb),         // in    std_logic;                            -- Slave selection
    .ack_o(ack),         //   out std_logic;                            -- Acknowledge output
    .adr_i(adr),         // in    std_logic_vector(1 downto 0);         -- Low bits of Wishbone address
    .we_i(we),           // in    std_logic;                            -- Write enable
    .dat_i(dat_wr_o),    // in    std_logic_vector(7 downto 0);         -- Data input
    .dat_o(dat_rd_i),    //   out std_logic_vector(7 downto 0);         -- Data output
    // ------------------------------------
    // ------------------------------------
    // -- Interrupt request:
    .irq(irq),           //   out std_logic;                            -- Interrupt request
    // ------------------------------------
    // ------------------------------------
    // -- I2C interfaces:
    .scl_i(scl),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
    .sda_i(sda),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
    .scl_o(scl),         //   out std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
    .sda_o(sda)          //   out std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
    // ------------------------------------
  );


endmodule
