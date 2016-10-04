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
-- RTAX Cells: 2064 (6.4%)
-- Comb Cells:  453 (4.2%)
-- FF   Cells: 1611 (7.5%)
-- Max   Freq:   54 Mhz
-- ----------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use work.rs_16_14_pkg.all;
	
entity rs_16_14_decoder is
	port(
	-- SYNCHRO
	clk			: in std_ulogic;						--! global clk
	rst_n		: in std_ulogic;						--! reset active low
	-- INPUT INTERFACE
	data_i		: in std_ulogic_vector(7 downto 0);	--! Data at the input of the CADU channel to be RS encoded
	valid_i		: in std_ulogic;						--! Data valid on data_i
	ready_o		: out std_ulogic;					--! RS decoder ready to receive data
	-- OUTPUT INTERFACE
	data_o		: out std_ulogic_vector(7 downto 0);	--! Output RS data (16 data + 2 RS codes)
	valid_o		: out std_ulogic;					--! Data valid on data_o
	cerr_o		: out std_ulogic;					--! Single error detected and corrected
	ncerr_o		: out std_ulogic;					--! Double error detected
	-- DEBUG INTERFACE
	debug_o		: out std_ulogic_vector(3 downto 0)	--! debug signal (can be removed for a final implementation)
	);
end entity rs_16_14_decoder;

--! @brief <architecture description>
--! @details <architecture description>
architecture odd_19052011 of rs_16_14_decoder is
-- CONSTANT DECLARATIONS ----------------------------------------------
-- --------------------------------------------------------------------

component rs_syndromes_16_14 is
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
end component;

component rs_berlekamps_16_14 is
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
end component;

component rs_chien_search_16_14 is
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
end component;

component rs_forney_16_14 is
	port(
	-- INPUT INTERFACE
	omega0_i		: in std_ulogic_vector(7 downto 0);	--! x^0 coef. for the Omega (error evaluator) polynomial
	Lambda1_i		: in std_ulogic_vector(7 downto 0);	--! x^1 coef. for the Lambda (locator polynomial) polynomial
	valid_i			: in std_ulogic;						--! Data valid on data_i
	-- OUTPUT INTERFACE
	error_value_o	: out std_ulogic_vector(7 downto 0);	--! Correction code for the faulty symbol
	valid_o			: out std_ulogic						--! Data valid on data_o
	);
end component;

-- TYPE DECLARATIONS --------------------------------------------------
type rs_type is array(0 to 13) of std_ulogic_vector(7 downto 0);
type state_type is (S_INIT,S_WAIT_SYNDROMES,S_WAIT_ERR_VALUE,S_WAIT_ERR_LOCATION,S_TRANSMIT);
-- --------------------------------------------------------------------

