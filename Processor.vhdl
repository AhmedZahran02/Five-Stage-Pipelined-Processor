LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY processor IS
PORT (
port_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
port_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
protected_warning : out std_logic;

clk : IN STD_LOGIC;
interrupt_signal : IN STD_LOGIC;
reset_signal : IN STD_LOGIC
);
END processor;

ARCHITECTURE arch OF processor IS



    component genReg is
        generic (
            REG_SIZE : INTEGER := 32;
            RESET_VALUE : INTEGER := 0 
        );
        port (
            dataIn : IN STD_LOGIC_VECTOR(REG_SIZE - 1 DOWNTO 0);
            writeEnable, clk, rst : IN STD_LOGIC;
            dataOut : OUT STD_LOGIC_VECTOR(REG_SIZE - 1 DOWNTO 0)
        );
    end component;

    component interrupt_control IS
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
    END component;

    component fetch_stage IS
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
        waitFor : OUT std_logic_vector(1 downto 0);
        nextCalculatedPC : OUT std_logic_vector(31 downto 0);  
        stall_flush_counter : IN std_logic
        );
    END component;

    component decode_stage IS
        GENERIC (
            REG_SIZE : INTEGER := 32;
            REG_NUMBER : INTEGER := 8;
            CONTROL_SIGNAL_SIZE : INTEGER := 22
        );
        PORT (
            -- fetch
            op_code : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            immediate_16 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            
            -- execute 
            execute_destination : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            execute_will_write_back : IN STD_LOGIC;
            is_pop_register : IN STD_LOGIC;

            -- memory
             memory_destination : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            memory_will_write_back : IN STD_LOGIC;

            -- write back 
            write_register_address : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            should_write_back : IN STD_LOGIC;
            load_data : IN STD_LOGIC_VECTOR(REG_SIZE - 1 DOWNTO 0);

            input_port : IN STD_LOGIC_VECTOR(REG_SIZE - 1 DOWNTO 0);
            --==================================================================
            clk : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            --==================================================================
            control_signals_out : OUT STD_LOGIC_VECTOR(CONTROL_SIGNAL_SIZE - 1 DOWNTO 0);
            operand_1 : OUT STD_LOGIC_VECTOR(REG_SIZE - 1 DOWNTO 0);
            operand_2 : OUT STD_LOGIC_VECTOR(REG_SIZE - 1 DOWNTO 0);
            write_back_register_address : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);        
            hazard_code : out std_logic_vector(3 downto 0);
            stall_signal : out std_logic
        );
    END component;

    component execute_stage is 
        GENERIC (
            n : integer := 32;
            SelSize : integer := 4 
        );
        port(
            operand_i,operand_ii: in std_logic_vector (n - 1 downto 0) ; 
            function_select : in std_logic_vector(SelSize - 1 downto 0);
            
            memory_data_out : in std_logic_vector(31 downto 0);
            is_pop_flags_operation : in std_logic;
    
            clk : in std_logic;
            rst : in std_logic;
    
            current_flags : out std_logic_vector(3 downto 0) ;
            next_flags : out std_logic_vector(3 downto 0);
            alu_result : out std_logic_vector(n - 1 downto 0);
            is_jump_zero : in std_logic
            );
        
    end component;

    component memory_stage is
        generic (
            DATA_SIZE : integer := 32; 
            SP_STEP : integer := 2;
            FLAGS_COUNT : integer := 4
        );
        Port (
            memory_data_in : in std_logic_vector(DATA_SIZE - 1 downto 0);
            address : in std_logic_vector(DATA_SIZE - 1 downto 0);
            input_flags : in std_logic_vector(FLAGS_COUNT - 1 downto 0);
            --==================================================================
            -- control signals
            write_enable : in std_logic;
            protect_address : in std_logic;
            free_address : in std_logic;
    
            memory_operation : in std_logic;
    
            is_stack_operation : in std_logic;
            inc_dec_stack : in std_logic; -- if 0 will increament else decreament
    
            is_push_flags : in std_logic;
    
            clk : in std_logic;
            reset : in std_logic;
            --==================================================================
            memory_data_result : out std_logic_vector(DATA_SIZE - 1 downto 0);   
            protected_flag_output : out std_logic;    
            final_data : out std_logic_vector(DATA_SIZE - 1 downto 0)         
        );
    end component;

    component writeback_stage IS
        GENERIC (
            REG_SIZE : INTEGER := 32
        );
        PORT (
            output_port_select : STD_LOGIC;
            writeback_address_in : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            writeback_data_in : IN STD_LOGIC_VECTOR(REG_SIZE - 1 DOWNTO 0);
            --==================================================================
            clk : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            --==================================================================
            writeback_address_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
            output_port : OUT STD_LOGIC_VECTOR(REG_SIZE - 1 DOWNTO 0);
            writeback_data_out : OUT STD_LOGIC_VECTOR(REG_SIZE - 1 DOWNTO 0)
        );
    END component;
    -- fetch stage output wires
    signal global_reset : std_logic;
    signal current_pc : std_logic_vector(31 downto 0);
    signal stall_pc_counter : std_logic;
    signal interrupt_halt_pc : std_logic;
    signal nextCalculatedPc : std_logic_vector(31 downto 0);
    signal wait_for : std_logic_vector(1 downto 0);
    signal instruction_memory_out : std_logic_vector(15 downto 0);

    -- decode stage output wires
    signal jump_destination : std_logic_vector(31 downto 0);
    signal control_signal_out : std_logic_vector(21 downto 0);
    signal hazard_code : std_logic_vector(3 downto 0);

    -- execute stage output wires
    signal resolved_source_1 : std_logic_vector(31 downto 0);
    signal resolved_source_2 : std_logic_vector(31 downto 0);
    signal operand_1_selector : std_logic_vector(31 downto 0);
    signal current_flags : std_logic_vector(3 downto 0); 
    signal next_flags : std_logic_vector(3 downto 0);


    -- memory stage output wires
    signal alu_result : std_logic_vector(31 downto 0);
    signal memory_data_out : std_logic_vector(31 downto 0);
    signal address_selection : std_logic_vector(31 downto 0);

    -- write back wires 
    signal mem_result : std_logic_vector(31 downto 0);
    signal write_back_data :std_logic_vector(31 downto 0);
    signal write_back_address :std_logic_vector(2 downto 0);

    -- 32 pc + 16 opcode
    signal fetch_stage_output   : std_logic_vector(47 downto 0);  
    signal decode_stage_input  : std_logic_vector(47 downto 0);
    --  32 pc + 4 hazard code + 18 control signal == 3 write back address == 32 operand-1 == 32 operand-2
    signal decode_stage_output  : std_logic_vector(120 downto 0);
    signal execute_stage_input : std_logic_vector(120 downto 0);
    -- 11 control signal == 3 write back address == 32 operand-1 == 32 operand-2
    signal execute_stage_output : std_logic_vector(77 downto 0);
    signal memory_stage_input  : std_logic_vector(77 downto 0);
    -- 4 control signal == 3 write back address == 32 write back data
    signal memory_stage_output  : std_logic_vector(38 downto 0);
    signal write_back_stage_input  : std_logic_vector(38 downto 0);

    signal latched_input_port : std_logic_vector(31 downto 0);

    signal next_instruction : std_logic_vector(15 downto 0);
    signal next_pc : std_logic_vector(31 downto 0);
    signal next_address : std_logic_vector(31 downto 0);
    signal take_memory_control_signal : std_logic;
    signal force_instruction_signal : std_logic_vector(0 downto 0);
    signal force_pc_signal : std_logic_vector(0 downto 0);

    signal is_pop_operation : std_logic;
    signal stall_decode_and_fetch : std_logic;
    signal hold_decode_buffer : std_logic;
    signal flush_execute_buffer : std_logic;


    signal jump_occured : std_logic;
    signal decreament_signal : std_logic;
