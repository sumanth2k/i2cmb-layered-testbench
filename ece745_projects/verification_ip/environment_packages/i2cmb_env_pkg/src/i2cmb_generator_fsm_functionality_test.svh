class i2cmb_generator_fsm_functionality_test extends i2cmb_generator;
	`ncsu_register_object(i2cmb_generator_fsm_functionality_test)

time time_start,time_end;
bit [7:0] wait_time;

function new(string name="", ncsu_component_base parent=null);
	super.new(name, parent);
endfunction

virtual task run();

  
	$display("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
    $display("             I2CMB FSM FUNCTIONALITY TESTS START          ");
    $display("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++");

	i2c_data.push_back( 100 );
	i2c_data.push_back( 101 );
	void'(i2c_read_trans.set_data(i2c_data));

	fork   begin i2c_agt0.bl_put( i2c_read_trans ); end join_none
	$display(" --------------------TEST FOR OPERATION IN BYTE FSM IDLE STATE--------------------");
	wb_agt0.bl_put_ref( cmd_en_trans );   
    check_FSM_state(`__LINE__, S_IDLE);


    wb_agt0.bl_put_ref( cmd_stop_trans );     
    check_err_bit( `__LINE__, cmd_stop_trans,"REQUESTING STOP COMMAND IN IDLE STATE");
    check_FSM_state(`__LINE__, S_IDLE);

	void'( trans_w[CMDR].set_data( {5'b0, CMD_READ_W_AK } ));
    wb_agt0.bl_put_ref( trans_w[CMDR] );    
    check_err_bit( `__LINE__, trans_w[CMDR], "REQUESTING READ ACK COMMAND IN IDLE STATE");
    check_FSM_state(`__LINE__, S_IDLE);

	void'( trans_w[CMDR].set_data( {5'b0, CMD_READ_W_NAK } ) );
    wb_agt0.bl_put_ref( trans_w[CMDR] );    
    check_err_bit( `__LINE__, trans_w[CMDR], "REQUESTING READ NAK COMMAND IN IDLE STATE");
    check_FSM_state(`__LINE__, S_IDLE);

    wb_agt0.bl_put_ref( cmd_write_trans );    
    check_err_bit( `__LINE__, cmd_write_trans, "REQUESTING WRITE COMMAND IN IDLE STATE");
    check_FSM_state(`__LINE__, S_IDLE);

    wb_agt0.bl_put( trans_w[DPR].set_data( 8'h0f ) );
	void'( trans_w[CMDR].set_data( {5'b0,CMD_SET_BUS} ));
    wb_agt0.bl_put_ref( trans_w[CMDR] );
    check_err_bit( `__LINE__, trans_w[CMDR], "INVALID BUS ID");
    check_FSM_state(`__LINE__, S_IDLE);

    wb_agt0.bl_put( trans_w[DPR].set_data( I2C_BUS_ID ) );
	void'( trans_w[CMDR].set_data( {5'b0,CMD_SET_BUS} ) );
    wb_agt0.bl_put_ref( trans_w[CMDR] );
    check_don_bit( `__LINE__, trans_w[CMDR], "SETTING VALID BUS ID");

    check_FSM_state(`__LINE__, S_IDLE);


    wait_time = 8'h01;  
    wb_agt0.bl_put( trans_w[DPR].set_data( wait_time ) );
	void'( trans_w[CMDR].set_data( {5'b0, CMD_WAIT} ) );
    time_start = $time;
    wb_agt0.bl_put_ref( trans_w[CMDR] );
    time_end = $time;

    assert( ((time_end - time_start)/100000000) == wait_time ) $display("TEST CASE PASSED: WAIT TIME CORRECT");
    else $fatal("TEST CASE FAILED: WAIT TIME DURATION INCORRECT");

    check_don_bit( `__LINE__,trans_w[CMDR], "FINISHING WAIT COMMAND");
    check_FSM_state(`__LINE__, S_IDLE);


    wb_agt0.bl_put_ref( cmd_start_trans );     
    check_don_bit( `__LINE__, cmd_start_trans, "START COMMAND IN INDLE STATE");
    check_FSM_state(`__LINE__, S_BUS_TAKEN);

	$display("----------------------TEST FOR OPERATION IN BYTE FSM BUS_TAKEN STATE---------------");

	wb_agt0.bl_put_ref( cmd_start_trans );     
	check_don_bit( `__LINE__, cmd_start_trans, "START COMMAND IN TAKEN STATE");
	check_FSM_state(`__LINE__, S_BUS_TAKEN);


	wb_agt0.bl_put(trans_w[DPR].set_data( {I2C_SLAVE_ADDRESS<<1} | bit'(I2C_READ) ) ); 
	wb_agt0.bl_put_ref(cmd_write_trans); 
	check_don_bit( `__LINE__, cmd_write_trans, "WRITE COMMAND IN TAKEN STATE");
	check_FSM_state(`__LINE__,  S_BUS_TAKEN );


	void'( trans_w[CMDR].set_data( {5'b0, CMD_READ_W_AK } ) );
    wb_agt0.bl_put_ref( trans_w[CMDR] );     
    check_don_bit( `__LINE__, trans_w[CMDR], "READ ACK COMMAND IN TAKEN STATE");
    check_FSM_state(`__LINE__,  S_BUS_TAKEN );

	void'( trans_w[CMDR].set_data( {5'b0, CMD_READ_W_AK } ) );
    wb_agt0.bl_put_ref( trans_w[CMDR] );     
    check_don_bit( `__LINE__, trans_w[CMDR], "READ NAK COMMAND IN TAKEN STATE");
    check_FSM_state(`__LINE__,  S_BUS_TAKEN );

    wb_agt0.bl_put_ref( cmd_start_trans );     
    wb_agt0.bl_put_ref( cmd_stop_trans );     
    wb_agt0.bl_put_ref( trans_r[CMDR] );  
    check_FSM_state(`__LINE__, S_IDLE);

	wb_agt0.bl_put_ref( cmd_start_trans );     

    wb_agt0.bl_put( trans_w[DPR].set_data( I2C_BUS_ID ) );
	void'( trans_w[CMDR].set_data( {5'b0,CMD_SET_BUS} ) );
    wb_agt0.bl_put_ref( trans_w[CMDR] );
    check_err_bit( `__LINE__, trans_w[CMDR], "REQUESTING SET BUS ID COMMAND IN TAKEN STATE");
    check_FSM_state(`__LINE__, S_BUS_TAKEN);

    wb_agt0.bl_put( trans_w[DPR].set_data( 8'h01 ) );
	void'( trans_w[CMDR].set_data( {5'b0, CMD_WAIT} ) );
    wb_agt0.bl_put_ref( trans_w[CMDR] );
    check_err_bit( `__LINE__, trans_w[CMDR], "REQUESTING WAIT COMMAND IN TAKEN STATE");
    check_FSM_state(`__LINE__, S_BUS_TAKEN);



	$display("------------------------TEST FOR NO ACKNOWLEDGE DETECTION--------------------------");
	wb_agt0.bl_put_ref(cmd_start_trans);
	wb_agt0.bl_put( trans_w[DPR].set_data( 8'd100 ) );
	wb_agt0.bl_put_ref(cmd_write_trans);
	check_nak_bit( `__LINE__, cmd_write_trans, "NO ACKNOWLEDGE WHILE REQUESTING WRITE COMMAND IN TAKEN STATE");
	check_FSM_state(`__LINE__, S_BUS_TAKEN);

	$display("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
	$display("            I2CMB FSM FUNCTIONALITY TESTS PASSED          ");
	$display("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++");

endtask

task reset_core_to_idle_state;
	wb_agt0.bl_put( trans_w[CSR].set_data( (~CSR_E) ) );   
	wb_agt0.bl_put( cmd_en_trans );   

	wb_agt0.bl_put( trans_w[DPR].set_data( I2C_BUS_ID ) );
	wb_agt0.bl_put( trans_w[CMDR].set_data( {5'b0,CMD_SET_BUS} ) );
endtask

task reset_core_to_taken_state;
	reset_core_to_idle_state();
	wb_agt0.bl_put_ref(cmd_start_trans);
endtask


task check_FSM_state(int line, BYTE_FSM_STATE expected_state );
    automatic BYTE_FSM_STATE actual_state;
    wb_agt0.bl_put_ref( trans_r[FSMR] );
    actual_state = to_fsmr_reg(trans_r[FSMR].wb_data).byte_fsm;
    assert( actual_state == expected_state ) begin end
    else $fatal("TEST CASE FAILED: EXPECTED BYTE FSM STATE: %s , INSTEAD BYTE FSM STATE IS SET: %s", map_state_name[expected_state], map_state_name[actual_state] );
endtask

task check_don_bit(int line, wb_transaction trans, string msg="TBD");

    assert( to_cmdr_reg(trans.cmdr_data).don ) $display( "TEST CASE PASSED: {DON BIT} ASSERTED AS EXPECTED DUE TO %s",msg);
    else $fatal("TEST CASE FAILED: EXPECTED {DON BIT} ASSERTED DUE TO %s, INSTEAD DONE IS 0 !.",msg);
endtask

task check_err_bit(int line, wb_transaction trans, string msg="TBD");

    assert( to_cmdr_reg(trans.cmdr_data).err ) $display("TEST CASE PASSED: {ERR BIT} ASSERTED AS EXPECTED DUE TO %s",msg);
    else $fatal("TEST CASE FAILED: EXPECTED {ERR BIT} ASSERTED DUE TO %s, INSTEAD DONE IS SET",msg);
endtask

task check_al_bit(int line, wb_transaction trans, string msg="TBD");

    assert( !to_cmdr_reg(trans.cmdr_data).don && to_cmdr_reg(trans.cmdr_data).al ) $display("TEST CASE PASSED: {AL BIT} ASSERTED AS EXPECTED DUE TO %s",msg);
    else $fatal("TEST CASE FAILED: EXPECTED {AL BIT} ASSERTED DUE TO %s, INSTEAD DONE IS SET",msg);
endtask

task check_nak_bit(int line, wb_transaction trans, string msg="TBD");

    assert( !to_cmdr_reg(trans.cmdr_data).don && to_cmdr_reg(trans.cmdr_data).nak ) $display("TEST CASE PASSED: {NAK BIT} ASSERTED AS EXPECTED DUE TO %s",msg);
    else $fatal("TEST CASE FAILED: EXPECTED {NAK BIT} ASSERTED DUE TO %s, INSTEAD DONE IS SET",msg);
endtask

endclass
