-- ----------------------
-- Yann Oddos - 2016
-- ----------------------

library ieee;
	use ieee.std_logic_1164.all;
entity hps_rs_control_bridge is
generic(
  SLAVE_ADDR_BITWIDTH : integer :=  8
);
port(
  aresetn_i               : in std_ulogic;
  aclk_i                  : in std_ulogic;
  --AXI WRITE address channel
  chipselect_i            : in   std_ulogic;
  read_i                  : in   std_ulogic;
  write_i                 : in   std_ulogic;
  address_i               : in   std_ulogic_vector(SLAVE_ADDR_BITWIDTH-1 downto 0);
  writedata_i             : in   std_ulogic_vector(31 downto 0);
  readdata_o              : out  std_ulogic_vector(31 downto 0);
  readdatavalid_o         : out  std_ulogic;
  waitrequest_o           : out  std_ulogic;
  --RS_CONTROL INTF
	hps_mem_stb_o           : out  std_ulogic;
	hps_mem_write_o         : out  std_ulogic;
	hps_mem_wdata_o         : out  std_ulogic_vector(31 downto 0);
	hps_mem_addr_o          : out  std_ulogic_vector(7 downto 0);
	hps_mem_rdata_i         : in   std_ulogic_vector(31 downto 0);
  hps_mem_rdy_i           : in   std_ulogic;
	hps_rs_exec_o	          : out  std_ulogic;
	hps_rs_en_decn_o        : out  std_ulogic;
	hps_rs_addr_o	          : out  std_ulogic_vector(7 downto 0)
);
end entity hps_rs_control_bridge;


architecture rtl of hps_rs_control_bridge is
--READ -> always leads to a RS_CTRL read from on-chip memory
--WRITE ->
--ADDR bit 7:0 for the onchip memory
--ADDR bit 7:0 bit 10:8 -- control bits
--ctrl=000 -> write into memory the 32bits writedata
--ctrl=001 -> start encoding
--ctrl=010 -> start decoding
type  avalon_slave_fsm_enum is (AVALON_IDLE,AVALON_WRITE,AVALON_READ);
constant rs_ctrl_write_c  : std_ulogic_vector(2 downto 0):="000";
constant rs_ctrl_read_c   : std_ulogic_vector(2 downto 0):="001";
constant rs_ctrl_dec_c    : std_ulogic_vector(2 downto 0):="010";
constant rs_ctrl_enc_c    : std_ulogic_vector(2 downto 0):="011";

signal readdata_s         :  std_ulogic_vector(31 downto 0);
signal crt_state_s        : avalon_slave_fsm_enum; 
signal hps_mem_wdata_s    : std_ulogic_vector(31 downto 0);
signal hps_ctrl_s         : std_ulogic_vector(2 downto 0);
signal hps_mem_write_s    : std_ulogic;

