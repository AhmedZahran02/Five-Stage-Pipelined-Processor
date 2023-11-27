library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.all;

entity memory is
    Generic ( 
        DATA_BUS_SIZE : integer := 32; 
        ADDRESS_BUS_SIZE : integer := 12 
    ); 
    
    Port (
            input_data_bus : in std_logic_vector(DATA_BUS_SIZE - 1 downto 0);
            address_bus : in std_logic_vector(ADDRESS_BUS_SIZE - 1 downto 0);
            --================================================================
            write_enable : in std_logic;
            free_enable : in std_logic;
            protect_enable : in std_logic;
            clk : in std_logic;
            reset : in std_logic;
            --================================================================
            output_data_bus: out std_logic_vector(DATA_BUS_SIZE - 1 downto 0)
        );
end memory;

architecture memory_architecture of memory is

    --variable protected_bit : std_logic_vector(2**ADDRESS_BUS_SIZE - 1 downto 0);
    TYPE ram_type IS ARRAY(0 TO 2**ADDRESS_BUS_SIZE) of std_logic_vector(DATA_BUS_SIZE - 1 DOWNTO 0);
    signal ram : ram_type;
    signal protect_bit : std_logic_vector(2**ADDRESS_BUS_SIZE - 1 downto 0);
begin

    process(clk,reset)
    begin

        if reset = '1' then 
            ram <= (others => (others => '0'));
            protect_bit <= (others => '0');
        elsif rising_edge(clk) then
            if write_enable = '1' and protect_bit(to_integer(unsigned(address_bus))) = '0' then
                ram(to_integer(unsigned(address_bus))) <= input_data_bus;
        
            elsif protect_enable = '1' then
                protect_bit(to_integer(unsigned(address_bus))) <= '1';
            
            elsif free_enable = '0' then
                protect_bit(to_integer(unsigned(address_bus))) <= '0';

            end if;
        end if;

    end process;

    output_data_bus <= (others => '0') when reset = '1' else ram(to_integer(unsigned(address_bus)));
    
end memory_architecture;