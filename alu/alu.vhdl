
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.std_logic_textio.all;
use std.textio.all;
use IEEE.numeric_STD.ALL;

entity alu is 
GENERIC (n : integer := 32;
	 SelSize : integer := 4 );
port(
	Data1,Data2: in std_logic_vector (n - 1 downto 0) ; 
	Sel: in std_logic_vector(SelSize - 1 downto 0);
	FlagsIn:in std_logic_vector(2 downto 0);
	FlagsOut:out std_logic_vector(2 downto 0) ;
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

    -- function binary_to_integer(bin_val : std_logic_vector) return natural is
    --     variable result : natural := 0;
    --     variable temp : natural := 1;
    -- begin
    --     for i in 31 to 24 loop
    --         if bin_val(i) = '1' then
    --             result := result + temp;
    --         end if;
    --         temp := temp * 2; 
    --     end loop;
    --     return result;
    -- end function;

signal NOP,INC_OUT,DEC_OUT,AND_OUT,OR_OUT,XOR_OUT,ADD_OUT,SUB_OUT,Neg_OUT,Data1_Bar,Data2_Bar,BITSET_OUT,buff :std_logic_vector(n-1 downto 0);
signal RR_OUT,RL_OUT,RL,RR :std_logic_vector(n downto 0);
signal Mux_Input  : std_logic_vector(2**SelSize * n - 1 downto 0);
signal C1_inc,C1_add,C1_sub,C1_dec,C1_setbit,C1_RR,C1_RL,dummy1,dummy2 : std_logic;
signal Index, anotherIndex,currentbit : natural;
signal oneVector: std_logic_vector(n - 1 downto 0) := "00000000000000000000000000000001";
signal dummy32: std_logic_vector(n - 1 downto 0) := "00000000000000000000000000000000";--- you can remove the dummy if you want to add a new operation

signal dummyMoa : std_logic;

signal rbimmediate: integer;
begin


--NOP => 0000
NOP <= X"00000000";

--NOT op1 => 0001
Data1_Bar <= not Data1;
Data2_Bar <= not Data2;

--NEG op1 => 0010
Neg_OUT <= (not Data1) + "1"; 

--INC op1 => 0011
increment: n_bit_adder GENERIC MAP (n) port map (Data1,(others=>'0'),'1',INC_OUT,C1_inc);

--DEC op1 => 0100
decrement: n_bit_adder GENERIC MAP (n) port map (Data1,(others=>'1'),'0',DEC_OUT,dummy1);

--op1 => 0101
--op2 => 0110

--add op1 op2 => 0111
addition: n_bit_adder GENERIC MAP (n) port map (Data1,Data2,'0',ADD_Out,C1_add);

--sub op1 op2 => 1000
subtraction: n_bit_adder GENERIC MAP (n) port map (Data1,Data2_Bar,'1',SUB_OUT,dummy2);


C1_dec <= dummy1 when Sel = "0100"
	else '0';

C1_sub <= dummy2 when Sel = "1000"
	else '0';

--and op1 op2 => 1001
AND_OUT <= Data1 AND Data2;

--or op1 op2 => 1010
OR_OUT <= Data1 OR Data2;

--xor op1 op2 => 1011
XOR_OUT <= Data1 XOR Data2;

rbimmediate <= to_integer(unsigned(Data2(5 downto 0)));

process(Data1,Data2,Sel,rbimmediate)
        variable temp_result : STD_LOGIC_VECTOR(n - 1 downto 0);
    begin
        if rbimmediate >= 0 and rbimmediate <= n - 1 then
            temp_result := Data1;
            temp_result(rbimmediate) := '1';
            BITSET_OUT <= temp_result;
        else
            BITSET_OUT <= Data1;
        end if;
end process;

C1_setbit <= '1';
--RCL op1 op1 => 1101
process (Data1, Data2,Sel,rbimmediate,FlagsIn)
begin
	RL(0) <= FlagsIn(2);
	RL(n downto 1) <= Data1(n - 1 downto 0);
    if rbimmediate >= 0 and rbimmediate <= 31 then
        anotherIndex <= rbimmediate;
    end if;
end process;

process (Data1, Data2, anotherIndex,RL ,Sel,FlagsIn)
begin
    if anotherIndex < 32 and anotherIndex >= 0 then
        RL_OUT <= (others=>'0');
        RL_OUT (anotherIndex - 1 downto 0) <= RL(n downto n - anotherIndex + 1);
        RL_OUT (n downto anotherIndex) <= RL(n - anotherIndex downto 0);
    end if;
end process;

C1_RL <= RL_OUT(0);

--RCR op1 op1 => 1110
process (Data1, Data2,Sel,rbimmediate,FlagsIn)
begin
	RR(0) <= FlagsIn(2);
	RR(n downto 1) <= Data1(n - 1 downto 0);
    if rbimmediate >= 0 and rbimmediate <= 31 then
        Index <= rbimmediate;
    end if;
end process;

process (Data1, Data2, Index,RR,Sel,FlagsIn)
begin
    if Index < 32 and Index >= 0 then
        RR_OUT <= (others=>'0');
        RR_OUT (n downto n - Index + 1) <= RR(Index - 1 downto 0);
        RR_OUT (n - Index downto 0) <= RR(n downto Index);
    end if;
end process;

C1_RR <= RR_OUT(0);

Mux_Input <= XOR_OUT & RR_OUT (n  downto 1)&RL_OUT (n  downto 1)& BITSET_OUT  & XOR_OUT & OR_OUT & AND_OUT &SUB_OUT & ADD_Out & Data2 & Data1 & DEC_OUT& INC_OUT & Neg_OUT & Data1_Bar &  NOP;

selectTheOutput: GenericMux GENERIC MAP (n,SelSize) port map (Mux_Input,Sel,buff);

--carry flag
FlagsOut(2) <= 
    C1_inc when  Sel="0011"
	else C1_dec when Sel = "0100"  
	else C1_add when Sel = "0111" 
	else C1_sub when Sel = "1000"
	else C1_setbit when Sel = "1100" 
  	else C1_RL when Sel = "1101" 
	else C1_RR when Sel = "1110" 
	else FlagsIn(2) ;

--negative flag
FlagsOut(1) <= FlagsIn(1) when (Sel = "0000" or Sel = "1111" or Sel = "0101" or Sel = "0110" or Sel = "1100")
    else buff(n - 1);

dummyMoa <= '1' When buff = "00000000000000000000000000000000" else '0';
--zero flag
FlagsOut(0) <= FlagsIn(0) WHEN (Sel = "0000" or Sel = "1111" or Sel = "0101" or Sel = "0110" or Sel = "1100") ELSE
               '1' WHEN buff = "00000000000000000000000000000000" ELSE
               '0';

DataOut <= buff;

end architecture Structural;