-- SIGNAL DECLARATIONS ------------------------------------------------
signal rs_syndrome0 				: std_ulogic_vector(7 downto 0); --! First syndrome (alpha1)
signal rs_syndrome1 				: std_ulogic_vector(7 downto 0); --! Second syndrome (alpha2)
signal valid_syndromes				: std_ulogic;					--! Syndromes availables
signal valid_syndromes_berlekamps 	: std_ulogic;					--! Syndromes availables and correction required since at least one of the syndromes is not equal to zero
signal Lambda0 						: std_ulogic_vector(7 downto 0); --! coef. x^0 of the Lambda polynomial
signal Lambda1 						: std_ulogic_vector(7 downto 0); --! coef. x^1 of the Lambda polynomial
signal valid_Lambda_omega 			: std_ulogic;					--! Lambda and omega polynomial available
signal error_location				: std_ulogic_vector(7 downto 0); --! The position of the faulty symbol
signal valid_error_location 		: std_ulogic;					--! Data valid on the output port error_location
signal omega0 						: std_ulogic_vector(7 downto 0); --! Coef. x^0 of the Omega  (error evaluator) polynomial
signal error_value					: std_ulogic_vector(7 downto 0); --! The value used to correct the faulty symbol by XOR operation
signal valid_error_value 			: std_ulogic;					--! Data valid on output port error_value
signal cerr_int						: std_ulogic;					--! Internal value of cerr_o (correctable/single error detected)
signal ncerr_int					: std_ulogic;					--! Internal value of ncerr_o (non-correctable/double error detected)
-- --------------------------------------------------------------------
signal debug_syndromes				: std_ulogic_vector(3 downto 0); --! Debug signal for the Syndrome Algorithm
signal debug_berlekamps				: std_ulogic_vector(3 downto 0); --! Debug signal for the Berlekamps Algorithm
signal debug_chien_search			: std_ulogic_vector(3 downto 0); --! Debug signal for the Chien Search Algorithm
-- --------------------------------------------------------------------
signal crt_rs_offset				: natural range 0 to 13;		--! Current RS data offset
signal crt_rs						: rs_type;						--! current RS data 14 symbols
signal CRT_STATE					: state_type;					--! State of hte RS decoder
signal crt_err_value				: std_ulogic_vector(7 downto 0); --! Error value to correct the faulty symbol
signal data_int						: std_ulogic_vector(7 downto 0); --! Internal value of data_o
signal valid_int					: std_ulogic;					--! Internal value of valid_o
-- --------------------------------------------------------------------
begin
	
	RS_SYNDROMES_16_14_INST : rs_syndromes_16_14
	port map(
		--SYNCHRO
		clk					=> clk,
		rst_n				=> rst_n,
		-- INPUT INTERFACE
		data_i				=> data_i,
		valid_i				=> valid_i,
		-- OUTPUT INTERFACE
		rs_syndrome0_o		=> rs_syndrome0,
		rs_syndrome1_o		=> rs_syndrome1,
		valid_o				=> valid_syndromes,
		-- DEBUG INTERFACE
		debug_o				=> debug_syndromes
	);
	
	valid_syndromes_berlekamps <= '1' when (valid_syndromes='1' and (rs_syndrome0/="00000000" or rs_syndrome0/="00000000")) else '0';
	
	RS_BERLEKAMPS_16_14_INST : rs_berlekamps_16_14
	port map(
		--SYNCHRO
		clk					=> clk,
		rst_n				=> rst_n,
		-- INPUT INTERFACE
		rs_syndrome0_i		=> rs_syndrome0,
		rs_syndrome1_i		=> rs_syndrome1,
		valid_i				=> valid_syndromes_berlekamps,
		-- OUTPUT INTERFACE
		Lambda0_o			=> Lambda0,
		Lambda1_o			=> Lambda1,
		omega0_o			=> omega0,
		omega1_o			=> OPEN,
		valid_o				=> valid_Lambda_omega,
		-- DEBUG INTERFACE
		debug_o				=> debug_berlekamps
	);
	
	RS_CHIEN_SEARCH_16_14_INST : rs_chien_search_16_14
	port map(
		--SYNCHRO
		clk					=> clk,
		rst_n				=> rst_n,
		-- INPUT INTERFACE
		Lambda0_i			=> Lambda0,
		Lambda1_i			=> Lambda1,
		valid_i				=> valid_Lambda_omega,
		-- OUTPUT INTERFACE
		error_location_o	=> error_location,
		decoder_failure_o	=> ncerr_o,
		valid_o				=> valid_error_location,
		-- DEBUG INTERFACE
		debug_o				=> debug_chien_search
	);
	
	cerr_o <= valid_error_location;
	
	RS_FORNEY_16_14_INST : rs_forney_16_14
	port map(
		-- INPUT INTERFACE
		omega0_i		=> omega0,
		Lambda1_i		=> Lambda1,
		valid_i			=> valid_Lambda_omega,
		-- OUTPUT INTERFACE
		error_value_o	=> error_value,
		valid_o			=> valid_error_value
	);
	
	data_o <= data_int;
	valid_o <= valid_int;
	
	-- -----------------------------------
	--!@process <insert description here> 
	-- -----------------------------------
	process(rst_n,clk)
	begin
		if rst_n='0' then
			for i in 0 to 13 loop
				crt_rs(i) <= (others=>'0');
			end loop;
			crt_rs_offset <= 0;
			data_int <= (others=>'0');
			valid_int <= '0';
			crt_err_value <= (others=>'0');
			CRT_STATE <= S_INIT;
		elsif clk'event and clk='1' then
			case CRT_STATE is
				when S_INIT =>
					if valid_i='1' and crt_rs_offset<13 then
						crt_rs(crt_rs_offset) <= data_i;
						crt_rs_offset <= crt_rs_offset+1;
						CRT_STATE <= S_INIT;
					elsif valid_i='1' and crt_rs_offset=13 then
						crt_rs(13) <= data_i;
						crt_rs_offset <= 0;
						CRT_STATE <= S_WAIT_SYNDROMES;
					else
						CRT_STATE <= S_INIT;
					end if;
					--------------------------
					crt_err_value <= (others=>'0');
					data_int <= (others=>'0');
					valid_int <= '0';
				when S_WAIT_SYNDROMES =>
					if valid_syndromes='1' and valid_syndromes_berlekamps='1' then
						-- Engage into the Correction processus
						CRT_STATE <= S_WAIT_ERR_VALUE;
					elsif valid_syndromes='1' and valid_syndromes_berlekamps='0' then
						-- No correction needed, transmit then
						CRT_STATE <= S_TRANSMIT;
