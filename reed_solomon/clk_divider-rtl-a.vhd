-- ----------------------
-- Yann Oddos - 2016
-- ----------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture rtl of clk_divider is

signal clk_s 		: std_ulogic;
signal cnt_s 		: integer;

begin

	process(clk_i,rst_n_i)
	begin
		if rst_n_i='0' then
			cnt_s 		<= 0;
			clk_s 		<= '0';
		elsif clk_i'event and clk_i='1' then
			if cnt_s<1500000 then
				cnt_s <= cnt_s+1;
			else
				cnt_s <= 0;
				clk_s <= not clk_s;
			end if;
		end if;
	end process;
	
	clk_o <= clk_s;

end architecture;