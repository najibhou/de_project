-- ----------------------
-- Yann Oddos - 2016
-- ----------------------

-- ----------------------------------------------------
-- RS(16,14) with 8bits symbols
-- GF(256) polynomial generator : p(x)=x^8+x^7+x^2+x+1
-- g(x)=(x-alpha^1)*(x-alpha^2) <=> g(x)=(x+2)*(x+4)
-- g(x)=x^2+6*x+8
-- ----------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;


package rs_16_14_pkg is

	constant DEBUG_ENABLE : NATURAL :=1; --! Enable disable debug_o port utilization
	
	type gf256_type is array(0 to 255) of std_ulogic_vector(7 downto 0);
	
	constant inverses_table : gf256_type:=(
		"00000000","00000001","11000011","10000010","10100010","01111110","01000001","01011010",
		"01010001","00110110","00111111","10101100","11100011","01101000","00101101","00101010",
		"11101011","10011011","00011011","00110101","11011100","00011110","01010110","10100101",
		"10110010","01110100","00110100","00010010","11010101","01100100","00010101","11011101",
		"10110110","01001011","10001110","11111011","11001110","11101001","11011001","10100001",
		"01101110","11011011","00001111","00101100","00101011","00001110","10010001","11110001",
		"01011001","11010111","00111010","11110100","00011010","00010011","00001001","01010000",
		"10101001","01100011","00110010","11110101","11001001","11001100","10101101","00001010",
		"01011011","00000110","11100110","11110111","01000111","10111111","10111110","01000100",
		"01100111","01111011","10110111","00100001","10101111","01010011","10010011","11111111",
		"00110111","00001000","10101110","01001101","11000100","11010001","00010110","10100100",
		"11010110","00110000","00000111","01000000","10001011","10011101","10111011","10001100",
		"11101111","10000001","10101000","00111001","00011101","11010100","01111010","01001000",
		"00001101","11100010","11001010","10110000","11000111","11011110","00101000","11011010",
		"10010111","11010010","11110010","10000100","00011001","10110011","10111001","10000111",
		"10100111","11100100","01100110","01001001","10010101","10011001","00000101","10100011",
		"11101110","01100001","00000011","11000010","01110011","11110011","10111000","01110111",
		"11100000","11111000","10011100","01011100","01011111","10111010","00100010","11111010",
		"11110000","00101110","11111110","01001110","10011000","01111100","11010011","01110000",
		"10010100","01111101","11101010","00010001","10001010","01011101","10111100","11101100",
		"11011000","00100111","00000100","01111111","01010111","00010111","11100101","01111000",
		"01100010","00111000","10101011","10101010","00001011","00111110","01010010","01001100",
		"01101011","11001011","00011000","01110101","11000000","11111101","00100000","01001010",
		"10000110","01110110","10001101","01011110","10011110","11101101","01000110","01000101",
		"10110100","11111100","10000011","00000010","01010100","11010000","11011111","01101100",
		"11001101","00111100","01101010","10110001","00111101","11001000","00100100","11101000",
		"11000101","01010101","01110001","10010110","01100101","00011100","01011000","00110001",
		"10100000","00100110","01101111","00101001","00010100","00011111","01101101","11000110",
		"10001000","11111001","01101001","00001100","01111001","10100110","01000010","11110110",
		"11001111","00100101","10011010","00010000","10011111","10111101","10000000","01100000",
		"10010000","00101111","01110010","10000101","00110011","00111011","11100111","01000011",
		"10001001","11100001","10001111","00100011","11000001","10110101","10010010","01001111"
	);--! Stores all the inverses coefficients for all the GF(256) values
	
	function full_multiplier_g256(A: std_ulogic_vector(7 downto 0); B:std_ulogic_vector(7 downto 0)) return std_ulogic_vector; --! Global Multiplication in GF(256) with p(x)=x^8+x^7+x^2+x+1

	function mult2(d: std_ulogic_vector(7 downto 0)) return std_ulogic_vector; --! Multiplication by 2 in GF(256) with p(x)=x^8+x^7+x^2+x+1
	function mult4(d: std_ulogic_vector(7 downto 0)) return std_ulogic_vector; --! Multiplication by 4 in GF(256) with p(x)=x^8+x^7+x^2+x+1
	function mult6(d: std_ulogic_vector(7 downto 0)) return std_ulogic_vector; --! Multiplication by 6 in GF(256) with p(x)=x^8+x^7+x^2+x+1
	function mult8(d: std_ulogic_vector(7 downto 0)) return std_ulogic_vector; --! Multiplication by 8 in GF(256) with p(x)=x^8+x^7+x^2+x+1
	
	function conv_string_to_byte(str: string(1 to 2)) return std_ulogic_vector;
