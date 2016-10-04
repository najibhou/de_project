-- ----------------------
-- Yann Oddos - 2016
-- ----------------------


-- ----------------------------------------------------
-- RS(16,14) with 8bits symbols
-- GF(256) polynomial generator : p(x)=x^8+x^7+x^2+x+1
-- g(x)=(x-alpha^1)*(x-alpha^2) <=> g(x)=(x+2)*(x+4)
-- g(x)=x^2+6*x+8
-- -----------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
	use work.rs_16_14_pkg.all;
	
entity rs_forney_16_14 is
	port(
	-- INPUT INTERFACE
	omega0_i		: in std_ulogic_vector(7 downto 0);	--! x^0 coef. for the Omega (error evaluator) polynomial
	Lambda1_i		: in std_ulogic_vector(7 downto 0);	--! x^1 coef. for the Lambda (locator polynomial) polynomial
	valid_i			: in std_ulogic;						--! Data valid on data_i
	-- OUTPUT INTERFACE
	error_value_o	: out std_ulogic_vector(7 downto 0);	--! Correction code for the faulty symbol
	valid_o			: out std_ulogic						--! Data valid on data_o
	);
end entity rs_forney_16_14;

--! @brief <architecture description>
--! @details <architecture description>
architecture odd_20052011 of rs_forney_16_14 is
-- CONSTANT DECLARATIONS ----------------------------------------------
-- --------------------------------------------------------------------

-- TYPE DECLARATIONS --------------------------------------------------
-- --------------------------------------------------------------------

-- SIGNAL DECLARATIONS ------------------------------------------------
-- --------------------------------------------------------------------
begin
	
	error_value_o <=
				full_multiplier_g256(omega0_i,inverses_table(to_integer(unsigned(Lambda1_i))));
	
	valid_o <= valid_i;
	
	
end architecture odd_20052011;