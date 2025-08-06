`timescale 1ns / 10ps
interface i2c_if       #(
    int I2C_ADDR_WIDTH = 7,
    int I2C_DATA_WIDTH = 8,
    int SLAVE_ADDRESS = 7'h22
)(
    input           scl_s,
    inout   triand  sda_s
);
    import i2c_pkg::*;

    logic drive_sda = 0;
    logic drive_ack = 0;
    
    assign sda_s = drive_sda ? drive_ack : 'bz;

    bit start_flag1 = 0;
    bit stop_flag1 = 0;
    bit data_flag1 = 0;


    task automatic waitforstart( ref bit flag_start_task );
        while( !flag_start_task ) @(negedge sda_s) if(scl_s) flag_start_task = 1'b1;
        flag_start_task = 1'b0;
    endtask

    task automatic waitforstop( ref bit flag_stop_task );
        while( !flag_stop_task ) @(posedge sda_s) if(scl_s) flag_stop_task = 1'b1;
        flag_stop_task = 1'b0;
    endtask


    task wait_for_i2c_transfer ( output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] write_data []);
        automatic bit [I2C_ADDR_WIDTH-1:0]      addr_pack;
        automatic bit [I2C_DATA_WIDTH-1:0]      data_pack;
        automatic bit [I2C_DATA_WIDTH-1:0]      data_packet_queue [$];
        automatic bit correct = 0;

        waitforstart( start_flag1 );
        GetAddress( op, correct, addr_pack );
        assert( correct ) begin end else $fatal("Invalid i2c slave address");
        
        @(negedge scl_s) begin drive_sda <=correct; drive_ack <=0; end
        @(posedge scl_s);

        if(!correct) 
        begin
            waitforstop( stop_flag1 );
        end 
        else if( op == I2C_WRITE ) 
        begin
            @(negedge scl_s) drive_sda =0;
            GetData( data_pack );
            data_packet_queue.push_back( data_pack );
            
            @(negedge scl_s) begin drive_sda <=correct; drive_ack <=0; end
            @(posedge scl_s);

            @(negedge scl_s) drive_sda =0;
            do begin
                data_flag1 = 0;
                fork    :   fork_in_driver
                    begin   
                        waitforstart( start_flag1 );       start_flag1 = 1;    
                    end
                    begin   
                        waitforstop( stop_flag1 );                             
                    end
                    begin   
                        GetData( data_pack );
                        data_packet_queue.push_back( data_pack );
                        data_flag1 = 1;
                        
                        @(negedge scl_s) begin drive_sda <=correct; drive_ack <=0; end
                        @(posedge scl_s);
                        @(negedge scl_s) drive_sda =0;
                    end
                join_any
                disable fork;
            end while( data_flag1 );

            write_data = new [ data_packet_queue.size() ];
            write_data = {>>{data_packet_queue}};
        end 

    endtask

    task provide_read_data ( input bit [I2C_DATA_WIDTH-1:0] read_data [], output bit transfer_complete);
        automatic bit ack =0; 
        foreach( read_data[i] ) 
        begin
            drive_data( read_data[i] );
            @(negedge scl_s) drive_sda <=0;
            @(posedge scl_s) ack = !sda_s;
            if( !ack ) 
            begin 
                fork
                    begin waitforstart( start_flag1 ); start_flag1 =1; end
                    begin waitforstop( stop_flag1 ); end
                join_any
                disable fork;
                break;
            end 
        end 
        transfer_complete = !ack;
    endtask


    bit start_flag2 = 0;
    bit stop_flag2 = 0;
    bit data_flag2 = 0;


    task monitor ( output bit [I2C_ADDR_WIDTH-1:0] addr, output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] data []);
        automatic bit [I2C_DATA_WIDTH-1:0] data_packet_queue [$];
        automatic bit [I2C_DATA_WIDTH-1:0] data_pack;
        automatic bit correct = 0;
        automatic bit ack = 0;

        waitforstart( start_flag2 );
        GetAddress( op, correct, addr );
        @(posedge scl_s);
        if(!correct) begin
            waitforstop( stop_flag2 );
        end 
        else 
        begin
            automatic bit stall = 0;
            do begin
                data_flag2 = 0;
                fork : fork_in_monitor
                    begin   wait(stall); waitforstart( start_flag2 ); start_flag2 = 1; end
                    begin   wait(stall); waitforstop( stop_flag2 ); end
                    begin   GetData( data_pack );
                            data_packet_queue.push_back( data_pack );
                            @(posedge scl_s);
                            data_flag2 = 1;
                    end
                join_any
                disable fork_in_monitor;
                stall = 1;
            end while( data_flag2 );
        end 
        data = new [ data_packet_queue.size() ];
        data = {>>{data_packet_queue}};
    endtask


     task automatic GetAddress( output i2c_op_t op1, output bit _correct_ , output bit [I2C_ADDR_WIDTH-1:0] addr_pack_task );
        automatic bit queue[$];
        repeat(I2C_ADDR_WIDTH) @(posedge scl_s) begin queue.push_back(sda_s); end
        addr_pack_task = {>>{queue}};
        @(posedge scl_s) op1 = i2c_op_t'(sda_s);
        _correct_ = 1'b1;
    endtask

     task automatic GetData( output bit [I2C_DATA_WIDTH-1:0] data_pack_task );
        automatic bit queue[$];
        repeat(I2C_DATA_WIDTH) @(posedge scl_s) begin queue.push_back(sda_s); end
        data_pack_task = {>>{queue}};
    endtask


     task automatic drive_data( input bit [I2C_DATA_WIDTH-1:0] read_data_task );
        foreach( read_data_task[j] ) begin
            @(negedge scl_s) drive_sda <=1; drive_ack <= read_data_task[j];
        end
    endtask


endinterface







