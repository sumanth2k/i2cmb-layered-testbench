class i2cmb_generator extends ncsu_component;
`ncsu_register_object(i2cmb_generator)

wb_transaction trans_r[iicmb_reg_ofst_t];
wb_transaction trans_w[iicmb_reg_ofst_t];

wb_transaction cmd_start_trans,cmd_stop_trans, cmd_en_trans, cmd_write_trans, cmd_wdata_trans[32+64];
i2c_transaction i2c_write_trans, i2c_read_trans, i2c_read_trans_arr[1+64];

wb_agent wb_agt0;
i2c_agent i2c_agt0;

bit [I2C_DATA_WIDTH-1:0] i2c_data [$];

function new(string name="", ncsu_component_base parent=null);
	super.new(name,parent);

	for(int i=3; i>=0; i--) begin
		automatic iicmb_reg_ofst_t addr_ofst = iicmb_reg_ofst_t'(i);
		$cast(trans_r[addr_ofst], ncsu_object_factory::create("wb_transaction"));
		$cast(trans_w[addr_ofst], ncsu_object_factory::create("wb_transaction"));
		void'(trans_r[addr_ofst].set_addr(addr_ofst)); void'(trans_r[addr_ofst].set_op(WB_READ));
		void'(trans_w[addr_ofst].set_addr(addr_ofst)); void'(trans_w[addr_ofst].set_op(WB_WRITE));
	end

	$cast(cmd_start_trans, ncsu_object_factory::create("wb_transaction"));
	$cast(cmd_stop_trans, ncsu_object_factory::create("wb_transaction"));
	$cast(cmd_en_trans, ncsu_object_factory::create("wb_transaction"));
	$cast(cmd_write_trans, ncsu_object_factory::create("wb_transaction"));

	void'(cmd_en_trans.set_op(WB_WRITE)); 		void'(cmd_en_trans.set_addr(CSR)); 		void'(cmd_en_trans.set_data( CSR_E | CSR_IE));		// Enable Core
	void'(cmd_start_trans.set_op(WB_WRITE)); 	void'(cmd_start_trans.set_addr(CMDR)); 	void'(cmd_start_trans.set_data({5'b0,CMD_START}));	
	void'(cmd_stop_trans.set_op(WB_WRITE)); 	void'(cmd_stop_trans.set_addr(CMDR)); 	void'(cmd_stop_trans.set_data(CMD_STOP));			// Stop Command
	void'(cmd_write_trans.set_op(WB_WRITE)); 	void'(cmd_write_trans.set_addr(CMDR)); 	void'(cmd_write_trans.set_data({5'b0,CMD_WRITE}));	// Write Command

	$cast(i2c_write_trans, ncsu_object_factory::create("i2c_transaction"));
	$cast(i2c_read_trans, ncsu_object_factory::create("i2c_transaction"));

	void'(i2c_write_trans.set_op(I2C_WRITE));
	void'(i2c_read_trans.set_op(I2C_READ));

	foreach(cmd_wdata_trans[i]) begin
		$cast(cmd_wdata_trans[i], ncsu_object_factory::create("wb_transaction"));
        void'(cmd_wdata_trans[i].set_addr(DPR));
        void'(cmd_wdata_trans[i].set_op(WB_WRITE));
    end

	$cast(i2c_read_trans_arr[0], ncsu_object_factory::create("i2c_transaction"));
	void'(i2c_read_trans_arr[0].set_op(I2C_READ));

    for(int i=0; i<64; i++) begin
        $cast(i2c_read_trans_arr[i+1], ncsu_object_factory::create("i2c_transaction"));
        void'(i2c_read_trans_arr[i+1].set_op(I2C_READ));
    end

endfunction

function void set_wb_agent(wb_agent wb_agt);
    this.wb_agt0 = wb_agt;
endfunction

function void set_i2c_agent(i2c_agent i2c_agt);
    this.i2c_agt0 = i2c_agt;
endfunction

virtual task run();

	foreach(cmd_wdata_trans[i]) begin
        void'(cmd_wdata_trans[i].set_data( (i<32)? i : 32+i ));
    end

    for(int i=0; i<32; i++) begin
        i2c_data.push_back( 100+i ); 
    end

    void'(i2c_read_trans_arr[0].set_data(i2c_data));

    for(int i=0; i<64; i++) begin
        i2c_data.delete;
        i2c_data.push_back( 63-i );   
        void'(i2c_read_trans_arr[i+1].set_data(i2c_data));
    end

    fork
        begin
            i2c_agt0.bl_put( i2c_write_trans );

            i2c_agt0.bl_put( i2c_read_trans_arr[0] );

            for(int i=0;i<64;i++) 
            begin
                i2c_agt0.bl_put( i2c_write_trans );
                i2c_agt0.bl_put( i2c_read_trans_arr[i+1] );
            end
        end 
        begin
            wb_agt0.bl_put( cmd_en_trans );									
            wb_agt0.bl_put( trans_w[DPR].set_data(I2C_BUS_ID) );			
            wb_agt0.bl_put( trans_w[CMDR].set_data({5'b0,CMD_SET_BUS}) );	

            $display("+++++++++++++++++++++++++++++++++++++++++++++++++++++");
            $display(" Write 32 incrementing values                        ");
            $display("+++++++++++++++++++++++++++++++++++++++++++++++++++++");

            wb_agt0.bl_put( cmd_start_trans );		    
            WB_address( I2C_WRITE );					
            for(int i=0; i<32; i++) 
            begin           	
                WB_write_byte( cmd_wdata_trans[i] );	
            end
            wb_agt0.bl_put( cmd_stop_trans );		    

            $display("+++++++++++++++++++++++++++++++++++++++++++++++++++++");
            $display(" Read 32 values from the i2c_bus                     ");
            $display("+++++++++++++++++++++++++++++++++++++++++++++++++++++");

            wb_agt0.bl_put( cmd_start_trans );          
            WB_address( I2C_READ );                   	
            for(int i=0; i<32; i++) 
            begin           	
                WB_read_byte( i==31 );              	
            end
            wb_agt0.bl_put( cmd_stop_trans );			

            $display("+++++++++++++++++++++++++++++++++++++++++++++++++++++");
            $display(" Alternate writes and reads for 64 transfers         ");
            $display("+++++++++++++++++++++++++++++++++++++++++++++++++++++");

            for(int i=32; i<96; i++) 
            begin
                wb_agt0.bl_put( cmd_start_trans );     	
                WB_address( I2C_WRITE );               	
                WB_write_byte( cmd_wdata_trans[i] );	
                wb_agt0.bl_put( cmd_start_trans );     	
                WB_address( I2C_READ );                	
                WB_read_byte();                      	
            end 
            wb_agt0.bl_put( cmd_stop_trans );		

        end 
    join

    $display("+++++++++++++++++++++++++++++++++++++++++++++++++++++");
    $display(" Project 2 Finish                                    ");
    $display("+++++++++++++++++++++++++++++++++++++++++++++++++++++");

endtask

virtual task WB_address( input i2c_op_t i2c_op, input bit [6:0] _slave_addr_=I2C_SLAVE_ADDRESS );
    wb_agt0.bl_put(trans_w[DPR].set_data( ({1'b0,_slave_addr_}<<1) | bit'(i2c_op) ) ); 
    wb_agt0.bl_put(cmd_write_trans); 
endtask

task WB_write_byte( input wb_transaction trans );
    wb_agt0.bl_put(trans);			
    wb_agt0.bl_put(cmd_write_trans); 
endtask

task WB_read_byte( input logic last=1  );
    wb_agt0.bl_put(trans_w[CMDR].set_data( {5'b0, CMD_READ_W_AK ^ last } ) ); 
    wb_agt0.bl_put_ref(trans_r[DPR]); 
endtask

function CMDR_REG to_cmdr_reg( bit [WB_DATA_WIDTH-1:0] wb_data );
	automatic CMDR_REG cmdr_reg;
    {cmdr_reg.don, cmdr_reg.nak, cmdr_reg.al, cmdr_reg.err, cmdr_reg.r, cmdr_reg.cmd} = wb_data;
    return cmdr_reg;
endfunction

function CSR_REG to_csr_reg( bit [WB_DATA_WIDTH-1:0] wb_data );
	automatic CSR_REG csr_reg;;
    {csr_reg.e, csr_reg.ie, csr_reg.bb, csr_reg.bc, csr_reg.bus_id} = wb_data;
    return csr_reg;
endfunction

function FSMR_REG to_fsmr_reg( bit [WB_DATA_WIDTH-1:0] wb_data );
	automatic FSMR_REG fsmr_reg;
    {fsmr_reg.byte_fsm, fsmr_reg.bit_fsm} = wb_data;
    return fsmr_reg;
endfunction

endclass
