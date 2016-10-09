
library ieee;
use ieee.std_logic_1164.all;

entity clk_divider is
port(
	rst_n_i  : in std_ulogic;
	clk_i	 	: in std_ulogic;
	clk_o		: out std_ulogic
	
);
end entity;
