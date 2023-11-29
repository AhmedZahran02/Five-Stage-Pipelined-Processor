
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.std_logic_textio.all;
use std.textio.all;
use IEEE.numeric_STD.ALL;

entity alu is 
GENERIC (n : integer := 32;
	 SelSize : integer := 3 );
port(
	Data1,Data2: in std_logic_vector (n - 1 downto 0) ; 
	Sel: in std_logic_vector(SelSize - 1 downto 0);
	FlagsIn:in std_logic_vector(2 downto 0);
	FlagsOut:out std_logic_vector(2 downto 0) ;
	Imm : in INTEGER := 2;
	DataOut : out std_logic_vector(n - 1 downto 0));

end entity alu;

architecture Structural of alu is 

component n_bit_adder IS
GENERIC (n : integer);
PORT   (a, b : IN std_logic_vector(n-1 DOWNTO 0) ;
             cin : IN std_logic;
             s : OUT std_logic_vector(n-1 DOWNTO 0);
             cout : OUT std_logic);

END component n_bit_adder;


component GenericMux is
    generic (
        M : positive;  
        K : positive);
    port (
        Inputs   : in  std_logic_vector(2**K * M - 1 downto 0);  -- Input signals
        Sel      : in  std_logic_vector(K - 1 downto 0);          -- Select lines
        Output   : out std_logic_vector(M - 1 downto 0)           -- Output signal
    );
end component GenericMux;



signal AND_OUT,OR_OUT,XOR_OUT,ADD_OUT,SUB_OUT,Neg_OUT,RR_OUT,Data1_Bar,Data2_Bar :std_logic_vector(n-1 downto 0);
signal RL_OUT :std_logic_vector(n - 1 downto 0);
signal Mux_Input  : std_logic_vector(2**SelSize * n - 1 downto 0);
signal Z1,Z2,Z3,C1,C2,C3,N1,N2,N3,dummy1 : std_logic;

begin

Data1_Bar <= not Data1;
Data2_Bar <= not Data2;

Neg_OUT <= (not Data1) + "1"; 

AND_OUT <= Data1 AND Data2;
OR_OUT <= Data1 OR Data2;
XOR_OUT <= Data1 XOR Data2;

-- Rotate Right operation with carry
--RR_OUT(n - 1) <= FlagsIn(2);              
--RR_OUT(n - 2 downto 0) <= Data1(n - 1 downto 1);
--C2 <= Data1(0);-----> carry  

-- Rotate left operation with carry
--RL_OUT(0) <= FlagsIn(2);              
--RL_OUT(n downto 1) <= Data1(n - 1 downto 0); 
--C3 <= RL_OUT(n - 1);  -----> carry

-- RCL operation
RL_OUT(n - 1 downto Imm ) <= Data1(n-1 - Imm downto 0);
RL_OUT(Imm - 1 downto 0) <= Data1(N-1 downto N - Imm);
--C3 <= Data1(N-1 - Imm);

-- RCR operation
-- Uncomment the following lines for RCR
-- temp_result <= Rsrc(7 - Imm downto 0) & Rsrc(7 downto 8 - Imm);
-- temp_carry <= Rsrc(7 downto 8 - Imm)(7);

Mux_Input <= RL_OUT & SUB_OUT & ADD_Out & XOR_OUT & OR_OUT & AND_OUT & Neg_OUT & Data1_Bar;

addition: n_bit_adder GENERIC MAP (n) port map (Data1,Data2,'0',ADD_Out,C1);

subtraction: n_bit_adder GENERIC MAP (n) port map (Data1,Data2_Bar,'1',SUB_OUT,dummy1);

selectTheOutput: GenericMux GENERIC MAP (n,SelSize) port map (Mux_Input,Sel,DataOut);
end architecture Structural;