BEGIN

jump_occured <= write_back_stage_input(37) or execute_stage_input(83) or execute_stage_input(82);

-- place interruption control here
interrupt_control_inst: interrupt_control
port map (
  memoryData        => memory_data_out,
  waitFor           => wait_for,
  int               => interrupt_signal,
  clk               => clk,
  rst               => reset_signal,
  globalReset       => global_reset,
  forceInstruction  => force_instruction_signal(0),
  takeMemoryControl => take_memory_control_signal,
  forcePc           => force_pc_signal(0),
  nextInstruction   => next_instruction,
  nextPc            => next_pc,
  nextAddress       => next_address,
  haltPc            => interrupt_halt_pc,
  jump_occured      => jump_occured,
  decreament_signal => decreament_signal
);
stall_pc_counter <= interrupt_halt_pc or stall_decode_and_fetch;


-- place fetch stage here and connect fetch_stage_output correct according to the comment
fetch: fetch_stage
port map (
  forceInstruction     => force_instruction_signal,
  regFileReadI         => jump_destination, 
  memoryData           => write_back_stage_input(31 downto 0),
  isRetOperation       => write_back_stage_input(37), 
  isNonContionalJump   => execute_stage_input(83),
  isJumpZero           => execute_stage_input(82),
  zeroFlag             => current_flags(0),
  holdPC               => stall_pc_counter,
  nextPc               => next_pc,
  forcePc              => force_pc_signal,
  nextInstruction      => next_instruction,
  clk                  => clk,
  reset                => global_reset,
  currentPc            => current_pc,
  instructionOut       => fetch_stage_output(15 downto 0),
  instructionMemoryOut => instruction_memory_out,
  waitFor              => wait_for,
  nextCalculatedPC     => nextCalculatedPc,
  stall_flush_counter       => stall_decode_and_fetch
); 