end package;

package body rs_16_14_pkg is

	function full_multiplier_g256(A: std_ulogic_vector(7 downto 0); B:std_ulogic_vector(7 downto 0)) return std_ulogic_vector is
	variable F 	: std_ulogic_Vector(14 downto 0);
	variable res: std_ulogic_vector(7 downto 0);
	begin
		F(0)  := (A(0) and B(0));
        F(1)  := (A(1) and B(0)) xor (A(0) and B(1));
        F(2)  := (A(2) and B(0)) xor (A(1) and B(1)) xor (A(0) and B(2));
        F(3)  := (A(3) and B(0)) xor (A(2) and B(1)) xor (A(1) and B(2)) xor (A(0) and B(3));
        F(4)  := (A(4) and B(0)) xor (A(3) and B(1)) xor (A(2) and B(2)) xor (A(1) and B(3)) xor (A(0) and B(4));
        F(5)  := (A(5) and B(0)) xor (A(4) and B(1)) xor (A(3) and B(2)) xor (A(2) and B(3)) xor (A(1) and B(4)) xor (A(0) and B(5));
        F(6)  := (A(6) and B(0)) xor (A(5) and B(1)) xor (A(4) and B(2)) xor (A(3) and B(3)) xor (A(2) and B(4)) xor (A(1) and B(5)) xor (A(0) and B(6));
        F(7)  := (A(7) and B(0)) xor (A(6) and B(1)) xor (A(5) and B(2)) xor (A(4) and B(3)) xor (A(3) and B(4)) xor (A(2) and B(5)) xor (A(1) and B(6)) xor (A(0) and B(7));
        F(8)  := (A(7) and B(1)) xor (A(6) and B(2)) xor (A(5) and B(3)) xor (A(4) and B(4)) xor (A(3) and B(5)) xor (A(2) and B(6)) xor (A(1) and B(7));
        F(9)  := (A(7) and B(2)) xor (A(6) and B(3)) xor (A(5) and B(4)) xor (A(4) and B(5)) xor (A(3) and B(6)) xor (A(2) and B(7));
        F(10) := (A(7) and B(3)) xor (A(6) and B(4)) xor (A(5) and B(5)) xor (A(4) and B(6)) xor (A(3) and B(7));
        F(11) := (A(7) and B(4)) xor (A(6) and B(5)) xor (A(5) and B(6)) xor (A(4) and B(7));
        F(12) := (A(7) and B(5)) xor (A(6) and B(6)) xor (A(5) and B(7));
        F(13) := (A(7) and B(6)) xor (A(6) and B(7));
        F(14) := (A(7) and B(7));
         
        res(7)  := F(12) xor F(11) xor F(10) xor F(9) xor F(8) xor F(7);
        res(6)  := F(14) xor F(12) xor F(6);
        res(5)  := F(14) xor F(13) xor F(11) xor F(5);
        res(4)  := F(14) xor F(13) xor F(12) xor F(10) xor F(4);
        res(3)  := F(14) xor F(13) xor F(12) xor F(11) xor F(9) xor F(3);
        res(2)  := F(2) xor F(13) xor F(12) xor F(11) xor F(10) xor F(8);
        res(1)  := F(14) xor F(8) xor F(1);
        res(0)  := F(0) xor F(13) xor F(12) xor F(11) xor F(10) xor F(8) xor F(9);
		
		return res;
	end function;
	
	 -- -------------------------
	 -- a8  = a7+a2+a+1
	 -- a9  = a7+a3+1
	 -- a10 = a7+a4+a2+1
	 -- a11 = a7+a5+a3+a2+1
	 -- a12 = a7+a6+a4+a3+a2+1
	 -- a13 = a5+a4+a3+a2+1
	 -- a14 = a6+a5+a4+a3+a
	 -- a15 = a7+a6+a5+a4+a2
	 -- ------------------------
	
	function mult2(d: std_ulogic_vector(7 downto 0)) return std_ulogic_vector is
	variable res : std_ulogic_vector(7 downto 0);
	begin
		res(7) := d(7) xor d(6);
		res(6) := d(5);
		res(5) := d(4);
		res(4) := d(3);
		res(3) := d(2);
		res(2) := d(7) xor d(1);
		res(1) := d(7) xor d(0);
		res(0) := d(7);
		
		return res;
	end function;
	
	function mult4(d: std_ulogic_vector(7 downto 0)) return std_ulogic_vector is
	variable res : std_ulogic_vector(7 downto 0);
	begin
		
		res(7) := d(7) xor d(6) xor d(5);
		res(6) := d(4);
		res(5) := d(3);
		res(4) := d(2);
		res(3) := d(7) xor d(1);
		res(2) := d(6) xor d(0);
		res(1) := d(6);
		res(0) := d(7) xor d(6);
		
		return res;
	end function;
	
	function mult6(d: std_ulogic_vector(7 downto 0)) return std_ulogic_vector is
	variable res : std_ulogic_vector(7 downto 0);
	begin
		
		res(7) := d(5);
		res(6) := d(5) xor d(4);
		res(5) := d(4) xor d(3);
		res(4) := d(3) xor d(2);
		res(3) := d(7) xor d(2) xor d(1);
		res(2) := d(7) xor d(6) xor d(1) xor d(0);
		res(1) := d(7) xor d(6) xor d(0);
		res(0) := d(6);
		
		return res;
	end function;
	
	function mult8(d: std_ulogic_vector(7 downto 0)) return std_ulogic_vector is
	variable res : std_ulogic_vector(7 downto 0);
	begin
		
		res(7) := d(7) xor d(6) xor d(5) xor d(4);
		res(6) := d(3);
		res(5) := d(2);
		res(4) := d(7) xor d(1);
		res(3) := d(6) xor d(0);
		res(2) := d(7) xor d(5);
		res(1) := d(5);
		res(0) := d(7) xor d(6) xor d(5);
		
		return res;
	end function;
	
	function conv_string_to_byte(str: string(1 to 2)) return std_ulogic_vector is
	variable res : std_ulogic_vector(7 downto 0);
	begin
		case str(1) is
			when '0' => res(7 downto 4):="0000";
			when '1' => res(7 downto 4):="0001";
			when '2' => res(7 downto 4):="0010";
			when '3' => res(7 downto 4):="0011";
			when '4' => res(7 downto 4):="0100";
			when '5' => res(7 downto 4):="0101";
			when '6' => res(7 downto 4):="0110";
			when '7' => res(7 downto 4):="0111";
			when '8' => res(7 downto 4):="1000";
			when '9' => res(7 downto 4):="1001";
			when 'a' => res(7 downto 4):="1010";
			when 'b' => res(7 downto 4):="1011";
			when 'c' => res(7 downto 4):="1100";
			when 'd' => res(7 downto 4):="1101";
			when 'e' => res(7 downto 4):="1110";
			when 'f' => res(7 downto 4):="1111";
			when others => report "[RS_16_14]:: String value str(1) error!!! Character <"&str(1)&"> should be an hexadecimal value belonging to [0..F]" severity error;
		end case;
		
		case str(2) is
			when '0' => res(3 downto 0):="0000";
			when '1' => res(3 downto 0):="0001";
			when '2' => res(3 downto 0):="0010";
			when '3' => res(3 downto 0):="0011";
			when '4' => res(3 downto 0):="0100";
			when '5' => res(3 downto 0):="0101";
			when '6' => res(3 downto 0):="0110";
			when '7' => res(3 downto 0):="0111";
			when '8' => res(3 downto 0):="1000";
			when '9' => res(3 downto 0):="1001";
			when 'a' => res(3 downto 0):="1010";
			when 'b' => res(3 downto 0):="1011";
			when 'c' => res(3 downto 0):="1100";
			when 'd' => res(3 downto 0):="1101";
			when 'e' => res(3 downto 0):="1110";
			when 'f' => res(3 downto 0):="1111";
			when others => report "[RS_16_14]:: String value str(2) error!!! Character <"&str(1)&"> should be an hexadecimal value belonging to [0..F]" severity error;
		end case;
		
		return res;
	end function;
	
end rs_16_14_pkg;