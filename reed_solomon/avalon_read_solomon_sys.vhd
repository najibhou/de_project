-- ----------------------
-- Yann Oddos - 2016
-- ----------------------

library ieee;
	use ieee.std_logic_1164.all;
  
entity avalon_read_solomon_sys is
generic(
  SLAVE_ADDR_BITWIDTH : integer :=  8
);
port(
  aresetn_i               : in std_ulogic;
  aclk_i                  : in std_ulogic;
  --AXI WRITE address channel
  chipselect_i            : in   std_ulogic;
  read_i                  : in   std_ulogic;
  write_i                 : in   std_ulogic;
  address_i               : in   std_ulogic_vector(SLAVE_ADDR_BITWIDTH-1 downto 0);
  writedata_i             : in   std_ulogic_vector(31 downto 0);
  readdata_o              : out  std_ulogic_vector(31 downto 0);
  readdatavalid_o         : out  std_ulogic;
  waitrequest_o           : out  std_ulogic;
	-- EXTERNAL_CONTROL INTERFACE
	start_encode_i          : in  std_ulogic;
	start_decode_i          : in  std_ulogic;
  encode_done_o           : out std_ulogic;
  decode_done_o           : out std_ulogic;
	dec_cerr_o		          : out std_ulogic;					--! Single error detected and corrected
	dec_ncerr_o		          : out std_ulogic;					--! Double error detected
	debug_o                 : out std_ulogic_vector(2 downto 0)
  
);
end entity avalon_read_solomon_sys;


architecture rtl of avalon_read_solomon_sys is

component hps_rs_control_bridge
generic(
  SLAVE_ADDR_BITWIDTH : integer :=  8
);
port(
  aresetn_i               : in std_ulogic;
  aclk_i                  : in std_ulogic;
  --AXI WRITE address channel
  chipselect_i            : in   std_ulogic;
  read_i                  : in   std_ulogic;
  write_i                 : in   std_ulogic;
  address_i               : in   std_ulogic_vector(SLAVE_ADDR_BITWIDTH-1 downto 0);
  writedata_i             : in   std_ulogic_vector(31 downto 0);
  readdata_o              : out  std_ulogic_vector(31 downto 0);
  readdatavalid_o         : out  std_ulogic;
  waitrequest_o           : out  std_ulogic;
  --RS_CONTROL INTF
	hps_mem_stb_o           : out  std_ulogic;
	hps_mem_write_o         : out  std_ulogic;
	hps_mem_wdata_o         : out  std_ulogic_vector(31 downto 0);
	hps_mem_addr_o          : out  std_ulogic_vector(7 downto 0);
	hps_mem_rdata_i         : in   std_ulogic_vector(31 downto 0);
  hps_mem_rdy_i           : in   std_ulogic;
	hps_rs_exec_o	          : out  std_ulogic;
	hps_rs_en_decn_o        : out  std_ulogic;
	hps_rs_addr_o	          : out  std_ulogic_vector(7 downto 0)
);
end component;

component rs_16_14_control
	port(
	-- SYNCHRO
	clk_i			              : in std_ulogic;						--! global clk
	rst_n_i		              : in std_ulogic;						--! reset active low
	-- ON CHIP MEMORY INTERFACE
	ram_data_o              : out std_ulogic_vector(31 downto 0);
	ram_data_i              : in  std_ulogic_vector(31 downto 0);
	ram_wr_en_o             : out std_ulogic;
	ram_rd_en_o             : out std_ulogic;
	ram_address_o           : out std_ulogic_vector(7 downto 0);
	-- EXTERNAL_CONTROL INTERFACE
	start_encode_i          : in  std_ulogic;
	start_decode_i          : in  std_ulogic;
  encode_done_o           : out std_ulogic;
  decode_done_o           : out std_ulogic;
	dec_cerr_o		          : out std_ulogic;					--! Single error detected and corrected
	dec_ncerr_o		          : out std_ulogic;					--! Double error detected
	-- HPS INTERFACE
	hps_mem_stb_i           : in  std_ulogic;
	hps_mem_write_i         : in  std_ulogic;
	hps_mem_wdata_i         : in  std_ulogic_vector(31 downto 0);
	hps_mem_addr_i          : in  std_ulogic_vector(7 downto 0);
	hps_mem_rdata_o         : out std_ulogic_vector(31 downto 0);
  hps_mem_rdy_o           : out std_ulogic;
	hps_rs_exec_i	          : in  std_ulogic;
	hps_rs_en_decn_i        : in  std_ulogic;
	hps_rs_addr_i	          : in  std_ulogic_vector(7 downto 0);
  debug_o                 : out std_ulogic_vector(2 downto 0)
	);
end component;

component ram32w
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		rden		: IN STD_LOGIC  := '1';
		wren		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
end component;