-- if not jz or zero flag is 1 then take the resolved register else take the next pc
jump_destination <= resolved_source_1 WHEN 
(execute_stage_input(82) = '0' or current_flags(0) = '1')  ELSE 
execute_stage_input(116 downto 85);

latchin_input: genReg generic map(32,0) port map(
    dataIn => port_in,
    writeEnable => '1', 
    clk => clk,
    rst => global_reset,
    dataOut => latched_input_port
);

-- passing current pc in case of call operation
fetch_stage_output(47 downto 16) <= nextCalculatedPc WHEN decreament_signal = '0' else (nextCalculatedPc - 1);

hold_decode_buffer <= not stall_decode_and_fetch;

IF_ID: genReg generic map(48,0) port map(
    dataIn => fetch_stage_output,
    writeEnable => hold_decode_buffer, 
    clk => clk,
    rst => global_reset,
    dataOut => decode_stage_input
);

-- place decode stage here and connect decode_stage_output correct according to the comment
decode: decode_stage
    generic map (
    REG_SIZE            => 32,
    REG_NUMBER          => 8,
    CONTROL_SIGNAL_SIZE => 22
    )
    port map (
    op_code                     => decode_stage_input(15 downto 0),
    immediate_16                => instruction_memory_out,

    execute_destination         => execute_stage_input(66 downto 64),
    execute_will_write_back     => execute_stage_input(68),
    is_pop_register             => is_pop_operation,

    memory_destination          => memory_stage_input(66 downto 64),
    memory_will_write_back      => memory_stage_input(68),
    
    write_register_address      => write_back_address,
    should_write_back           => write_back_stage_input(36),
    load_data                   => write_back_data,
    
    input_port                  => latched_input_port,
    clk                         => clk,
    reset                       => global_reset,

    control_signals_out         => control_signal_out,
    write_back_register_address => decode_stage_output(66 downto 64),
    operand_1                   => decode_stage_output(63 downto 32),
    operand_2                   => decode_stage_output(31 downto 0),
    hazard_code                 => hazard_code,
    stall_signal                => stall_decode_and_fetch
);

-- is stack operation and poping
is_pop_operation <= execute_stage_input(76) and (not execute_stage_input(71));


-- hazard code if any
decode_stage_output(120 downto 117) <= hazard_code;
-- next pc of the currently decoded instruction
decode_stage_output(116 downto 85) <= decode_stage_input(47 downto 16);
-- control flags
decode_stage_output(84 downto 67) <= 
control_signal_out(20) & control_signal_out(17) & control_signal_out(16) & control_signal_out(14 downto 0);


