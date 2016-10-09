-- ----------------------
-- Yann Oddos - 2016
-- ----------------------


library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
library work;
	use work.rs_16_14_pkg.all;
	
entity rs_16_14_control is
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
end entity rs_16_14_control;

--! @brief <architecture description>
--! @details <architecture description>
architecture rtl of rs_16_14_control is
type rs_control_state_t is (
	STATE_RS_INIT,
	STATE_RS_MEM_READ,
	STATE_RS_ENCODE_READ,
	STATE_RS_ENCODE_EXEC,
	STATE_RS_ENCODE_STORE,
	STATE_RS_DECODE_READ,
	STATE_RS_DECODE_EXEC,
	STATE_RS_DECODE_STORE
	);

component rs_encoder_16_14
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
end component;

component rs_16_14_decoder
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
end component;

signal crt_state_s        : rs_control_state_t;
signal ram_data_s         : std_ulogic_vector(31 downto 0);
signal ram_wr_en_s        : std_ulogic;
signal ram_rd_en_s        : std_ulogic;
signal ram_address_s      : std_ulogic_vector(7 downto 0);

signal rs_base_address    : std_ulogic_vector(7 downto 0);
signal hps_mem_rdy_s      : std_ulogic;
signal rs_data_original_s : std_ulogic_vector(127 downto 0);
signal rs_enc_result_s    : std_ulogic_vector(127 downto 0);
signal rs_dec_result_s    : std_ulogic_vector(127 downto 0);
signal mem_word_count_s   : natural range 0 to 5;
signal byte_count_s       : natural range 0 to 16;
signal enc_byte_count_s   : natural range 0 to 16;
signal dec_byte_count_s   : natural range 0 to 16;

signal enc_valid_s        : std_ulogic;
signal enc_data_s         : std_ulogic_vector(7 downto 0);
signal enc_ready_s        : std_ulogic;
signal enc_data_result_s	: std_ulogic_vector(7 downto 0);
signal enc_valid_result_s : std_ulogic;
signal enc_finish_s       : std_ulogic;
signal enc_debug_s        : std_ulogic_vector(3 downto 0);

signal dec_valid_s        : std_ulogic;
signal dec_data_s         : std_ulogic_vector(7 downto 0);
signal dec_data_result_s  : std_ulogic_vector(7 downto 0);
signal dec_valid_result_s : std_ulogic;
signal dec_ready_s        : std_ulogic;
signal dec_finish_s       : std_ulogic;
signal dec_cerr_s         : std_ulogic;
signal dec_ncerr_s        : std_ulogic;
signal dec_debug_s        : std_ulogic_vector(3 downto 0);

