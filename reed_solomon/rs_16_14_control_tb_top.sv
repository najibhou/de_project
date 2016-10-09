// ----------------------
// Yann Oddos - 2016
// ----------------------

module rs_16_14_control_tb_top();
`define MAX_RAM_DEPTH 256

// SYNCHRO
logic tb_clk;
logic tb_rst_n;
// ON CHIP MEMORY INTERFACE
logic [31:0] tb_ram_data_dutout;
logic [31:0] tb_ram_data_dutinp;
logic tb_ram_wr_en;
logic tb_ram_rd_en;
logic [7:0] tb_ram_address;
// EXTERNAL_CONTROL INTERFACE
logic tb_start_encode;
logic tb_start_decode;
// HPS INTERFACE
logic tb_hps_mem_stb;
logic tb_hps_mem_write;
logic [31:0] tb_hps_mem_wdata;
logic [7:0] tb_hps_mem_addr;
logic [31:0] tb_hps_mem_rdata;
logic tb_hps_rs_exec;
logic tb_hps_rs_en_decn;
logic [7:0] tb_hps_rs_addr;
logic tb_dec_cerr;
logic tb_dec_ncerr;
// DEBUG INTERFACE
logic [7:0] tb_debug;
logic tb_encode_done;
logic tb_decode_done;

logic [127:0] rs_data_table[64];
int rs_data_table_index;
logic [31:0] ram_contents[`MAX_RAM_DEPTH];


