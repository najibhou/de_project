-- ----------------------
-- Yann Oddos - 2016
-- ----------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
library work;
	use work.rs_16_14_pkg.all;
	
entity rs_hps_bridge is
	port(
	-- SYNCHRO
	clk			                : in std_ulogic;						--! global clk
	reset_n		              : in std_ulogic;						--! reset active low
	-- HPS INTERFACE
  readdata                : out std_ulogic_vector(31 downto 0);
  address                 : in  std_ulogic_vector(7 downto 0);
  chipselect              : in  std_ulogic;
  write_n                 : in  std_ulogic;
  writedata               : in  std_ulogic_vector(31 downto 0);
	-- RS CONTROL INTERFACE
	hps_mem_stb_o           : out std_ulogic;
	hps_mem_write_o         : out std_ulogic;
	hps_mem_wdata_o         : out std_ulogic_vector(31 downto 0);
	hps_mem_addr_i          : out std_ulogic_vector(7 downto 0);
	hps_mem_rdata_i         : in  std_ulogic_vector(31 downto 0);
	hps_rs_exec_o	          : out std_ulogic;
	hps_rs_en_decn_o        : out std_ulogic;
	hps_rs_addr_o	          : out std_ulogic_vector(7 downto 0);
  debug_i                 : out std_ulogic_vector(2 downto 0)
	);
end entity rs_hps_bridge;

architecture rtl of rs_hps_bridge is

begin
  
end architecture rtl;