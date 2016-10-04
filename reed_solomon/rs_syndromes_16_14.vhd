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
-- RTAX Cells:  65  (0.2%)
-- Comb Cells:  22  (0.2%)
-- FF   Cells:  43  (0.2%)
-- Max   Freq: 216  Mhz
-- ----------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use work.rs_16_14_pkg.all;
	
entity rs_syndromes_16_14 is
	port(
	--SYNCHRO
	clk					: in std_ulogic;						--! global clk
	rst_n				: in std_ulogic;						--! reset active low
	-- INPUT INTERFACE
	data_i				: in std_ulogic_vector(7 downto 0);	--! Data at the input of the CADU channel to be RS encoded
	valid_i				: in std_ulogic;						--! Data valid on data_i
	-- OUTPUT INTERFACE
	rs_syndrome0_o		: out std_ulogic_vector(7 downto 0);	--! First Syndrome
	rs_syndrome1_o		: out std_ulogic_vector(7 downto 0);	--! Second Syndrome
	valid_o				: out std_ulogic;					--! Data valid on data_o
	-- DEBUG INTERFACE
	debug_o				: out std_ulogic_vector(3 downto 0)	--! debug signal (can be removed for a final implementation)
	);
end entity rs_syndromes_16_14;

--! @brief <architecture description>
--! @details <architecture description>
architecture odd_19052011 of rs_syndromes_16_14 is
-- CONSTANT DECLARATIONS ----------------------------------------------
-- --------------------------------------------------------------------

-- TYPE DECLARATIONS --------------------------------------------------
-- --------------------------------------------------------------------

-- SIGNAL DECLARATIONS ------------------------------------------------
signal crt_rs_offset		: natural range 0 to 16;			--! Current Byte offset being processed by the RS encoder

signal rs_syndrome0_int		: std_ulogic_vector(7 downto 0);		--! Internal synchronous value for the first rs syndrome
signal rs_syndrome1_int		: std_ulogic_vector(7 downto 0);		--! Internal synchronous value for the second rs syndrome

signal valid_int			: std_ulogic;						--! Internal synchronous value for valid_o
-- --------------------------------------------------------------------
begin
		
	valid_o <= valid_int;
	rs_syndrome0_o <= rs_syndrome0_int;
	rs_syndrome1_o <= rs_syndrome1_int;
		
	valid_int <= '1' when crt_rs_offset=16 else '0';
	-- -----------------------------------
	--! @process <process description here>
	-- -----------------------------------
	process(rst_n,clk)
	begin
		if rst_n='0' then
			rs_syndrome0_int <= (others=>'0');
			rs_syndrome1_int <= (others=>'0');
			crt_rs_offset <= 0;
		elsif clk'event and clk='1' then
			
			if valid_i='1' and crt_rs_offset<16 then
				rs_syndrome0_int <= mult2(rs_syndrome0_int) xor data_i; --alpha_1=2
				rs_syndrome1_int <= mult4(rs_syndrome1_int) xor data_i; --alpha_1=2
				crt_rs_offset <= crt_rs_offset+1;
			elsif crt_rs_offset=16 then
				rs_syndrome0_int <= (others=>'0');
				rs_syndrome1_int <= (others=>'0');
				crt_rs_offset <= 0;
			end if;--syndromes computation
			
		end if;--synchro
	end process;
	
end architecture odd_19052011;