logic         tb_avalon_chipselect;
logic         tb_avalon_read;
logic         tb_avalon_write;
logic [31:0]  tb_avalon_address;
logic [31:0]  tb_avalon_writedata;
logic [31:0]  tb_avalon_readdata;
logic         tb_avalon_readdatavalid;
logic         tb_avalon_waitrequest;
logic         tb_hps_mem_rdy;


  rs_16_14_control CONTROL_INST
	(
    // SYNCHRO
    .clk_i			              (tb_clk),
    .rst_n_i		              (tb_rst_n),
    // ON CHIP MEMORY INTERFACE
    .ram_data_o               (tb_ram_data_dutout),
    .ram_data_i               (tb_ram_data_dutinp),
    .ram_wr_en_o              (tb_ram_wr_en),
    .ram_rd_en_o              (tb_ram_rd_en),
    .ram_address_o            (tb_ram_address),
    // EXTERNAL_CONTROL INTERFACE
    .start_encode_i           (tb_start_encode),
    .start_decode_i           (tb_start_decode),
    .encode_done_o            (tb_encode_done),
    .decode_done_o            (tb_decode_done),
    .dec_cerr_o		            (tb_dec_cerr),
    .dec_ncerr_o		          (tb_dec_ncerr),
    // HPS INTERFACE
    .hps_mem_stb_i            (tb_hps_mem_stb),
    .hps_mem_write_i          (tb_hps_mem_write),
    .hps_mem_wdata_i          (tb_hps_mem_wdata),
    .hps_mem_addr_i           (tb_hps_mem_addr),
    .hps_mem_rdata_o          (tb_hps_mem_rdata),
    .hps_mem_rdy_o            (tb_hps_mem_rdy),
    .hps_rs_exec_i	          (tb_hps_rs_exec),
    .hps_rs_en_decn_i         (tb_hps_rs_en_decn),
    .hps_rs_addr_i	          (tb_hps_rs_addr),
    .debug_o                  ()
	);
  
  hps_rs_control_bridge
  #(
    .SLAVE_ADDR_BITWIDTH (32)
  )
  hps_rs_control_bridge_inst
  (
    .aresetn_i               (tb_rst_n),
    .aclk_i                  (tb_clk),
    //AXI WRITE address channel
    .chipselect_i            (tb_avalon_chipselect),
    .read_i                  (tb_avalon_read),
    .write_i                 (tb_avalon_write),
    .address_i               (tb_avalon_address),
    .writedata_i             (tb_avalon_writedata),
    .readdata_o              (tb_avalon_readdata),
    .readdatavalid_o         (tb_avalon_readdatavalid),
    .waitrequest_o           (tb_avalon_waitrequest),
    //RS_CONTROL INTF
    .hps_mem_stb_o           (tb_hps_mem_stb),
    .hps_mem_write_o         (tb_hps_mem_write),
    .hps_mem_wdata_o         (tb_hps_mem_wdata),
    .hps_mem_addr_o          (tb_hps_mem_addr),
    .hps_mem_rdata_i         (tb_hps_mem_rdata),
    .hps_mem_rdy_i           (tb_hps_mem_rdy),
    .hps_rs_exec_o	         (tb_hps_rs_exec),
    .hps_rs_en_decn_o        (tb_hps_rs_en_decn),
    .hps_rs_addr_o	         (tb_hps_rs_addr)
  );
  
  assign tb_start_encode = 0;
  assign tb_start_decode = 0;
  
  initial begin
    fork 
      model_ram();
    join_none;
    tb_rst_n <= 0;
    #20us;
    tb_rst_n <= 1;
  end
  
  initial begin
    tb_clk <= 0;
    forever begin
      tb_clk <= 0;
      #10ns;
      tb_clk <= 1;
      #10ns;
    end
  end
  
  initial begin
    int crt_address;
    #10us;
    load_ram();
    crt_address=0;
    #100us;
    perform_encoding(8'h0);//2 last bytes will be used for the codes
    #200us;
    crt_address+=4;
    perform_encoding(8'h4);//2 last bytes will be used for the codes
    #200us;
    crt_address+=4;
    perform_encoding(8'h8);//2 last bytes will be used for the codes
    #200us;
    crt_address+=4;
    for(int rs_data_table_index=0;rs_data_table_index<16;rs_data_table_index++)begin
      insert_idle_cycles($urandom_range(0,256));
      perform_encoding(crt_address);
      crt_address+=4;
    end//for
    #200us;
    crt_address=0;
    perform_decoding(8'h0);//2 last bytes will be used for the codes
    #200us;
    crt_address+=4;
    perform_decoding(8'h4);//2 last bytes will be used for the codes
    #200us;
    crt_address+=4;
    perform_decoding(8'h8);//2 last bytes will be used for the codes
    #200us;
    crt_address+=4;
    for(int rs_data_table_index=0;rs_data_table_index<16;rs_data_table_index++)begin
      insert_idle_cycles($urandom_range(0,256));
      perform_decoding(crt_address);
      crt_address+=4;
    end//for
  end
  
  task perform_encoding(bit [7:0] ram_address);
    wait(tb_rst_n==1);
    @(posedge tb_clk);
    $display("[perform_encoding]:: START ENCODING @%h",ram_address);
    avalon_master_encode(ram_address);
    wait(tb_encode_done);
    @(negedge tb_clk);
    $display("[perform_encoding]:: Encoding result %h",tb_ram_data_dutout);
    @(negedge tb_clk);
    $display("[perform_encoding]:: Encoding result %h",tb_ram_data_dutout);
    @(negedge tb_clk);
    $display("[perform_encoding]:: Encoding result %h",tb_ram_data_dutout);
    @(negedge tb_clk);
    $display("[perform_encoding]:: Encoding result %h",tb_ram_data_dutout);
  endtask : perform_encoding
  
  task perform_decoding(bit [7:0] ram_address);
    wait(tb_rst_n==1);
    @(posedge tb_clk);
    $display("[perform_decoding]:: START DECODING @%h",ram_address);
    avalon_master_decode(ram_address);
    wait(tb_decode_done);
  endtask : perform_decoding
  
  task load_ram();
    int crt_data1;
    int crt_data2;
    int crt_data3;
    int crt_data4;
    int crt_address;
    
    $display("[LOAD_RAM]:: START...");
    crt_address=0;
    rs_data_table[0][31:0]  =32'h89ABEFC5;
    rs_data_table[0][63:32] =32'h01234567;
    rs_data_table[0][95:64] =32'h89ABCDEF;
    rs_data_table[0][127:96]=32'h01234567;
    load_rs_block(crt_address,rs_data_table[0]);//clean
    
    crt_address+=4;
    rs_data_table[1][31:0]  =32'h89AB0000;
    rs_data_table[1][63:32] =32'h01234567;
    rs_data_table[1][95:64] =32'h89ABCDEF;
    rs_data_table[1][127:96]=32'h01234567;
    load_rs_block(crt_address,rs_data_table[1]);//cerr
    
    crt_address+=4;
    rs_data_table[2][31:0]  =32'h89AB00C5;
    rs_data_table[2][63:32] =32'h01DD4567;
    rs_data_table[2][95:64] =32'h89FFFDEF;
    rs_data_table[2][127:96]=32'h01234567;
    load_rs_block(crt_address,rs_data_table[2]);//ncerr
    crt_address+=4;
    
    
    for(rs_data_table_index=3;rs_data_table_index<32;rs_data_table_index++)begin
      crt_data1=$urandom();
      crt_data2=$urandom();
      crt_data3=$urandom();
      crt_data4=$urandom();
      rs_data_table[rs_data_table_index][31:0]=crt_data1;
      rs_data_table[rs_data_table_index][63:32]=crt_data2;
      rs_data_table[rs_data_table_index][95:64]=crt_data3;
      rs_data_table[rs_data_table_index][127:96]=crt_data4;
      rs_data_table[rs_data_table_index][15:0]=16'h0000;
      load_rs_block(crt_address,rs_data_table[rs_data_table_index]);
      crt_address+=4;
    end
    $display("[LOAD_RAM]:: FINISHED");
  endtask : load_ram
  
  task load_rs_block(bit [7:0] address, bit [127:0] rs_block);
    bit [31:0] data;
    $display("[LOAD_RAM]:: LOAD @%h  value %h",address,rs_block);
    avalon_master_write(address,rs_block[127:96]);
    avalon_master_write(address+1,rs_block[95:64]);
    avalon_master_write(address+2,rs_block[63:32]);
    avalon_master_write(address+3,rs_block[31:0]);
    insert_idle_cycles($urandom_range(0,4));
    avalon_master_read(address,data);
    if(data!=rs_block[127:96])$error("[LOAD_RS_BLOCK]:: Invalid data written in memory @%h. Read %h, expected %h",address,data,rs_block[127:96]);
    avalon_master_read(address+1,data);
    if(data!=rs_block[95:64])$error("[LOAD_RS_BLOCK]:: Invalid data written in memory. Read %h, expected %h",address+1,data,rs_block[95:64]);
    insert_idle_cycles($urandom_range(0,4));
    avalon_master_read(address+2,data);
    if(data!=rs_block[63:32])$error("[LOAD_RS_BLOCK]:: Invalid data written in memory. Read %h, expected %h",address+2,data,rs_block[63:32]);
    insert_idle_cycles($urandom_range(0,4));
    avalon_master_read(address+3,data);
    if(data!=rs_block[31:0])$error("[LOAD_RS_BLOCK]:: Invalid data written in memory. Read %h, expected %h",address+3,data,rs_block[31:0]);
  endtask : load_rs_block
  
  task insert_idle_cycles(int nb_cycles);
    repeat(nb_cycles)avalon_master_idle();
  endtask : insert_idle_cycles
  
  
  task model_ram();
    for(int index=0;index<`MAX_RAM_DEPTH;index++)begin
      ram_contents[index] <= 0;
    end
    wait(tb_rst_n);
    forever begin
      @(posedge tb_clk);
      if(tb_ram_wr_en)begin //RAM WRITE
        ram_contents[tb_ram_address] <= tb_ram_data_dutout;
      end//RAM WRITE
      else if(tb_ram_rd_en)begin//RAM READ
        tb_ram_data_dutinp <= ram_contents[tb_ram_address];
      end//RAM READ
      else begin
        tb_ram_data_dutinp<=0;
      end//NO OPERATION
    end//forever
  endtask :  model_ram
  
  task avalon_master_idle();
    @(posedge tb_clk);
    tb_avalon_chipselect  <= 0;
    tb_avalon_write       <= 0;
    tb_avalon_read        <= 0;
    tb_avalon_address     <= 0;
    tb_avalon_writedata   <= 0;
  endtask : avalon_master_idle
  
  task avalon_master_write(bit [7:0] address, int data);
    wait(tb_rst_n);
    @(posedge tb_clk);
    $display("[AVALON_MASTER_WRITE]:: Writing data %h @%h",data,address);
    tb_avalon_chipselect    <= 1;
    tb_avalon_write         <= 1;
    tb_avalon_read          <= 1;
    tb_avalon_address[7:0]  <= address;
    tb_avalon_address[10:8] <= "000";//WRITE INTO ONCHIP MEM
    tb_avalon_address[31:11]<= 0;
    tb_avalon_writedata     <= data;
    wait(tb_avalon_waitrequest==0);
  endtask : avalon_master_write
  
  task avalon_master_read(input bit [7:0] address, output int data);
    wait(tb_rst_n);
    @(posedge tb_clk);
    tb_avalon_chipselect    <= 1;
    tb_avalon_write         <= 0;
    tb_avalon_read          <= 1;
    tb_avalon_address[7:0]  <= address;
    tb_avalon_address[31:8] <= "000";//WRITE INTO ONCHIP MEM
    while(tb_avalon_readdatavalid==0)begin
      @(posedge tb_clk);
    end
    //@(posedge tb_clk);
    tb_avalon_chipselect  <= 0;
    tb_avalon_write       <= 0;
    tb_avalon_address     <= 0;
    tb_avalon_writedata   <= 0;
    data                  = tb_avalon_readdata;
    $display("[AVALON_MASTER_READ]:: Reading data @%h is %h",address,data);
  endtask : avalon_master_read
  
  
  task avalon_master_encode(bit [7:0] address);
    wait(tb_rst_n);
    @(posedge tb_clk);
    $display("[AVALON_MASTER_ENCODE]:: START Encoding data from %h",address);
    tb_avalon_chipselect    <= 1;
    tb_avalon_write         <= 1;
    tb_avalon_read          <= 0;
    tb_avalon_address[31:11]<= 0;
    tb_avalon_address[10:8] <= 3'b011;//ENCODE START
    tb_avalon_address[7:0]  <= address;
    tb_avalon_writedata     <= 0;
    @(posedge tb_clk);
    tb_avalon_chipselect  <= 0;
    tb_avalon_write       <= 0;
    tb_avalon_address     <= 0;
    tb_avalon_writedata   <= 0;
    tb_avalon_read        <= 0;
  endtask : avalon_master_encode
  
  task avalon_master_decode(bit [7:0] address);
    wait(tb_rst_n);
    @(posedge tb_clk);
    $display("[AVALON_MASTER_DECODE]:: START Decoding data from %h",address);
    tb_avalon_chipselect    <= 1;
    tb_avalon_write         <= 1;
    tb_avalon_read          <= 0;
    tb_avalon_address[7:0]  <= address;
    tb_avalon_address[10:8] <= 3'b010;//DECODE START
    tb_avalon_address[31:11]<= 0;
    tb_avalon_writedata     <= 0;
    @(posedge tb_clk);
    tb_avalon_chipselect  <= 0;
    tb_avalon_write       <= 0;
    tb_avalon_address     <= 0;
    tb_avalon_writedata   <= 0;
    tb_avalon_read        <= 0;
  endtask : avalon_master_decode

endmodule;