--synthesis translate_off
					assert(rs_syndrome0="00000000" and rs_syndrome1="00000000")
						report "[RS_16_14_DECODER]:: Error, syndroms should be both equal to zero when no error detected" severity error;
--synthesis translate_on
					else
						CRT_STATE <= S_WAIT_SYNDROMES;
					end if;
					--------------------------
					crt_err_value <= (others=>'0');
					data_int <= (others=>'0');
					valid_int <= '0';
				when S_WAIT_ERR_VALUE =>
					if valid_error_value='1' then
						crt_err_value <= error_value;
						CRT_STATE <= S_WAIT_ERR_LOCATION;
					else
						CRT_STATE <= S_WAIT_ERR_VALUE;
					end if;
					--------------------------
					crt_rs_offset <= 0;
					data_int <= (others=>'0');
					valid_int <= '0';
				when S_WAIT_ERR_LOCATION =>
					if valid_error_location='1' then
						case error_location is
							when "00000011" => crt_rs(13) <= crt_rs(13) xor crt_err_value;
							when "00000100" => crt_rs(12) <= crt_rs(12) xor crt_err_value;
							when "00000101" => crt_rs(11) <= crt_rs(11) xor crt_err_value;
							when "00000110" => crt_rs(10) <= crt_rs(10) xor crt_err_value;
							when "00000111" => crt_rs(9) <= crt_rs(9) xor crt_err_value;
							when "00001000" => crt_rs(8) <= crt_rs(8) xor crt_err_value;
							when "00001001" => crt_rs(7) <= crt_rs(7) xor crt_err_value;
							when "00001010" => crt_rs(6) <= crt_rs(6) xor crt_err_value;
							when "00001011" => crt_rs(5) <= crt_rs(5) xor crt_err_value;
							when "00001100" => crt_rs(4) <= crt_rs(4) xor crt_err_value;
							when "00001101" => crt_rs(3) <= crt_rs(3) xor crt_err_value;
							when "00001110" => crt_rs(2) <= crt_rs(2) xor crt_err_value;
							when "00001111" => crt_rs(1) <= crt_rs(0) xor crt_err_value;
							when "00010000" => crt_rs(1) <= crt_rs(0) xor crt_err_value;
							when others => 
						end case;
						CRT_STATE <= S_TRANSMIT;
					else
						CRT_STATE <= S_WAIT_ERR_LOCATION;
					end if;
					--------------------------
					crt_rs_offset <= 0;
					data_int <= (others=>'0');
					valid_int <= '0';
				when S_TRANSMIT =>
					data_int <= crt_rs(crt_rs_offset);
					valid_int <= '1';
					
					if crt_rs_offset<13 then
						crt_rs_offset <= crt_rs_offset+1;
						CRT_STATE <= S_TRANSMIT;
					elsif crt_rs_offset=13 then
						crt_rs_offset <= 0;
						crt_err_value <= (others=>'0');
						CRT_STATE <= S_INIT;
					end if;
					
			end case;--fsm
		end if;--synchro
	end process;
  
  ready_o <= '1';--FIXME
	
end architecture odd_19052011;