-- ----------------------
-- Yann Oddos - 2016
-- ----------------------


-- ----------------------------------------------------
-- RS(16,14) with 8bits symbols
-- GF(256) polynomial generator : p(x)=x^8+x^7+x^2+x+1
-- g(x)=(x-alpha^1)*(x-alpha^2) <=> g(x)=(x+2)*(x+4)
-- g(x)=x^2+6*x+8
-- -----------------------------------------------------
-- Synthesis results
--
-- RTAX Cells:  139 (0.4%)
-- Comb Cells:   44 (0.4%)
-- FF   Cells:   95 (0.4%)
-- Max   Freq:  160 Mhz
-- ----------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
	use work.rs_16_14_pkg.all;
	
entity rs_chien_search_16_14 is
	port(
	--SYNCHRO
	clk					: in std_ulogic;						--! global clk
	rst_n				: in std_ulogic;						--! reset active low
	-- INPUT INTERFACE
	Lambda0_i			: in std_ulogic_vector(7 downto 0);	--! x^0 coef. for the Lambda (error locator) polynomial
	Lambda1_i			: in std_ulogic_vector(7 downto 0);	--! x^1 coef. for the Lambda (error locator) polynomial
	valid_i				: in std_ulogic;						--! Data valid for Lambda coefs.
	-- OUTPUT INTERFACE
	error_location_o	: out std_ulogic_vector(7 downto 0);	--! Location of the erroneous symbol
	decoder_failure_o	: out std_ulogic;					--! If the roots is not in the field, then 2 error detected
	valid_o				: out std_ulogic;					--! Data valid on data_o
	-- DEBUG INTERFACE
	debug_o				: out std_ulogic_vector(3 downto 0)	--! debug signal (can be removed for a final implementation)
	);
end entity rs_chien_search_16_14;

--! @brief <architecture description>
--! @details <architecture description>
architecture odd_19052011 of rs_chien_search_16_14 is
-- CONSTANT DECLARATIONS ----------------------------------------------
constant ALPHA_238_DECIMAL_FORM : std_ulogic_VECTOR := "01101101"; -- alpha^238=109
-- --------------------------------------------------------------------

-- TYPE DECLARATIONS --------------------------------------------------
-- --------------------------------------------------------------------

-- SIGNAL DECLARATIONS ------------------------------------------------
signal crt_gf256_offset		: natural range 0 to 255;			--! Current Byte offset being processed by the RS encoder
signal Lambda0_int			: std_ulogic_vector(7 downto 0);		--! Store the last Lambda0_i value

signal error_found			: std_ulogic;						--! Error/Polynomial locator root found
signal result				: std_ulogic_vector(7 downto 0);		--! Evaluation of Lambda(x) for x=alpha^crt_gf256_offset
signal chien_compute		: std_ulogic;						--! Identifiy when the Chien search algorithm is performing computation
signal error_location_int	: std_ulogic_vector(7 downto 0);		--! Internal synchronous value for error_location_o
signal valid_int			: std_ulogic;						--! Internal synchronous value for valid_o
-- --------------------------------------------------------------------
begin
	
	error_location_o <= error_location_int;
	valid_o <= valid_int;
	
	CHIEN_SEARCH_PROC:process(rst_n,clk)
	variable value1 : std_ulogic_vector(7 downto 0);
	begin
		if rst_n='0' then
			crt_gf256_offset <= 0;
			error_location_int <= "00000000";
			valid_int <= '0';
			chien_compute <= '0';
			result <= "00000000";
			error_found <= '0';
		elsif clk'event and clk='1' then
			if valid_i='1' then
				Lambda0_int <= Lambda0_i;
				value1:= full_multiplier_g256(Lambda1_i,ALPHA_238_DECIMAL_FORM);
				result <= Lambda0_i xor value1;
				valid_int <= '0';
				chien_compute <= '1';
				crt_gf256_offset <= 237;
			elsif chien_compute='1' and crt_gf256_offset<254 then
				value1:= mult2(value1);
				result <= Lambda0_int xor value1;
				valid_int <= '0';
				crt_gf256_offset <= crt_gf256_offset+1;
				chien_compute <= '1';
			elsif chien_compute='1' and crt_gf256_offset=254 then
				value1:= mult2(value1);
				result <= Lambda0_int xor value1;
				crt_gf256_offset <= 0;
				valid_int <= '1';
				chien_compute <= '0';
			else
				crt_gf256_offset <= 0;
				value1 := "00000000";
				valid_int <= '0';
				chien_compute <= '0';
			end if;
			
			if valid_i='1' then
				error_found <= '0';
			elsif chien_compute='1' and result="00000000" then
				error_found <= '1';
			end if;
			
			if chien_compute='1' and result="00000000" then
				error_location_int <= std_ulogic_vector(to_unsigned(255-crt_gf256_offset,8));
			elsif chien_compute='0' then
				error_location_int <= "00000000";
			end if;
		end if;--synchro
	end process;
	
	decoder_failure_o <= '1' when (valid_int='1' and error_found='0') else '0';
	
end architecture odd_19052011;