signal hps_rs_exec_s      : std_ulogic;
signal hps_rs_en_decn_s   : std_ulogic;
signal hps_mem_stb_s      : std_ulogic;
signal hps_rs_addr_s      : std_ulogic_vector(7 downto 0);
signal readdatavalid_s    : std_ulogic;
signal waitrequest_s      : std_ulogic;
begin
  
  AVALON_SLAVE_P:process(aresetn_i,aclk_i)
  begin
    if aresetn_i='0' then
      hps_rs_exec_s     <= '0';
      hps_rs_en_decn_s  <= '0';
      hps_mem_stb_s     <= '0';
      hps_mem_write_s   <= '0';
      readdatavalid_s   <= '0';
      hps_rs_addr_s     <= (others=>'0');
      readdata_s        <= (others=>'0');
      hps_mem_wdata_s   <= (others=>'0');
      crt_state_s       <= AVALON_IDLE;
    elsif aclk_i'event and aclk_i='1' then
      case(crt_state_s) is
        when AVALON_IDLE  =>
          if chipselect_i='1' and write_i='1' and address_i(10 downto 8)=rs_ctrl_write_c then
            hps_rs_exec_s     <= '0';
            hps_rs_en_decn_s  <= '0';
            hps_mem_stb_s     <= '1';
            hps_mem_write_s   <= '1';
            hps_rs_addr_s     <= address_i(7 downto 0);
            hps_mem_wdata_s   <= writedata_i;
            crt_state_s       <= AVALON_IDLE;
          elsif chipselect_i='1' and write_i='1' and address_i(10 downto 8)=rs_ctrl_enc_c then
            hps_rs_exec_s     <= '1';
            hps_rs_en_decn_s  <= '1';
            hps_mem_stb_s     <= '0';
            hps_mem_write_s   <= '0';
            hps_rs_addr_s     <= address_i(7 downto 0);
            hps_mem_wdata_s   <= (others=>'0');
            crt_state_s       <= AVALON_IDLE;
          elsif chipselect_i='1' and write_i='1' and address_i(10 downto 8)=rs_ctrl_dec_c then
            hps_rs_exec_s     <= '1';
            hps_rs_en_decn_s  <= '0';
            hps_mem_stb_s     <= '0';
            hps_mem_write_s   <= '0';
            hps_rs_addr_s     <= address_i(7 downto 0);
            hps_mem_wdata_s   <= (others=>'0');
            crt_state_s       <= AVALON_IDLE;
          elsif chipselect_i='1' and read_i='1' then
            hps_rs_exec_s     <= '0';
            hps_rs_en_decn_s  <= '0';
            hps_mem_stb_s     <= '1';
            hps_mem_write_s   <= '0';
            hps_rs_addr_s     <= address_i(7 downto 0);
            hps_mem_wdata_s   <= (others=>'0');
            crt_state_s       <= AVALON_READ;
          else 
            hps_rs_exec_s     <= '0';
            hps_rs_en_decn_s  <= '0';
            hps_mem_stb_s     <= '0';
            hps_mem_write_s   <= '0';
            hps_mem_wdata_s   <= (others=>'0');
            hps_rs_addr_s     <= (others=>'0');
            crt_state_s <= AVALON_IDLE;
          end if;
          readdata_s        <= (others=>'0');
          readdatavalid_s   <= '0';
        when AVALON_READ => 
            if hps_mem_rdy_i='1' then
              readdatavalid_s   <= '1';
              readdata_s        <= hps_mem_rdata_i;
              crt_state_s       <= AVALON_IDLE;
            else
              readdatavalid_s   <= '0';
              readdata_s        <= (others=>'0');
              crt_state_s       <= AVALON_READ;
            end if;
            hps_rs_exec_s     <= '0';
            hps_rs_en_decn_s  <= '0';
            hps_mem_write_s   <= '0';
            hps_rs_addr_s     <= (others=>'0');
            hps_mem_wdata_s   <= (others=>'0');
        when others =>
          readdatavalid_s   <= '0';
          hps_rs_exec_s     <= '0';
          hps_rs_en_decn_s  <= '0';
          hps_mem_stb_s     <= '0';
          hps_mem_write_s   <= '0';
          hps_rs_addr_s     <= (others=>'0');
          hps_mem_wdata_s   <= (others=>'0');
          crt_state_s       <= AVALON_IDLE;
          assert false report "[AVALON_SLAVE_P]:: Wrong state reached!!!" severity error;
      end case;
    end if;
  end process AVALON_SLAVE_P;
  
  hps_mem_stb_o   <= hps_mem_stb_s;
  hps_mem_write_o <= hps_mem_write_s;
  hps_mem_wdata_o <= hps_mem_wdata_s;
  hps_mem_addr_o  <= hps_rs_addr_s;
  hps_rs_exec_o   <= hps_rs_exec_s;
  hps_rs_en_decn_o<= hps_rs_en_decn_s;
  hps_rs_addr_o   <= hps_rs_addr_s;
  readdata_o      <= readdata_s;
  readdatavalid_o <= readdatavalid_s;
  waitrequest_o   <= waitrequest_s;
  waitrequest_s   <= '0';--FIXME YODDOS
  
end architecture rtl;
