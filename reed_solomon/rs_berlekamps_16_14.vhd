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
-- RTAX Cells:  858 (2.6%)
-- Comb Cells:  137 (1.3%)
-- FF   Cells:  721 (3.3%)
-- Max   Freq:   60 Mhz
-- ----------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use work.rs_16_14_pkg.all;


entity rs_berlekamps_16_14 is
	port(
	--SYNCHRO
	clk					: in std_ulogic;						--! global clk
	rst_n				: in std_ulogic;						--! reset active low
	-- INPUT INTERFACE
	rs_syndrome0_i		: in std_ulogic_vector(7 downto 0);	--! First syndrome of the RS code
	rs_syndrome1_i		: in std_ulogic_vector(7 downto 0);	--! Second syndrome of the RS code
	valid_i				: in std_ulogic;						--! Data valid on data_i
	-- OUTPUT INTERFACE
	Lambda0_o				: out std_ulogic_vector(7 downto 0);	--! X^0 coeffcient of the Lambda (error locator) polynomial
	Lambda1_o				: out std_ulogic_vector(7 downto 0);	--! X^1 coeffcient of the Lambda (error locator) polynomial
	omega0_o				: out std_ulogic_vector(7 downto 0);	--! X^0 coeffcient of the omega (error evaluator) polynomial
	omega1_o				: out std_ulogic_vector(7 downto 0);	--! X^1 coeffcient of the omega (error evaluator) polynomial
	valid_o				: out std_ulogic;					--! Data valid on data_o
	-- DEBUG INTERFACE
	debug_o				: out std_ulogic_vector(3 downto 0)	--! debug signal (can be removed for a final implementation)
	);
end entity rs_berlekamps_16_14;

--! @brief <architecture description>
--! @details <architecture description>
architecture odd_19052011 of rs_berlekamps_16_14 is
-- CONSTANT DECLARATIONS ----------------------------------------------
-- --------------------------------------------------------------------

-- TYPE DECLARATIONS --------------------------------------------------
-- --------------------------------------------------------------------

-- SIGNAL DECLARATIONS ------------------------------------------------
signal rs_syndrome0_int		: std_ulogic_vector(7 downto 0);		--! First syndrome of the RS code
signal rs_syndrome1_int		: std_ulogic_vector(7 downto 0);		--! Second syndrome of the RS code
	
signal Lambda1_int			: std_ulogic_vector(7 downto 0);		--! Internal synchronous value for Lambda1_o

signal omega1_int			: std_ulogic_vector(7 downto 0);		--! Internal synchronous value for omega1_o
signal omega0_int			: std_ulogic_vector(7 downto 0);		--! Internal synchronous value for omega0_o
signal valid_int			: std_ulogic;						--! Internal synchronous value for valid_o

signal C1_int				: std_ulogic_vector(7 downto 0);		--! x^1 coef. for the Correction Polynomial

signal k					: natural range 0 to 3;
--signal l					: natural range 0 to 2;
signal compute_berlekamps	: std_ulogic;
-- --------------------------------------------------------------------
begin
	
	BERLEKAMPS_PROC:process(rst_n,clk)
	variable error_value : std_ulogic_vector(7 downto 0);
	begin
		if rst_n='0' then
			k <= 1;
			--l <= 0;
			Lambda1_int <= "00000000";
			--Lambda0_int <= "00000001"; optimize: lambda0 always equals 1
			C1_int <= "00000001";
			--C0_int <= "00000000";
			rs_syndrome0_int <= (others=>'0');
			rs_syndrome1_int <= (others=>'0');
			error_value :=(others=>'0');
			valid_int <= '0';
			compute_berlekamps <= '0';
		elsif clk'event and clk='1' then
			if valid_i='1' then
				rs_syndrome0_int <= rs_syndrome0_i;
				rs_syndrome1_int <= rs_syndrome1_i;
				Lambda1_int <= "00000000";
				--Lambda0_int <= "00000001";
				C1_int <= "00000001";
				--C0_int <= "00000000";
				error_value :=(others=>'0');
				--l <= 0; optimize on l
				
				if rs_syndrome0_i="00000000" then
					k <= 2;
				else
					k <= 1;
				end if;
				
				compute_berlekamps <= '1';
			elsif k<=2 and compute_berlekamps='1' then
				if k=1 then
					error_value:=rs_syndrome0_int;

					-- if l=0 then --optimize on l
						-- --do nothing
					-- else
