LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY controlUnit IS
PORT (
opCode : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
controlSignals : OUT STD_LOGIC_VECTOR(21 DOWNTO 0)
);
END controlUnit;

ARCHITECTURE controlUnit_architecture OF controlUnit IS
BEGIN
PROCESS (opCode)
BEGIN

-- Initialize
controlSignals <= (OTHERS => '0');

CASE opCode IS
-- NOP
WHEN "00000" =>
controlSignals <= (OTHERS => '0');
-- NOT
WHEN "00001" =>
controlSignals <= "1000000000100000000010";
-- NEG
WHEN "00010" =>
controlSignals <= "1000000001000000000010";
-- INC
WHEN "00011" =>
controlSignals <= "1000000001100000000010";
-- DEC
WHEN "00100" =>
controlSignals <= "1000000010000000000010";
-- OUT
WHEN "00101" =>
controlSignals <= "1000000010100000000001";
-- IN
WHEN "00110" =>
controlSignals <= "1000001011000000000010";
-- ADD
WHEN "00111" =>
controlSignals <= "0000000011100000000010";
-- ADDI
WHEN "01000" =>
controlSignals <= "0010000011100000000010";
-- SUB
WHEN "01001" =>
controlSignals <= "0000000100000000000010";
-- AND
WHEN "01010" =>
controlSignals <= "0000000100100000000010";
-- OR
WHEN "01011" =>
controlSignals <= "0000000101000000000010";
-- XOR
WHEN "01100" =>
controlSignals <= "0000000101100000000010";
-- CMP
WHEN "01101" =>
controlSignals <= "0000000100000000000000";
-- BITSET
WHEN "01110" =>
controlSignals <= "1001000110000000000010";
-- RCL
WHEN "01111" =>
controlSignals <= "1001000110100000000010";
-- RCR
WHEN "10000" =>
controlSignals <= "1001000111000000000010";
-- PUSH
WHEN "10001" =>
controlSignals <= "1000000000001100010000";
-- POP
WHEN "10010" =>
controlSignals <= "1000000000001000100010";
-- PUSH FLAGS
WHEN "10011" =>
controlSignals <= "1000000000001100111000";
-- POP FLAGS
WHEN "10100" =>
controlSignals <= "1000000000001000100100";
-- LDM
WHEN "10101" =>
controlSignals <= "1010000011000000000010";
-- LDD
WHEN "10110" =>
controlSignals <= "1011000011000000100010";
-- STD
WHEN "10111" =>
controlSignals <= "1011000011000100000000";
-- PROTECT
WHEN "11000" =>
controlSignals <= "1000000010100010000000";
-- FREE
WHEN "11001" =>
controlSignals <= "1000000010100001000000";
-- JZ
WHEN "11010" =>
controlSignals <= "1000010000000000000000";
-- JMP
WHEN "11011" =>
controlSignals <= "1000100000000000000000";
-- CALL
WHEN "11100" =>
controlSignals <= "1100100000001100110000";
-- RET
WHEN "11101" =>
controlSignals <= "0000000000011000100000";
-- PUSH PC (internal instruction)
WHEN "11110" =>
controlSignals <= "1100000000001100110000";
-- Special Xor (internal instruction)
WHEN "11111" =>
controlSignals <= "0000000111100000000010";
WHEN OTHERS =>
controlSignals <= (OTHERS => '0');
END CASE;
END PROCESS;
END controlUnit_architecture;