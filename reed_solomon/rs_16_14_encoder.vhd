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
	
	use work.rs_16_14_pkg.all;
	
entity rs_encoder_16_14 is
	port(
	--SYNCHRO
	clk			: in std_ulogic;						--! global clk
	rst_n		: in std_ulogic;						--! reset active low
	-- INPUT INTERFACE
	data_i		: in std_ulogic_vector(7 downto 0);	--! Data at the input of the CADU channel to be RS encoded
	valid_i		: in std_ulogic;						--! Data valid on data_i
	ready_o		: out std_ulogic;					--! RS encoder ready to process data
	-- OUTPUT INTERFACE
	data_o		: out std_ulogic_vector(7 downto 0);	--! Output RS data (223 data + 32 RS codes)
	valid_o		: out std_ulogic;					--! Data valid on data_o
	-- DEBUG INTERFACE
	debug_o		: out std_ulogic_vector(3 downto 0)	--! debug signal (can be removed for a final implementation)
	);
end entity rs_encoder_16_14;

--! @brief <architecture description>
--! @details <architecture description>
architecture odd_19052011 of rs_encoder_16_14 is
-- CONSTANT DECLARATIONS ----------------------------------------------
-- --------------------------------------------------------------------

-- TYPE DECLARATIONS --------------------------------------------------
type rs_registers_type is array(0 to 1) of std_ulogic_vector(7 downto 0);
-- --------------------------------------------------------------------

-- SIGNAL DECLARATIONS ------------------------------------------------
signal rs_registers 		: rs_registers_type; 				--! Contains the 32 current RS-codes
signal crt_rs_offset		: natural range 0 to 15;			--! Current Byte offset being processed by the RS encoder

signal data_int				: std_ulogic_vector(7 downto 0);		--! Internal synchronous value for data_o
signal valid_int			: std_ulogic;						--! Internal synchronous value for valid_o
signal ready_int			: std_ulogic;						--! Internal synchronized value for ready_o

-- --------------------------------------------------------------------
begin
	
	ready_o <= ready_int;
	data_o  <= data_int;
	valid_o <= valid_int;
	
	-- -----------------------------------
	--! @process <process description here>
	-- -----------------------------------
	RS_16_14_ENCODER_PROC:process(rst_n,clk)
	begin
		if rst_n='0' then
			crt_rs_offset <= 0;
			data_int <= (others=>'0');
			rs_registers(0) <= (others=>'0');
			rs_registers(1) <= (others=>'0');
			valid_int <= '0';
			ready_int <= '0';
		elsif clk'event and clk='1' then
			if valid_i='1' and crt_rs_offset<14 then
				data_int <= data_i;
				valid_int <= '1';
				
				rs_registers(1) <= rs_registers(0) xor (mult6(data_i xor rs_registers(1)));
				rs_registers(0) <= mult8(data_i xor rs_registers(1));
				
				crt_rs_offset<=crt_rs_offset+1;
				
			elsif crt_rs_offset=14 then
				data_int <= rs_registers(1);
				valid_int <= '1';
				crt_rs_offset<=15;
			elsif crt_rs_offset=15 then
				data_int <= rs_registers(0);
				rs_registers(0) <= (others=>'0');
				rs_registers(1) <= (others=>'0');
				valid_int <= '1';
				crt_rs_offset<=0;
			else
				data_int <= (others=>'0');
				valid_int <= '0';
			end if;--main if control
			
			if crt_rs_offset>=14 then
				ready_int <= '0';
			else
				ready_int <= '1';
			end if;--force not ready when outing RS codes
		end if;--synchro
	end process;

	-- ------------------------------ --
	-- ----------DEBUG PART---------- --
	DEBUG_GEN:if DEBUG_ENABLE=1 generate
		debug_o(0) <= '0';
		debug_o(1) <= '0';
		debug_o(2) <= '0'; 
		debug_o(3) <= '0';
	end generate DEBUG_GEN;
	-- ------------------------------ --
	-- ------------------------------ --
	
--ABV VERIFICATION PART------------------------------------------------------------------
	--vunit rs_encoder_16_14_check(rs_encoder_16_14){
		--default clock is rising_edge(clk);
		--
		--property P0 is
			--always();
		--assert P0 report "[rs_encoder_16_14]:: description error ";
		--
	--}
--EOV------------------------------------------------------------------------------------
end architecture odd_19052011;