-- --synthesis translate_off
						-- assert(l=1) report "[RS_BERLEKAMPS_16_14]::Incorrect value for l=<"&str(l)&">" severity error;
-- --synthesis translate_on
						-- error_value:=error_value xor full_multiplier_g256(Lambda1_int,rs_syndrome1_int);
					-- end if;
					
					Lambda1_int <= full_multiplier_g256(error_value,C1_int) xor Lambda1_int;
					--Lambda0_int <= full_multiplier_g256(error_value,C0_int) xor Lambda0_int; optimization removing C0_int
					--Lambda0_int <= Lambda0_int;
					
					--if 2*l<1 then optimize since l is always equal to zero here
					--	l <= 1; optimize on l
						--C1_int <= full_multiplier_g256(inverses_table(to_integer(unsigned(error_value))),Lambda1_int);
						--C1_int <= full_multiplier_g256(inverses_table(to_integer(unsigned(error_value))),Lambda0_int); optimize: lambda0 always equals 1
						C1_int <= inverses_table(to_integer(unsigned(error_value)));
						--C0_int <= "00000000";
					--else
						--C1_int <= C0_int; optimization removing C0_int
					--	C1_int <= "00000000";
					--	--C0_int <= "00000000";
					--end if;
					k<=k+1;
				elsif k=2 then
					error_value:=rs_syndrome1_int xor full_multiplier_g256(Lambda1_int,rs_syndrome0_int);
					
					-- if l=0 then --optimize on l
						-- --do nothing
					-- else
-- --synthesis translate_off
						-- assert(l=1) report "[RS_BERLEKAMPS_16_14]::Incorrect value for l=<"&str(l)&">" severity error;
-- --synthesis translate_on
						-- error_value:=error_value xor full_multiplier_g256(Lambda1_int,rs_syndrome0_int);
					-- end if;
					
					Lambda1_int <= full_multiplier_g256(error_value,C1_int) xor Lambda1_int;
					--Lambda0_int <= full_multiplier_g256(error_value,C0_int) xor Lambda0_int; optimization removing C0_int
					--Lambda0_int <= Lambda0_int; optimize: lambda0 always equals 1
					
					--if 2*l<2 then optimize since l always equal to 1 here
					--	l <= 2-l;
						--C0_int <= "00000000";
						--C1_int <= full_multiplier_g256(inverses_table(to_integer(unsigned(error_value))),Lambda0_int); optimize: lambda0 always equals 1
					--	C1_int <= inverses_table(to_integer(unsigned(error_value)));
					--else
						--C1_int <= C0_int; optimization removing C0_int
						C1_int <= "00000000";
						--C0_int <= "00000000";
					--end if;
					k<=k+1;
				end if;
				valid_int <= '0';
			elsif compute_berlekamps='1' and k>2 then
				valid_int <= '1';
				compute_berlekamps <= '0';
				k <= 1;
				--l <= 0; optimize on l
				error_value :=(others=>'0');
				C1_int <= "00000001";
				--C0_int <= "00000000";
			elsif compute_berlekamps='0' then
				valid_int <= '0';
				compute_berlekamps <= '0';
				k <= 1;
				--l <= 0; optimize on l
				error_value :=(others=>'0');
				Lambda1_int <= "00000000";
				--Lambda0_int <= "00000001"; optimize: lambda0 always equals 1
				C1_int <= "00000001";
				--C0_int <= "00000000";
				rs_syndrome0_int <= (others=>'0');
				rs_syndrome1_int <= (others=>'0');
			end if;--computation
		end if;--synchro
	end process;
		
	omega1_int <= rs_syndrome1_int xor full_multiplier_g256(rs_syndrome0_int,Lambda1_int);
	omega0_int <= rs_syndrome0_int;
		
	omega1_o <= omega1_int;
	omega0_o <= omega0_int;
		
	Lambda1_o <= Lambda1_int;
	--Lambda0_o <= Lambda0_int; optimize: lambda0 always equals 1
	Lambda0_o <= "00000001";
	
	valid_o <= valid_int;
	
end architecture odd_19052011;