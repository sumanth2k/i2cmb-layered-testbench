make clean
make compile
make run_cli
make run_cli GEN_TYPE=i2cmb_generator_register_test TEST_SEED=1234567890
make run_cli GEN_TYPE=i2cmb_generator_fsm_functionality_test TEST_SEED=1234567890
# make run_cli GEN_TYPE=i2cmb_generator_direct_test
# make run_cli GEN_TYPE=i2cmb_generator_random_test TEST_SEED=1234567890
make merge_coverage 
make view_coverage