signal ram_data_o_ulogic_s     : std_ulogic_vector(31 downto 0);
signal ram_data_o_logic_s      : std_logic_vector(31 downto 0);
signal ram_data_i_ulogic_s     : std_ulogic_vector(31 downto 0);
signal ram_data_i_logic_s      : std_logic_vector(31 downto 0);
signal ram_wr_en_ulogic_s      : std_ulogic;
signal ram_wr_en_logic_s       : std_logic;
signal ram_rd_en_ulogic_s      : std_ulogic;
signal ram_rd_en_logic_s       : std_logic;
signal ram_address_ulogic_s    : std_ulogic_vector(7 downto 0);
signal ram_address_logic_s     : std_logic_vector(7 downto 0);


signal hps_mem_stb_s           : std_ulogic;
signal hps_mem_write_s         : std_ulogic;
signal hps_mem_wdata_s         : std_ulogic_vector(31 downto 0);
signal hps_mem_addr_s          : std_ulogic_vector(7 downto 0);
signal hps_mem_rdata_s         : std_ulogic_vector(31 downto 0);
signal hps_mem_rdy_s           : std_ulogic;


signal hps_rs_exec_s	         :  std_ulogic;
signal hps_rs_en_decn_s        :  std_ulogic;
signal hps_rs_addr_s	         :  std_ulogic_vector(7 downto 0);
begin

  i_hps_rs_control_bridge : hps_rs_control_bridge
  generic map(
    SLAVE_ADDR_BITWIDTH     =>  8
  )
  port map(
    aresetn_i               => aresetn_i,
    aclk_i                  => aclk_i,
    --AXI WRITE address channel
    chipselect_i            => chipselect_i,
    read_i                  => read_i,
    write_i                 => write_i,
    address_i               => address_i,
    writedata_i             => writedata_i,
    readdata_o              => readdata_o,
    readdatavalid_o         => readdatavalid_o,
    waitrequest_o           => waitrequest_o,
    --RS_CONTROL INTF
    hps_mem_stb_o           => hps_mem_stb_s,
    hps_mem_write_o         => hps_mem_write_s,
    hps_mem_wdata_o         => hps_mem_wdata_s,
    hps_mem_addr_o          => hps_mem_addr_s,
    hps_mem_rdata_i         => hps_mem_rdata_s,
    hps_mem_rdy_i           => hps_mem_rdy_s,
    hps_rs_exec_o	          => hps_rs_exec_s,
    hps_rs_en_decn_o        => hps_rs_en_decn_s,
    hps_rs_addr_o	          => hps_rs_addr_s
  );
  
  i_rs_16_14_control : rs_16_14_control
	port map(
    -- SYNCHRO
    clk_i			              => aclk_i,
    rst_n_i		              => aresetn_i,
    -- ON CHIP MEMORY INTERFACE
    ram_data_o              => ram_data_o_ulogic_s,
    ram_data_i              => ram_data_i_ulogic_s,
    ram_wr_en_o             => ram_wr_en_ulogic_s,
    ram_rd_en_o             => ram_rd_en_ulogic_s,
    ram_address_o           => ram_address_ulogic_s,
    -- EXTERNAL_CONTROL INTERFACE
    start_encode_i          =>start_encode_i,
    start_decode_i          =>start_decode_i,
    encode_done_o           =>encode_done_o,
    decode_done_o           =>decode_done_o,
    dec_cerr_o		          =>dec_cerr_o,
    dec_ncerr_o		          =>dec_ncerr_o,
    -- HPS INTERFACE
    hps_mem_stb_i           => hps_mem_stb_s,
    hps_mem_write_i         => hps_mem_write_s,
    hps_mem_wdata_i         => hps_mem_wdata_s,
    hps_mem_addr_i          => hps_mem_addr_s,
    hps_mem_rdata_o         => hps_mem_rdata_s,
    hps_mem_rdy_o           => hps_mem_rdy_s,
    hps_rs_exec_i	          => hps_rs_exec_s,
    hps_rs_en_decn_i        => hps_rs_en_decn_s,
    hps_rs_addr_i	          => hps_rs_addr_s,
    debug_o                 => debug_o
	);
	
	ram_data_i_ulogic_s <= to_stdulogicvector(ram_data_i_logic_s);
	ram_address_logic_s <= to_stdlogicvector(ram_address_ulogic_s);
	ram_data_o_logic_s  <= to_stdlogicvector(ram_data_o_ulogic_s);
	ram_wr_en_logic_s   <= ram_wr_en_ulogic_s;
	ram_rd_en_logic_s   <= ram_rd_en_ulogic_s;
  
  i_ram32w : ram32w
  port map(
    address		              => ram_address_logic_s,
    clock		                => aclk_i,
    data		                => ram_data_o_logic_s,
    rden		                => ram_rd_en_logic_s,
    wren		                => ram_wr_en_logic_s,
    q		                    => ram_data_i_logic_s
  );

end architecture rtl;