signal enc_finish_delay_s : std_ulogic;
signal dec_finish_delay_s : std_ulogic;
begin
  
  i_rs_encoder : rs_encoder_16_14
  port map(
    --SYNCHRO
    clk			  =>clk_i,
    rst_n		  =>rst_n_i,
    -- INPUT INTERFACE
    data_i		=>enc_data_s,
    valid_i		=>enc_valid_s,
    ready_o		=>enc_ready_s,
    -- OUTPUT INTERFACE
    data_o		=>enc_data_result_s,
    valid_o		=>enc_valid_result_s,
    -- DEBUG INTERFACE
    debug_o		=>enc_debug_s
  );
  
  i_rs_decoder : rs_16_14_decoder
	port map(
    -- SYNCHRO
    clk			  =>clk_i,
    rst_n		  =>rst_n_i,
    -- INPUT INTERFACE
    data_i		=>dec_data_s,
    valid_i		=>dec_valid_s,
    ready_o		=>dec_ready_s,
    -- OUTPUT INTERFACE
    data_o		=>dec_data_result_s,
    valid_o		=>dec_valid_result_s,
    cerr_o		=>dec_cerr_s,
    ncerr_o		=>dec_ncerr_s,
    -- DEBUG INTERFACE
    debug_o		=>dec_debug_s
	);
  
	PROC_MAIN_RS_CONTROL_P:process(rst_n_i,clk_i)
	begin
		if rst_n_i='0' then
			crt_state_s         <= STATE_RS_INIT;
      ram_data_s          <= (others=>'0');
      ram_wr_en_s         <='0';
      ram_rd_en_s         <='0';
      ram_address_s       <=(others=>'0');
      byte_count_s        <= 0;
      enc_valid_s         <= '0';
      enc_data_s          <= (others=>'0');
      dec_valid_s         <= '0';
      dec_data_s          <= (others=>'0');
      mem_word_count_s    <= 0;
      rs_base_address     <= (others=>'0');
      rs_data_original_s  <= (others=>'0');
      hps_mem_rdy_s       <= '0';
		elsif clk_i'event and clk_i='1' then
			case crt_state_s is
				when STATE_RS_INIT =>
					if start_decode_i = '1' or (hps_rs_exec_i='1' and hps_rs_en_decn_i='0') then 
            ram_data_s        <= (others=>'0');
            ram_wr_en_s       <= '0';
            ram_rd_en_s       <= '1';
            ram_address_s     <= hps_rs_addr_i;
            rs_base_address   <= hps_rs_addr_i;
						crt_state_s       <= STATE_RS_DECODE_READ;
					elsif start_encode_i='1' or (hps_rs_exec_i='1' and hps_rs_en_decn_i='1') then
            ram_data_s        <= (others=>'0');
            ram_wr_en_s       <= '0';
            ram_rd_en_s       <= '1';
            ram_address_s     <= hps_rs_addr_i;
            rs_base_address   <= hps_rs_addr_i;
						crt_state_s       <= STATE_RS_ENCODE_READ;
					elsif hps_mem_stb_i='1' and hps_mem_write_i='1' and hps_mem_rdy_s='0' then
            ram_data_s      <= hps_mem_wdata_i;
            ram_address_s   <= hps_mem_addr_i;
            ram_wr_en_s     <= '1';
            ram_rd_en_s     <= '0';
            rs_base_address <=(others=>'0');
						crt_state_s     <= STATE_RS_INIT;
					elsif hps_mem_stb_i='1' and hps_mem_write_i='0' and hps_mem_rdy_s='0' then
            ram_data_s      <= (others=>'0');
            ram_address_s   <= hps_mem_addr_i;
            ram_wr_en_s     <= '0';
            ram_rd_en_s     <= '1';
            rs_base_address <=(others=>'0');
						crt_state_s     <= STATE_RS_MEM_READ;
					else
            ram_data_s      <= (others=>'0');
            ram_address_s   <= (others=>'0');
            ram_wr_en_s     <= '0';
            ram_rd_en_s     <= '0';
            rs_base_address <=(others=>'0');
						crt_state_s     <= STATE_RS_INIT;
					end if;
          -------------------------------------
          byte_count_s      <= 0;
          enc_valid_s       <= '0';
          enc_data_s        <= (others=>'0');
          dec_valid_s       <= '0';
          dec_data_s        <= (others=>'0');
          mem_word_count_s  <= 0;
          hps_mem_rdy_s     <= '0';
          
				when STATE_RS_MEM_READ =>
          crt_state_s       <= STATE_RS_INIT;
          hps_mem_rdy_s     <= '1';
          ram_data_s        <= (others=>'0');
          ram_address_s     <= (others=>'0');
          ram_wr_en_s       <= '0';
          ram_rd_en_s       <= '0';
          -------------------------------------
          enc_valid_s       <= '0';
          enc_data_s        <= (others=>'0');
          dec_valid_s       <= '0';
          dec_data_s        <= (others=>'0');
          rs_base_address   <= (others=>'0');
          
				when STATE_RS_ENCODE_READ=>
          if mem_word_count_s<4 then
            case mem_word_count_s is
              when 0 => --wait 1 clock
              when 1 => rs_data_original_s(127 downto 96) <= ram_data_i;
              when 2 => rs_data_original_s(95 downto 64)  <= ram_data_i;
              when 3 => rs_data_original_s(63 downto 32)  <= ram_data_i;
              when others=> assert false report "[PROC_MAIN_RS_CONTROL_P]:: Wrong mem index when reading ENC data" severity error;
            end case;
            ram_address_s       <= std_ulogic_vector(unsigned(ram_address_s)+1);
            ram_wr_en_s         <= '0';
            ram_rd_en_s         <= '1';
            mem_word_count_s    <= mem_word_count_s+1;
            crt_state_s         <= STATE_RS_ENCODE_READ;
          else
            rs_data_original_s(31 downto 0) <= ram_data_i;
            mem_word_count_s                <= 0;
            ram_wr_en_s                     <= '0';
            ram_rd_en_s                     <= '0';
            crt_state_s                     <= STATE_RS_ENCODE_EXEC;
          end if;
          -------------------------------------
          byte_count_s      <= 0;
          enc_valid_s       <= '0';
          enc_data_s        <= (others=>'0');
          dec_valid_s       <= '0';
          dec_data_s        <= (others=>'0');
          hps_mem_rdy_s     <= '0';
				when STATE_RS_ENCODE_EXEC=>
          if byte_count_s<14 and enc_ready_s='1' then
            --ENCODER accepts current data
            case byte_count_s is
              when 0 => enc_data_s  <= rs_data_original_s(127 downto 120);
              when 1 => enc_data_s  <= rs_data_original_s(119 downto 112);
              when 2 => enc_data_s  <= rs_data_original_s(111 downto 104);
              when 3 => enc_data_s  <= rs_data_original_s(103 downto 96);
              when 4 => enc_data_s  <= rs_data_original_s(95  downto 88);
              when 5 => enc_data_s  <= rs_data_original_s(87  downto 80);
              when 6 => enc_data_s  <= rs_data_original_s(79  downto 72);
              when 7 => enc_data_s  <= rs_data_original_s(71  downto 64);
              when 8 => enc_data_s  <= rs_data_original_s(63  downto 56);
              when 9 => enc_data_s  <= rs_data_original_s(55  downto 48);
              when 10 => enc_data_s <= rs_data_original_s(47  downto 40);
              when 11 => enc_data_s <= rs_data_original_s(39  downto 32);
              when 12 => enc_data_s <= rs_data_original_s(31  downto 24);
              when 13 => enc_data_s <= rs_data_original_s(23  downto 16);
              when others =>
                --synthesis translate_off
                assert false report "" severity error;
                --synthesis translate_on
            end case;
            enc_valid_s     <= '1';
            byte_count_s    <= byte_count_s+1;
            crt_state_s     <= STATE_RS_ENCODE_EXEC;
            ram_rd_en_s     <= '0';
            ram_wr_en_s     <= '0';
          elsif byte_count_s<14 and enc_ready_s='0' then
            -- WAIT TIME FROM ENCODER, let's wait...
            enc_valid_s     <= '0';
            ram_rd_en_s     <= '0';
            ram_wr_en_s     <= '0';
            crt_state_s     <= STATE_RS_ENCODE_EXEC;
          else 
            --FINISH ENCODING CURRENT Block
            enc_data_s      <= (others=>'0');
            enc_valid_s     <= '0';
            ram_rd_en_s     <= '0';
            if enc_finish_s='1' then
              byte_count_s    <= 0;
              ram_wr_en_s     <= '1';
              ram_data_s      <= rs_enc_result_s(127 downto 96);
              crt_state_s     <= STATE_RS_ENCODE_STORE;
            else
              ram_wr_en_s     <= '0';
              ram_data_s      <= (others=>'0');
              crt_state_s     <= STATE_RS_ENCODE_EXEC;
            end if;
          end if;
          -------------------------------------
          ram_address_s     <= rs_base_address;
          mem_word_count_s  <= 1;
          hps_mem_rdy_s     <= '0';
          
				when STATE_RS_ENCODE_STORE =>
          if mem_word_count_s<4 then
            case mem_word_count_s is
              when 1=> ram_data_s  <= rs_enc_result_s(95 downto 64);
              when 2=> ram_data_s  <= rs_enc_result_s(63 downto 32);
              when 3=> ram_data_s  <= rs_enc_result_s(31 downto 0);
              when others=> assert false report "[PROC_MAIN_RS_CONTROL_P]:: Wrong mem index when storing ENC results" severity error;
            end case;
            ram_address_s       <= std_ulogic_vector(unsigned(ram_address_s)+1);
            ram_wr_en_s         <= '1';
            ram_rd_en_s         <= '0';
            mem_word_count_s    <= mem_word_count_s+1;
            crt_state_s         <= STATE_RS_ENCODE_STORE;
          else 
            ram_address_s       <= (others=>'0');
            ram_wr_en_s         <= '0';
            ram_rd_en_s         <= '0';
            mem_word_count_s    <= 0;
            crt_state_s         <= STATE_RS_INIT;
          end if;
          -------------------------------------
          enc_valid_s       <= '0';
          enc_data_s        <= (others=>'0');
          dec_valid_s       <= '0';
          dec_data_s        <= (others=>'0');
          hps_mem_rdy_s     <= '0';
          
        when STATE_RS_DECODE_READ=>
          if mem_word_count_s<4 then
            case mem_word_count_s is
              when 0=> --wait 1 clock delay
              when 1=> rs_data_original_s(127 downto 96) <= ram_data_i;
              when 2=> rs_data_original_s(95 downto 64)  <= ram_data_i;
              when 3=> rs_data_original_s(63 downto 32)  <= ram_data_i;
              when others=> assert false report "[PROC_MAIN_RS_CONTROL_P]:: Wrong mem index when reading DEC data" severity error;
            end case;
            ram_address_s                   <= std_ulogic_vector(unsigned(ram_address_s)+1);
            ram_wr_en_s                     <= '0';
            ram_rd_en_s                     <= '1';
            mem_word_count_s                <= mem_word_count_s+1;
            crt_state_s                     <= STATE_RS_DECODE_READ;
          else
            rs_data_original_s(31 downto 0) <= ram_data_i;
            mem_word_count_s                <= 0;
            ram_wr_en_s                     <= '0';
            ram_rd_en_s                     <= '0';
            crt_state_s                     <= STATE_RS_DECODE_EXEC;
          end if;
          -------------------------------------
          enc_valid_s       <= '0';
          enc_data_s        <= (others=>'0');
          dec_valid_s       <= '0';
          dec_data_s        <= (others=>'0');
          hps_mem_rdy_s     <= '0';
          
				when STATE_RS_DECODE_EXEC=>
          if byte_count_s<16 and dec_ready_s='1' then
            --ENCODER accepts current data
            case byte_count_s is
              when 0 => dec_data_s  <= rs_data_original_s(127 downto 120);
              when 1 => dec_data_s  <= rs_data_original_s(119 downto 112);
              when 2 => dec_data_s  <= rs_data_original_s(111 downto 104);
              when 3 => dec_data_s  <= rs_data_original_s(103 downto 96);
              when 4 => dec_data_s  <= rs_data_original_s(95  downto 88);
              when 5 => dec_data_s  <= rs_data_original_s(87  downto 80);
              when 6 => dec_data_s  <= rs_data_original_s(79  downto 72);
              when 7 => dec_data_s  <= rs_data_original_s(71  downto 64);
              when 8 => dec_data_s  <= rs_data_original_s(63  downto 56);
              when 9 => dec_data_s  <= rs_data_original_s(55  downto 48);
              when 10 => dec_data_s <= rs_data_original_s(47  downto 40);
              when 11 => dec_data_s <= rs_data_original_s(39  downto 32);
              when 12 => dec_data_s <= rs_data_original_s(31  downto 24);
              when 13 => dec_data_s <= rs_data_original_s(23  downto 16);
              when 14 => dec_data_s <= rs_data_original_s(15  downto 8);--RS1
              when 15 => dec_data_s <= rs_data_original_s(7   downto 0);--RS2
              when others =>
                --synthesis translate_off
                assert false report "" severity error;
                --synthesis translate_on
            end case;
            dec_valid_s     <= '1';
            byte_count_s    <= byte_count_s+1;
            crt_state_s     <= STATE_RS_DECODE_EXEC;
            ram_rd_en_s     <= '0';
            ram_wr_en_s     <= '0';
          elsif byte_count_s<16 and dec_ready_s='0' then
            -- WAIT TIME FROM ENCODER, let's wait...
            dec_valid_s     <= '0';
            ram_rd_en_s     <= '0';
            ram_wr_en_s     <= '0';
            crt_state_s     <= STATE_RS_DECODE_EXEC;
          else 
            --FINISH DECODING CURRENT Block
            dec_data_s      <= (others=>'0');
            dec_valid_s     <= '0';
            ram_rd_en_s     <= '0';
            if dec_finish_s='1' then
              byte_count_s  <= 0;
              ram_wr_en_s   <= '1';
              ram_data_s    <= rs_dec_result_s(127 downto 96);
              crt_state_s   <= STATE_RS_DECODE_STORE;
            else
              ram_wr_en_s   <= '0';
              ram_data_s    <= (others=>'0');
              crt_state_s   <= STATE_RS_DECODE_EXEC;
            end if;
          end if;
          -------------------------------------
          enc_valid_s       <= '0';
          enc_data_s        <= (others=>'0');
          ram_address_s     <= rs_base_address;
          mem_word_count_s  <= 1;
          hps_mem_rdy_s     <= '0';
        when STATE_RS_DECODE_STORE =>
          if mem_word_count_s<4 then
            case mem_word_count_s is
              when 1=> ram_data_s  <= rs_dec_result_s(95 downto 64);
              when 2=> ram_data_s  <= rs_dec_result_s(63 downto 32);
              when 3=> ram_data_s  <= rs_dec_result_s(31 downto 0);
              when others=> assert false report "[PROC_MAIN_RS_CONTROL_P]:: Wrong mem index when storing DEC results" severity error;
            end case;
            ram_address_s       <= std_ulogic_vector(unsigned(ram_address_s)+1);
            ram_wr_en_s         <= '1';
            ram_rd_en_s         <= '0';
            mem_word_count_s    <= mem_word_count_s+1;
            crt_state_s         <= STATE_RS_DECODE_STORE;
          else 
            ram_address_s       <= (others=>'0');
            ram_wr_en_s         <= '0';
            ram_rd_en_s         <= '0';
            mem_word_count_s    <= 0;
            crt_state_s         <= STATE_RS_INIT;
          end if;
          -------------------------------------
          enc_valid_s       <= '0';
          enc_data_s        <= (others=>'0');
          dec_valid_s       <= '0';
          dec_data_s        <= (others=>'0');
          hps_mem_rdy_s     <= '0';
            
				when others=>
					crt_state_s       <= STATE_RS_INIT;
					--pragma translate off
					assert false report "[RS_16_14_CONTROL]:: INVALID STATE REACHED!!!" severity error;
					--pragma translate on
			end case;
		end if;
	end process PROC_MAIN_RS_CONTROL_P;
  
  GET_RS_ENC_DATA_P:process(rst_n_i,clk_i)
  begin
    if rst_n_i = '0' then
      enc_byte_count_s  <= 0;
      rs_enc_result_s  <=(others=>'0');
      enc_finish_s      <= '0';
    elsif clk_i'event and clk_i='1' then
      if enc_byte_count_s<16 and enc_valid_result_s='1' then
        case enc_byte_count_s is
          when 0  => rs_enc_result_s(127 downto 120) <= enc_data_result_s;
          when 1  => rs_enc_result_s(119 downto 112) <= enc_data_result_s;
          when 2  => rs_enc_result_s(111 downto 104) <= enc_data_result_s;
          when 3  => rs_enc_result_s(103 downto 96)  <= enc_data_result_s;
          when 4  => rs_enc_result_s(95  downto 88)  <= enc_data_result_s;
          when 5  => rs_enc_result_s(87  downto 80)  <= enc_data_result_s;
          when 6  => rs_enc_result_s(79  downto 72)  <= enc_data_result_s;
          when 7  => rs_enc_result_s(71  downto 64)  <= enc_data_result_s;
          when 8  => rs_enc_result_s(63  downto 56)  <= enc_data_result_s;
          when 9  => rs_enc_result_s(55  downto 48)  <= enc_data_result_s;
          when 10 => rs_enc_result_s(47  downto 40)  <= enc_data_result_s;
          when 11 => rs_enc_result_s(39  downto 32)  <= enc_data_result_s;
          when 12 => rs_enc_result_s(31  downto 24)  <= enc_data_result_s;
          when 13 => rs_enc_result_s(23  downto 16)  <= enc_data_result_s;
          when 14 => rs_enc_result_s(15  downto 8)   <= enc_data_result_s;
          when 15 => rs_enc_result_s(7   downto 0)   <= enc_data_result_s;
          when others =>
            --synthesis translate_off
            assert false report "[GET_RS_ENC_DATA]:: invalid byte counter value!" severity error;
            --synthesis translate_on
        end case;
        enc_byte_count_s  <= enc_byte_count_s+1;
        if enc_byte_count_s=15 then
          enc_finish_s     <= '1';
        else
          enc_finish_s     <= '0';
        end if;
      elsif  enc_byte_count_s<16 and enc_valid_result_s='0' then
        --NOTHING TO DO
      else
        enc_byte_count_s <= 0;
        enc_finish_s     <= '0';
      end if;
    end if;
  end process GET_RS_ENC_DATA_P;
  
  GET_RS_DEC_DATA_P:process(rst_n_i,clk_i)
  begin
    if rst_n_i = '0' then
      dec_byte_count_s  <= 0;
      rs_dec_result_s  <=(others=>'0');
      dec_finish_s      <= '0';
    elsif clk_i'event and clk_i='1' then
      if dec_byte_count_s<14 and dec_valid_result_s='1' then
        case dec_byte_count_s is
          when 0  => rs_dec_result_s(127 downto 120) <= dec_data_result_s;
          when 1  => rs_dec_result_s(119 downto 112) <= dec_data_result_s;
          when 2  => rs_dec_result_s(111 downto 104) <= dec_data_result_s;
          when 3  => rs_dec_result_s(103 downto 96)  <= dec_data_result_s;
          when 4  => rs_dec_result_s(95  downto 88)  <= dec_data_result_s;
          when 5  => rs_dec_result_s(87  downto 80)  <= dec_data_result_s;
          when 6  => rs_dec_result_s(79  downto 72)  <= dec_data_result_s;
          when 7  => rs_dec_result_s(71  downto 64)  <= dec_data_result_s;
          when 8  => rs_dec_result_s(63  downto 56)  <= dec_data_result_s;
          when 9  => rs_dec_result_s(55  downto 48)  <= dec_data_result_s;
          when 10 => rs_dec_result_s(47  downto 40)  <= dec_data_result_s;
          when 11 => rs_dec_result_s(39  downto 32)  <= dec_data_result_s;
          when 12 => rs_dec_result_s(31  downto 24)  <= dec_data_result_s;
          when 13 => rs_dec_result_s(23  downto 16)  <= dec_data_result_s;
          when others =>
            --synthesis translate_off
            assert false report "[GET_RS_ENC_DATA]:: invalid byte counter value!" severity error;
            --synthesis translate_on
        end case;
        dec_byte_count_s  <= dec_byte_count_s+1;
        if dec_byte_count_s=13 then
          rs_dec_result_s(15 downto 0) <= (others=>'0');
          dec_finish_s                 <= '1';
        else
          dec_finish_s                 <= '0';
        end if;
      elsif  dec_byte_count_s<14 and dec_valid_result_s='0' then
        --NOTHING TO DO
      else
        dec_byte_count_s <= 0;
        dec_finish_s     <= '0';
      end if;
    end if;
  end process GET_RS_DEC_DATA_P;
	
	
	CLK_DELAY_P:process(rst_n_i,clk_i)
  begin
    if rst_n_i='0' then
      dec_finish_delay_s <= '0';
      enc_finish_delay_s <= '0';
    elsif clk_i'event and clk_i='1' then
      dec_finish_delay_s <= dec_finish_s;
      enc_finish_delay_s <= enc_finish_s;
    end if;--clk
  end process CLK_DELAY_P;
  
	ram_data_o 		  <= ram_data_s;
	ram_wr_en_o 	  <= ram_wr_en_s;
	ram_rd_en_o 	  <= ram_rd_en_s;
	ram_address_o   <= ram_address_s;
  
  encode_done_o   <= enc_finish_delay_s;
  decode_done_o   <= dec_finish_delay_s;
  
  dec_cerr_o      <= dec_cerr_s;
  dec_ncerr_o     <= dec_ncerr_s;
  hps_mem_rdy_o   <= hps_mem_rdy_s;
  hps_mem_rdata_o <= ram_data_i;
	
	--debug_o(7 downto 6) <=  "00" when crt_state_s = STATE_RS_INIT or crt_state_s = STATE_RS_MEM_READ else
  --                        "01" when crt_state_s = STATE_RS_MEM_WRITE else		
  --                        "10" when crt_state_s = STATE_RS_ENCODE_READ or crt_state_s = STATE_RS_ENCODE_EXEC else
  --                        "11";
	--debug_o(5)          <= enc_finish_s;
	--debug_o(4)          <= dec_finish_s;
  --debug_o(3 downto 0) <= (others=>'0');
  debug_o <= "111" when crt_state_s = STATE_RS_INIT else
             "001" when crt_state_s = STATE_RS_MEM_READ else
             "010" when crt_state_s = STATE_RS_ENCODE_READ or crt_state_s = STATE_RS_ENCODE_EXEC or crt_state_s=STATE_RS_ENCODE_STORE else
             "011" when crt_state_s = STATE_RS_DECODE_READ or crt_state_s = STATE_RS_DECODE_EXEC or crt_state_s=STATE_RS_DECODE_STORE else
             "000";
  
end architecture rtl;