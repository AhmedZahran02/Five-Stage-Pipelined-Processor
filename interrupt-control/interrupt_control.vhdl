LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE ieee.numeric_std.ALL;

ENTITY interrupt_control IS
PORT (
memoryData : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
waitFor : IN std_logic_vector(1 downto 0);
int, clk, rst : IN STD_LOGIC;
globalReset, forceInstruction, takeMemoryControl, forcePc : OUT STD_LOGIC;
nextInstruction : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
nextPc : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
nextAddress : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
haltPc : OUT STD_LOGIC;
jump_occured : in std_logic;
decreament_signal : out std_logic
);
END interrupt_control;

ARCHITECTURE interrupt_control_archticture OF interrupt_control IS
COMPONENT genReg
GENERIC (
REG_SIZE : INTEGER := 32;
-- MoA : i need this for the stack pointer to be initialy = 2^12 - 1
RESET_VALUE : INTEGER := 0
);
PORT (
dataIn : IN STD_LOGIC_VECTOR(REG_SIZE - 1 DOWNTO 0);
writeEnable, clk, rst : IN STD_LOGIC;
dataOut : OUT STD_LOGIC_VECTOR(REG_SIZE - 1 DOWNTO 0)
);
END COMPONENT;

COMPONENT counter IS
GENERIC (
n : POSITIVE := 2
);
PORT (
clk : IN STD_LOGIC;
reset : IN STD_LOGIC;
load_enable : IN STD_LOGIC;
load_data : IN STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
result : OUT STD_LOGIC
);
END COMPONENT;

SIGNAL instructionMargin : std_logic_vector(1 downto 0);
SIGNAL currentState, nextState : STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL We1, regRst1, We2, regRst2, decreament_pc: STD_LOGIC;
SIGNAL regOut1, RegOut2 : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN
regRst1 <= '0';
regRst2 <= '0';

u1 : genReg PORT MAP(memoryData, We1, clk, regRst1, RegOut1);
u2 : genReg PORT MAP(memoryData, We2, clk, regRst2, RegOut2);

PROCESS (clk,rst,int)
BEGIN
    IF rst = '1' THEN
        nextState <= "0001";
        currentState <= "0000";
        forceInstruction <= '0';
        forcePc <= '0';
        haltPc <= '0';
        nextInstruction <= (others => '0');
        instructionMargin <= "00";
        nextPc <= (others => '0');
        globalReset <= '1';
        decreament_signal <= '0';
        We1 <= '0';
        We2 <= '0';
    ELSIF int = '1' and nextState = "0011" THEN
        nextState <= "0111";
        currentState <= "0111";
        instructionMargin <= waitFor;
        decreament_pc <= jump_occured;
        if waitFor = "00" then
            haltPc <= '1';
        else 
            haltPc <= '0';
        end if;
        forcePc <= '0';
    ELSIF rising_edge(clk) THEN
        currentState <= nextState;
    ELSIF falling_edge(clk) THEN
        CASE currentState is
            -- reset scenario
            when "0001" =>
                nextState <= "0010";
                nextAddress <= (others => '0');
                takeMemoryControl <= '1';
                We1 <= '1';
                We2 <= '0';
            when "0010" =>
                nextState <= "0011";
                forcePc <= '1';
                nextPc <= regOut1;
                nextAddress <= (1 => '1',others => '0');
                takeMemoryControl <= '1';
                We1 <= '0';
                We2 <= '1';
                
            
            -- int scenario
            when "0111" =>
                IF instructionMargin > "01" then
                    nextState <= "0111";
                    instructionMargin <= instructionMargin - 1;
                    haltPc <= '1';
                else
                    nextState <= "1000";
                    forceInstruction <= '1';
                    haltPc <= '1';
                    nextInstruction <= (others => '0');
                    nextInstruction <= "1001100000000000"; -- push flags instruction
                end if;
            
            when "1000" => 
                nextState <= "1001";
                forcePc <= '1';
                nextPc <= RegOut2;
                decreament_signal <= decreament_pc;
                nextInstruction <= "1111000000000000"; -- push pc instruction
            
            when "1001" =>
                nextState <= "0011";
                decreament_signal <= '0';
                haltPc <= '0';
                forcePc <= '0';
                forceInstruction <= '0';


            -- idle state;
            when "0011" =>
                nextState <= "0011";
                globalReset <= '0';
                forcePc <= '0';
                takeMemoryControl <= '0';
                We1 <= '0';
                We2 <= '0';

            when others =>
                We1 <= '0';
                We2 <= '0';
                forcePc <= '0';
                takeMemoryControl <= '0';
        end case;

    END IF;
END PROCESS;

END interrupt_control_archticture;