LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY fetch_stage IS
PORT (
forceInstruction : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
regFileReadI : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
memoryData : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
isRetOperation : IN STD_LOGIC;
isNonContionalJump : IN STD_LOGIC;
isJumpZero : IN STD_LOGIC;
zeroFlag : IN STD_LOGIC;
nextPc : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
forcePc : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
nextInstruction : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
clk : IN STD_LOGIC;
reset: IN STD_LOGIC;
holdPc : IN STD_LOGIC;
--------------------------------------------------
currentPc : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
instructionOut : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
instructionMemoryOut : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
waitFor : OUT STD_LOGIC_VECTOR(1 downto 0);
nextCalculatedPC : OUT std_logic_vector(31 downto 0);
stall_flush_counter : in std_logic
);
END fetch_stage;

ARCHITECTURE fetch_stage_architecture OF fetch_stage IS

COMPONENT GenericMux IS
GENERIC (
M : POSITIVE := 32;
K : POSITIVE := 1
);
PORT (
Inputs : IN STD_LOGIC_VECTOR(2 ** K * M - 1 DOWNTO 0); -- Input signals
Sel : IN STD_LOGIC_VECTOR(K - 1 DOWNTO 0); -- Select lines
Output : OUT STD_LOGIC_VECTOR(M - 1 DOWNTO 0) -- Output signal
);
END COMPONENT;

COMPONENT n_bit_adder IS
GENERIC (n : INTEGER := 32);
PORT (
a, b : IN STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
cin : IN STD_LOGIC;
s : OUT STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
cout : OUT STD_LOGIC);
END COMPONENT;

COMPONENT genReg IS
GENERIC (
REG_SIZE : INTEGER := 32;
RESET_VALUE : INTEGER := 0
);
PORT (
dataIn : IN STD_LOGIC_VECTOR(REG_SIZE - 1 DOWNTO 0);
writeEnable, clk, rst : IN STD_LOGIC;
dataOut : OUT STD_LOGIC_VECTOR(REG_SIZE - 1 DOWNTO 0)
);
END COMPONENT;

COMPONENT memory IS
PORT (
input_data_bus : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
address_bus : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
extra_address : IN STD_LOGIC;
--================================================================
write_enable : IN STD_LOGIC;
free_enable : IN STD_LOGIC;
protect_enable : IN STD_LOGIC;
clk : IN STD_LOGIC;
reset : IN STD_LOGIC;
--================================================================
output_data_bus : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
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
result : OUT std_logic_vector(n-1 downto 0);
next_count : OUT std_logic_vector(n-1 downto 0);
counter_enable : IN std_logic
);
END COMPONENT;

COMPONENT special_instruction_handler IS
    PORT (
        instructionIn : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        clk, bypass : IN STD_LOGIC;
        current_pc : in std_logic_vector(31 downto 0);

        --==================================================================
        instructionOut : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        isSpecial : OUT STD_LOGIC;
        stallCyclesCount : out std_logic_vector(1 downto 0)

    );
END COMPONENT;

SIGNAL one : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
SIGNAL zero : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
SIGNAL concatZeroOne : STD_LOGIC_VECTOR(63 DOWNTO 0);
SIGNAL pcAddValue : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL pcaddedValue : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL Cin : STD_LOGIC := '0';
SIGNAL Cout : STD_LOGIC;
SIGNAL pcNonMaskedValue : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL pcNonMaskedInput : STD_LOGIC_VECTOR(127 DOWNTO 0);
SIGNAL pcNonMaskedSel : STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL pcMaskedValue : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL pcMaskedInput : STD_LOGIC_VECTOR(63 DOWNTO 0);
SIGNAL inCurrentPc : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL instrNonMaskedValueTemp : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL instrNonMaskedValue : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL instrMaskedInput : STD_LOGIC_VECTOR(63 DOWNTO 0);
SIGNAL instrMaskedValue : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL instrMaskedSel : STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL NOP : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
SIGNAL counterResult : STD_LOGIC_VECTOR(1 downto 0);
SIGNAL counterWe : STD_LOGIC;
signal pcReset : std_logic;

