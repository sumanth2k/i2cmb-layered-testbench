
class i2cmb_generator_register_test extends i2cmb_generator;
`ncsu_register_object(i2cmb_generator_register_test)

bit [7:0] reset_value[iicmb_reg_ofst_t];
bit [7:0] mask_value[iicmb_reg_ofst_t]; 

function new(string name="", ncsu_component_base parent=null);
	super.new(name, parent);

	reset_value[CSR] = 8'h00;
	reset_value[DPR] = 8'h00;
	reset_value[CMDR] = 8'h80;
	reset_value[FSMR] = 8'h00;
	mask_value[CSR] = 8'hc0;
	mask_value[DPR] = 8'h00; 
	mask_value[CMDR] = 8'h17;
	mask_value[FSMR] = 8'h00;

endfunction

virtual task run();

    $display("+++++++++++++++++++++++++++++++++++++++++++++++++++++++");
    $display("                 REGISTER BLOCK TEST START          ");
    $display("+++++++++++++++++++++++++++++++++++++++++++++++++++++++");


    $display("----------------TEST REGISTER RESET VALUE AFTER SYSTEM RESET----------------");

    for(int i=3; i>=0 ;i--)begin
        automatic iicmb_reg_ofst_t addr_ofst = iicmb_reg_ofst_t'(i);
        super.wb_agt0.bl_put_ref(trans_r[addr_ofst]);
        assert(trans_r[addr_ofst].wb_data == reset_value[addr_ofst])  $display("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b CORRECT", map_reg_ofst_name[addr_ofst], trans_r[addr_ofst].wb_data);
    	else $fatal("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b INCORRECT", map_reg_ofst_name[addr_ofst],trans_r[addr_ofst].wb_data);
    end

    void'(trans_w[CSR].set_data( CSR_E | CSR_IE));
	super.wb_agt0.bl_put_ref(trans_w[CSR]);


    $display("----------------TEST REGISTER RESET VALUE AFTER ENABLE CORE----------------");

    for(int i=3; i>=0 ;i--)begin
        automatic iicmb_reg_ofst_t addr_ofst = iicmb_reg_ofst_t'(i);
        super.wb_agt0.bl_put_ref(trans_r[addr_ofst]);
        if(addr_ofst == CSR)begin
            assert(trans_r[addr_ofst].wb_data == mask_value[CSR] )  $display("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b CORRECT", map_reg_ofst_name[iicmb_reg_ofst_t'(addr_ofst)], trans_r[addr_ofst].wb_data);
            else $fatal("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} INCORRECT :%b", map_reg_ofst_name[iicmb_reg_ofst_t'(addr_ofst)],trans_r[addr_ofst].wb_data);
        end else begin
            assert(trans_r[addr_ofst].wb_data == reset_value[addr_ofst])  $display("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b CORRECT", map_reg_ofst_name[iicmb_reg_ofst_t'(addr_ofst)], trans_r[addr_ofst].wb_data);
            else $fatal("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b INCORRECT", map_reg_ofst_name[iicmb_reg_ofst_t'(addr_ofst)],trans_r[addr_ofst].wb_data);
        end
    end


    $display("----------------TEST REGISTER ACCESS PERMISSION AFTER RESET CORE----------------");

    void'(trans_w[CSR].set_data( (~CSR_E) & (~CSR_IE) ));
    super.wb_agt0.bl_put_ref(trans_w[CSR]);

    for(int i=3; i>=0 ;i--)begin
        automatic iicmb_reg_ofst_t addr_ofst = iicmb_reg_ofst_t'(i);
        void'(trans_w[addr_ofst].set_data( 8'hff ));
        super.wb_agt0.bl_put_ref(trans_w[addr_ofst]);

        super.wb_agt0.bl_put_ref(trans_r[addr_ofst]);
        if(addr_ofst == CSR)begin
            assert(trans_r[addr_ofst].wb_data == mask_value[CSR] )  $display("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b CORRECT", map_reg_ofst_name[addr_ofst], trans_r[addr_ofst].wb_data);
            else $fatal("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b INCORRECT", map_reg_ofst_name[addr_ofst],trans_r[addr_ofst].wb_data);
        end else begin
            assert(trans_r[addr_ofst].wb_data == reset_value[addr_ofst])  $display("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b CORRECT", map_reg_ofst_name[addr_ofst], trans_r[addr_ofst].wb_data);
            else $fatal("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b INCORRECT", map_reg_ofst_name[addr_ofst],trans_r[addr_ofst].wb_data);
        end
    end

 
    $display("----------------TEST REGISTER ACCESS PERMISSION AFTER ENABLE CORE----------------");

    void'(trans_w[CSR].set_data( CSR_E | CSR_IE));
    super.wb_agt0.bl_put_ref(trans_w[CSR]);

    for(int i=3; i>=0 ;i--)begin
        automatic iicmb_reg_ofst_t addr_ofst = iicmb_reg_ofst_t'(i);
        void'(trans_w[addr_ofst].set_data( 8'hff ));
        super.wb_agt0.bl_put_ref(trans_w[addr_ofst]);

        super.wb_agt0.bl_put_ref(trans_r[addr_ofst]);
        assert(trans_r[addr_ofst].wb_data == mask_value[addr_ofst])  $display("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b CORRECT", map_reg_ofst_name[addr_ofst], trans_r[addr_ofst].wb_data);
        else $fatal("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b INCORRECT", map_reg_ofst_name[addr_ofst],trans_r[addr_ofst].wb_data);
    end
 
    $display("----------------TEST REGISTER ALIASING AFTER ENABLE CORE----------------");

    for(int i=0; i<4 ;i++)begin
        automatic iicmb_reg_ofst_t addr_ofst_1 = iicmb_reg_ofst_t'(i);
        automatic iicmb_reg_ofst_t addr_ofst_2;

        void'(trans_w[addr_ofst_1].set_data( 8'hff ));
        super.wb_agt0.bl_put_ref(trans_w[addr_ofst_1]);
        for(int k=0; k<4 ;k++)begin
            if( k == i ) continue;
            addr_ofst_2 = iicmb_reg_ofst_t'(k);
            assert(trans_r[addr_ofst_2].wb_data == mask_value[addr_ofst_2])  $display("{%s UNCHANGED WHEN WRITING TO %s} PASSED ", map_reg_ofst_name[addr_ofst_2],map_reg_ofst_name[addr_ofst_1] );
            else $fatal("{%s ALIASED WHEN WRITING TO %s} FAILED ", map_reg_ofst_name[addr_ofst_2],map_reg_ofst_name[addr_ofst_1] );
        end
    end
    $display("+++++++++++++++++++++++++++++++++++++++++++++++++++++++");
    $display("                  REGISTER BLOCK TEST PASS          ");
    $display("+++++++++++++++++++++++++++++++++++++++++++++++++++++++");

 endtask

endclass