flush_execute_buffer <= stall_decode_and_fetch or global_reset;
ID_IE: genReg generic map(121,0) port map(
    dataIn => decode_stage_output,
    writeEnable => '1', 
    clk => clk,
    rst => flush_execute_buffer,
    dataOut => execute_stage_input
);

forwarding_unit_inst: entity work.forwarding_unit
port map (
  source_1_no_hazard  => execute_stage_input(63 downto 32),
  source_2_no_hazard  => execute_stage_input(31 downto 0),
  source_1_alu_result => alu_result,
  source_2_alu_result => alu_result,
  source_1_mem_result => mem_result,
  source_2_mem_result => mem_result,
  hazard_code         => execute_stage_input(120 downto 117),
  operand_1           => resolved_source_1,
  operand_2           => resolved_source_2
);

-- select the pc if it's call instruction or else keep going
operand_1_selector <= resolved_source_1 WHEN execute_stage_input(84) = '0' ELSE execute_stage_input(116 downto 85); 
-- place execute stage here and connect execute_stage_output correct according to the comment
exec: execute_stage generic map(32,4) port map(
    operand_i => operand_1_selector,
    operand_ii => resolved_source_2,
    function_select => execute_stage_input(81 downto 78),

    memory_data_out => write_back_stage_input(31 downto 0),
    is_pop_flags_operation => write_back_stage_input(38), -- from memory

    clk => clk,
    rst => global_reset,

    current_flags => current_flags,
    next_flags => next_flags,
    alu_result => execute_stage_output(31 downto 0),
    is_jump_zero => execute_stage_input(82)
);
execute_stage_output(63 downto 32) <= operand_1_selector;
execute_stage_output(66 downto 64) <= execute_stage_input(66 downto 64);
execute_stage_output(77 downto 67) <= execute_stage_input(77 downto 67);

IE_IM: genReg generic map(78,0) port map(
    dataIn => execute_stage_output,
    writeEnable => '1', 
    clk => clk,
    rst => global_reset,
    dataOut => memory_stage_input
);

-- place memory stage here and connect memory_stage_output correct according to the comment

alu_result <= memory_stage_input(31 downto 0);
address_selection <= memory_stage_input(31 downto 0) WHEN take_memory_control_signal = '0' ELSE next_address;

memo : memory_stage generic map(32,2,4) port map (
    memory_data_in => memory_stage_input(63 downto 32),
    address => address_selection,
    input_flags => current_flags,
   
    -- change the flags later
    write_enable => memory_stage_input(75),
    protect_address => memory_stage_input(74),
    free_address => memory_stage_input(73),

    memory_operation => memory_stage_input(72),

    is_stack_operation => memory_stage_input(76),
    inc_dec_stack => memory_stage_input(71),

    is_push_flags => memory_stage_input(70),

    clk => clk,
    reset => global_reset,
    
    memory_data_result => memory_data_out,     
    protected_flag_output => protected_warning,  
    final_data => memory_stage_output(31 downto 0)     
);
memory_stage_output(34 downto 32) <= memory_stage_input(66 downto 64);
memory_stage_output(36 downto 35) <= memory_stage_input(68 downto 67);
memory_stage_output(38 downto 37) <= memory_stage_input(69) & memory_stage_input(77);

IM_IW: genReg generic map(39,0) port map(
    dataIn => memory_stage_output,
    writeEnable => '1', 
    clk => clk,
    rst => global_reset,
    dataOut => write_back_stage_input
);

mem_result <= write_back_stage_input(31 downto 0);
-- place write back stage here
writeback: writeback_stage
generic map (
  REG_SIZE            => 32
)
port map (
  output_port_select    => write_back_stage_input(35),
  writeback_address_in  => write_back_stage_input(34 downto 32),
  writeback_data_in     => write_back_stage_input(31 downto 0),
  clk                   => clk,
  reset                 => global_reset,
  writeback_address_out => write_back_address,
  output_port           => port_out,
  writeback_data_out    => write_back_data
);

END arch;