signal negClk : std_logic;
signal holdPcCounter: std_logic_vector(0 downto 0);
signal flushNextInstruction : std_logic;
signal passNextInstruction : std_logic;

signal specialCount : std_logic_vector(1 downto 0);
signal specialInstructionCircuitInput: std_logic_vector(15 downto 0);
signal isSpecial : std_logic;

signal next_count : std_logic_vector(1 downto 0);
signal next_flush : std_logic_vector(15 downto 0);
signal instruction_waitfor : std_logic_vector(1 downto 0);
signal latch_reset : std_logic;
signal counter_enable : std_logic;
BEGIN

PROCESS (inCurrentPc) BEGIN
currentPc <= inCurrentPc;
END PROCESS;

PROCESS (instrMaskedValue,counterResult) BEGIN
IF reset = '1' then
  waitFor <= "00";
else
  waitFor <= (instruction_waitfor) or (next_count) or specialCount;
end if;
instructionOut <= instrMaskedValue;
END PROCESS;

passNextInstruction <= not flushNextInstruction;
latch_reset <= reset or flushNextInstruction;

genreg_inst: genReg
generic map (
  REG_SIZE    => 2
)
port map (
  dataIn      => instrMaskedValue(1 downto 0),
  writeEnable => passNextInstruction,
  clk         => clk,
  rst         => latch_reset,
  dataOut     => instruction_waitfor
);

one(0) <= '1';
concatZeroOne <= zero & one;
holdPcCounter(0) <= holdPc or isSpecial;
u1 : GenericMux PORT MAP(concatZeroOne, holdPcCounter, pcAddValue);

u2 : n_bit_adder PORT MAP(inCurrentPc, pcAddValue, Cin, pcaddedValue, Cout);

pcNonMaskedInput <= memoryData & memoryData & regFileReadI & pcaddedValue;
pcNonMaskedSel <= isRetOperation & (isJumpZero OR isNonContionalJump);

u3 : GenericMux GENERIC MAP(32, 2) PORT MAP(pcNonMaskedInput, pcNonMaskedSel, pcNonMaskedValue);

pcMaskedInput <= nextPc & pcNonMaskedValue;

u4 : GenericMux GENERIC MAP(32, 1) PORT MAP(pcMaskedInput, forcePc, pcMaskedValue);

pcReset <= reset and (not forcePc(0));

nextCalculatedPC <= pcNonMaskedValue WHEN isJumpZero = '0' ELSE pcaddedValue;
negClk <= not clk;

u5 : genReg PORT MAP(pcMaskedValue, '1', negClk, pcReset, inCurrentPc);

u7 : memory PORT MAP((OTHERS => '0') ,inCurrentPc(11 downto 0), '0', '0', '0', '0', clk, reset, instrNonMaskedValueTemp);
instructionMemoryOut <= instrNonMaskedValueTemp(15 downto 0);
specialInstructionCircuitInput <= instrNonMaskedValueTemp(15 DOWNTO 0) when forceInstruction(0) = '0' else (others => '0');

special_instruction_handler_inst: special_instruction_handler
port map (
  instructionIn    => specialInstructionCircuitInput,
  clk              => clk,
  bypass           => forceInstruction(0),
  instructionOut   => instrNonMaskedValue,
  isSpecial        => isSpecial,
  stallCyclesCount => specialCount,
  current_pc       => inCurrentPc
);

next_flush <= NOP or ("00000000000000" & next_count);

instrMaskedInput <= nextInstruction & nextInstruction & next_flush & instrNonMaskedValue;
flushNextInstruction <= '0' WHEN counterResult = "00" ELSE '1';
instrMaskedSel <= forceInstruction & flushNextInstruction;

u8 : GenericMux GENERIC MAP(16, 2) PORT MAP(instrMaskedInput, instrMaskedSel, instrMaskedValue);

counterWe <= instrMaskedValue(1) OR instrMaskedValue(0);

counter_enable <= not stall_flush_counter; 

u9 : counter PORT MAP(clk, reset, counterWe, instrMaskedValue(1 DOWNTO 0), counterResult, next_count,counter_enable);
END fetch_stage_architecture;