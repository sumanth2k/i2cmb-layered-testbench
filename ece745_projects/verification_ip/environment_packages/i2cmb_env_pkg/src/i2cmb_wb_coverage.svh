class i2cmb_coverage_wb extends ncsu_component #(.T(wb_transaction));

i2cmb_env_configuration cfg0;

iicmb_reg_ofst_t wb_addr;
iicmb_cmdr_t iicmb_cmd;
wb_op_t wb_op;
bit [WB_DATA_WIDTH-1:0] wb_data;
CSR_REG csr_reg;
event sample_wb;
event sample_CSR;
event sample_DPR;


covergroup env_coverage @(sample_wb);
	wb_addr_offset: coverpoint wb_addr; 	
	wb_operation: coverpoint wb_op; 		
	wb_addrXop: cross wb_addr_offset, wb_operation;
endgroup

covergroup CSR_coverage @(sample_CSR);
	CSR_Enable_bit: coverpoint csr_reg.e;
	CSR_Interrupt_Enable_bit: coverpoint csr_reg.ie;
	CSR_Bus_Busy_bit: coverpoint csr_reg.bb;
	CSR_Bus_Captured_bit: coverpoint csr_reg.bc;
	CSR_Bus_ID_bits: coverpoint csr_reg.bus_id { option.auto_bin_max = 4; }
endgroup

covergroup DPR_coverage @(sample_DPR);
	DPR_Data_Value: coverpoint wb_data { option.auto_bin_max = 4; }
endgroup


function void set_configuration(i2cmb_env_configuration cfg);
	cfg0 = cfg;
endfunction

function new(string name= "", ncsu_component_base parent = null);
	super.new(name, parent);
	env_coverage = new;
	CSR_coverage = new;
	DPR_coverage = new;
endfunction

virtual function void nb_put(T trans);
	if(trans.get_type_handle()==wb_transaction::get_type())begin
		$cast( wb_op , trans.get_op());
		$cast( wb_addr, trans.get_addr());
		wb_data =  trans.get_data_0();
		{csr_reg.e, csr_reg.ie, csr_reg.bb, csr_reg.bc, csr_reg.bus_id} = wb_data;
		if(wb_addr==CSR)	->>sample_CSR;
		if(wb_addr==DPR) ->>sample_DPR;
		->>sample_wb;
	end
endfunction


endclass
