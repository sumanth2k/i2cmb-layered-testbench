class i2cmb_generator_direct_test extends i2cmb_generator;
	`ncsu_register_object(i2cmb_generator_direct_test)

iicmb_cmdr_t test_cmd_arr [$];
byte test_dpr_arr [$];
i2c_op_t test_i2c_rw_1,test_i2c_rw_2;
int test_transfer_size [3] = '{1,2,11};
bit [6:0] test_i2c_addr [4] = '{0,32,64,96};

function new(string name="", ncsu_component_base parent=null);
	super.new(name, parent);
endfunction

virtual task run();
  automatic integer k;

	$display("++++++++++++++++++++++++++++++++++++++++++++");
    $display("      I2CMB DIRECT TESTS START          ");
    $display("++++++++++++++++++++++++++++++++++++++++++++");

	wb_agt0.bl_put_ref( trans_r[CSR] );
	reset_core_to_idle_state();

	test_i2c_rw_1 = I2C_WRITE;
	test_i2c_rw_2 = I2C_WRITE;

	i2c_data.delete;
	repeat(11)  i2c_data.push_back( 100 );
	void'(i2c_read_trans.set_data( i2c_data ));

	$display("         DIRECT TEST FOR I2C COVERAGE          ");

	fork: test_1
		begin
			foreach(test_i2c_addr[i])begin
				foreach(test_transfer_size[j])begin
					if(test_i2c_rw_1 == I2C_WRITE)begin
						i2c_agt0.bl_put( i2c_write_trans );
					end else begin
						i2c_agt0.bl_put( i2c_read_trans );
					end
					$cast( test_i2c_rw_1, !test_i2c_rw_1);
				end 
			end 
		end
		begin
			foreach(test_i2c_addr[i])begin
				foreach(test_transfer_size[j])begin
					if(test_i2c_rw_2 == I2C_WRITE)begin
						wb_agt0.bl_put(cmd_start_trans);
						WB_address( I2C_WRITE, test_i2c_addr[i] );
						repeat(test_transfer_size[j]) WB_write_byte( trans_w[DPR].set_data( 100 ) );
						wb_agt0.bl_put(cmd_stop_trans);
					end else begin
						wb_agt0.bl_put(cmd_start_trans);
						WB_address( I2C_READ, test_i2c_addr[i] );
						for(k=0;k<test_transfer_size[j];k=k+1) WB_read_byte( k == (test_transfer_size[j]-1) );
						wb_agt0.bl_put(cmd_stop_trans);
					end
					$cast( test_i2c_rw_2, !test_i2c_rw_2);
				end 
			end 
		end
	join
	disable test_1;

	$display("                DIRECT TEST FOR WB COVERAGE              ");

	i2c_data.delete;
	i2c_data.push_back( 0 );
	void'(i2c_read_trans.set_data(i2c_data));

	fork: test_2
	   		begin
				i2c_agt0.bl_put( i2c_write_trans );
				i2c_agt0.bl_put( i2c_write_trans );

                i2c_agt0.bl_put( i2c_read_trans );
				i2c_agt0.bl_put( i2c_read_trans );
				i2c_agt0.bl_put( i2c_read_trans );
				i2c_agt0.bl_put( i2c_read_trans );

            end
	join_none
				
				test_cmd_arr.push_back(CMD_SET_BUS);	test_dpr_arr.push_back(12);
				test_cmd_arr.push_back(CMD_SET_BUS);	test_dpr_arr.push_back(8);
				test_cmd_arr.push_back(CMD_STOP);		test_dpr_arr.push_back(0);
				test_cmd_arr.push_back(CMD_SET_BUS);	test_dpr_arr.push_back(0);
				test_cmd_arr.push_back(CMD_WAIT);		test_dpr_arr.push_back(0);
			   	test_cmd_arr.push_back(CMD_WAIT);		test_dpr_arr.push_back(0);
			   	test_cmd_arr.push_back(CMD_SET_BUS);	test_dpr_arr.push_back(I2C_BUS_ID);
				test_cmd_arr.push_back(CMD_START);		test_dpr_arr.push_back(0);
				test_cmd_arr.push_back(CMD_START);		test_dpr_arr.push_back(0);
				test_cmd_arr.push_back(CMD_WRITE);		test_dpr_arr.push_back(0);
				test_cmd_arr.push_back(CMD_WRITE);		test_dpr_arr.push_back(128);
			   	test_cmd_arr.push_back(CMD_START);		test_dpr_arr.push_back(0);
			   	test_cmd_arr.push_back(CMD_WRITE);		test_dpr_arr.push_back(I2C_WRITE );
			   	test_cmd_arr.push_back(CMD_WRITE);		test_dpr_arr.push_back(192);
			   	test_cmd_arr.push_back(CMD_STOP);		test_dpr_arr.push_back(0);
				test_cmd_arr.push_back(CMD_START);		test_dpr_arr.push_back(0);
				test_cmd_arr.push_back(CMD_WRITE);		test_dpr_arr.push_back(I2C_READ);
				test_cmd_arr.push_back(CMD_READ_W_NAK);	test_dpr_arr.push_back(0);
				test_cmd_arr.push_back(CMD_START);		test_dpr_arr.push_back(0);
				test_cmd_arr.push_back(CMD_WRITE);		test_dpr_arr.push_back(I2C_READ);
				test_cmd_arr.push_back(CMD_READ_W_AK);	test_dpr_arr.push_back(0);
				test_cmd_arr.push_back(CMD_READ_W_AK);	test_dpr_arr.push_back(0);
				test_cmd_arr.push_back(CMD_READ_W_NAK);	test_dpr_arr.push_back(0);
				test_cmd_arr.push_back(CMD_STOP);		test_dpr_arr.push_back(0);
			   	test_cmd_arr.push_back(CMD_WAIT);		test_dpr_arr.push_back(0);
				test_cmd_arr.push_back(CMD_STOP);		test_dpr_arr.push_back(0);
			   	test_cmd_arr.push_back(CMD_WAIT);		test_dpr_arr.push_back(0);
			   	test_cmd_arr.push_back(CMD_START);		test_dpr_arr.push_back(0);
			   	test_cmd_arr.push_back(CMD_WRITE);		test_dpr_arr.push_back(I2C_READ);
				test_cmd_arr.push_back(CMD_READ_W_AK);	test_dpr_arr.push_back(0);
			   	test_cmd_arr.push_back(CMD_START);		test_dpr_arr.push_back(0);
			   	test_cmd_arr.push_back(CMD_WRITE);		test_dpr_arr.push_back(I2C_READ);
				test_cmd_arr.push_back(CMD_READ_W_AK);	test_dpr_arr.push_back(0);
				test_cmd_arr.push_back(CMD_STOP);		test_dpr_arr.push_back(0);


				for( ;test_cmd_arr.size() > 0 ; )begin
					wb_agt0.bl_put( trans_w[DPR].set_data( test_dpr_arr.pop_front() ) );
					wb_agt0.bl_put( trans_w[CMDR].set_data( test_cmd_arr.pop_front() ) );
					wb_agt0.bl_put_ref( trans_r[DPR] );
				 wb_agt0.bl_put_ref( trans_r[CSR] );
				 wb_agt0.bl_put_ref( trans_r[CMDR] );
				 wb_agt0.bl_put_ref( trans_r[FSMR] );
				end

	$display("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
    $display("           I2CMB DIRECT TESTS PASSED          ");
    $display("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++");

endtask

task reset_core_to_idle_state;
	wb_agt0.bl_put( trans_w[CSR].set_data( (~CSR_E) ) );   
	wb_agt0.bl_put( cmd_en_trans );   
	wb_agt0.bl_put( trans_w[DPR].set_data( I2C_BUS_ID ) );
	wb_agt0.bl_put( trans_w[CMDR].set_data( {5'b0,CMD_SET_BUS} ) );
endtask

endclass
