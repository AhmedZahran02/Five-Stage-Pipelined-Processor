instructions = {
    'NOP': '00000',
    'NOT': '00001',
    'NEG': '00010',
    'INC': '00011',
    'DEC': '00100',
    'OUT': '00101',
    'IN': '00110',
    'ADD': '00111',
    'ADDI': '01000',
    'SUB': '01001',
    'AND': '01010',
    'OR': '01011',
    'XOR': '01100',
    'CMP': '01101',
    'BITSET': '01110',
    'RCL': '01111',
    'RCR': '10000',
    'PUSH': '10001',
    'POP': '10010',
    'PUSHF': '10011',
    'POPF': '10100',
    'LDM': '10101',
    'LDD': '10110',
    'STD': '10111',
    'PROTECT': '11000',
    'FREE': '11001',
    'JZ': '11010',
    'JMP': '11011',
    'CALL': '11100',
    'RET': '11101',
    'SWAP': '11110',
    'RETI': '11111'
}
# Imm = [
#     'ADDI','BITSET','RCL','RCR','LDM'
# ]
last_2_bits = {
    'NOP': '00',
    'NOT': '00',
    'NEG': '00',
    'INC': '00',
    'DEC': '00',
    'OUT': '00',
    'IN': '00',
    'ADD': '00',
    'ADDI': '01',
    'SUB': '00',
    'AND': '00',
    'OR': '00',
    'XOR': '00',
    'CMP': '00',
    'BITSET': '00',
    'RCL': '00',
    'RCR': '00',
    'PUSH': '00',
    'POP': '00',
    'PUSHF': '00',
    'POPF': '00',
    'LDM': '01',
    'LDD': '01',
    'STD': '01',
    'PROTECT': '00',
    'FREE': '00',
    'JZ': '01',
    'JMP': '01',
    'CALL': '01',
    'RET': '11',
    'SWAP': '00',
    'RETI': '11'
}

registers = {
    'R0': '000',
    'R1': '001',
    'R2': '010',
    'R3': '011',
    'R4': '100',
    'R5': '101',
    'R6': '110',
    'R7': '111',
}

def assemble(file_path):
    # Dictionary for storing the memory contents
    mode = False
    memory = {}
    current_address = None
    dataMemory = {}
    data_address = None

    with open(file_path, 'r') as f:
        for line in f:
            # Uppercase the line for Consistency
            line = line.upper()
            # Ignore lines starting with '#' and empty lines
            if line.startswith('#') or not line.strip():
                continue

            # Remove comments from the line
            line = line.split('#')[0].strip()
            
            # handle mode
            if line.startswith('.DATA'):
                mode = True
                continue
            
            if line.startswith('.CODE'):
                mode = False
                continue
            
            # Skipppp directives
            if line.startswith('.ORG'):
                if mode:
                    data_address = int(line.split()[1], 16)
                else :
                    current_address = int(line.split()[1], 16)
                continue
            
            if mode:
                [data_address,dataMemory]=handleMemory(line,dataMemory,data_address)
            else:
                [current_address,memory]=handleInstruction(line,memory,current_address)

    return [memory,dataMemory]

def handleInstruction(line,memory,current_address):
    
    # Check if the line starts with a numeric value
    if line.lstrip()[0].isdigit():
        return [current_address,memory]
    
    # Parse instructions
    tokens  = [elem.replace(',',' ').strip() for elem in line.split(' ')]
    new_tokens = [item for token in tokens for item in (token.split() if ' ' in token else [token])]

    tokens= new_tokens
    # print(f"tokens {tokens}")
    if not tokens:
        return {current_address,memory}

    instruction = tokens[0].upper()
    args = tokens[1:] if len(tokens) > 1 else []


    # Check if the instruction is recognized
    if instruction not in instructions:
        print(f"Error: Unrecognized instruction '{instruction}'")
        return [None,None]

    # Ensure consistency in formatting
    formatted_args = [arg for arg in args if arg.strip()]
    # print(f"formatted_args {formatted_args}")

    # Split the first element of args if it contains commas
    if formatted_args:
        # Assuming Rsrc1 and Rsrc2 are arguments in positions 1 and 2
        Rdst = formatted_args[0] if formatted_args else 'R0'
        Rsrc1 = formatted_args[1] if len(formatted_args) > 1 and args[-1].isdigit() == False else 'R0'
        Rsrc2 = formatted_args[2] if len(formatted_args) > 2 and args[-1].isdigit() == False else 'R0'
    else:
        Rdst, Rsrc1, Rsrc2 = 'R0', 'R0', 'R0' 

    # Handle swap
    if instruction == "SWAP":
        machine_code = instructions[instruction] + registers['R0'] + registers[Rdst] + registers[Rsrc1]
    else:
        machine_code = instructions[instruction] + registers[Rdst] + registers[Rsrc1] + registers[Rsrc2]

    if instruction in last_2_bits:
        machine_code += last_2_bits[instruction]

    # Store the machine code in memory
    memory[current_address] = machine_code
    current_address += 2

    # Handle the imm value
    if formatted_args and formatted_args[-1].isdigit():
        # Handle immediate value separately
        imm_value = int(formatted_args[-1])
        imm_instruction = format(imm_value, '016b')

        memory[current_address] = imm_instruction
        current_address += 2  # Assuming 2 bytes per instruction
    return [current_address,memory]

def handleMemory(line,dataMemory,data_address):
    if(data_address is None):
        data_address=0
    data = format(int(line), '032b')
    part1 = data[:16]
    part2 = data[16:]
    dataMemory[data_address] = part1
    dataMemory[data_address+1] = part2
    data_address += 2
    return [data_address,dataMemory]

def write_to_file(memory,dataMemory, output_file='out.txt'):
    if memory is None:
        print("Error during assembly. Cannot write to file.")
        return

    with open(output_file, 'w') as out_file:
        for address, machine_code in sorted(memory.items()):
            out_file.write(f"{machine_code}\n")
    with open("instructionMemory.txt", 'w') as out_file:
        for address, machine_code in sorted(memory.items()):
            out_file.write(f"{hex(address)[2:]} {machine_code}\n")
    
    if dataMemory is None:
        print("Error during assembly. Cannot write to file.")
        return

    with open("dataMemory.txt", 'w') as out_file:
        for data_address, data in sorted(dataMemory.items()):
            out_file.write(f"{hex(data_address)[2:]} {data}\n")


file_path = 'inst2.asm'
[memory,dataMemory] = assemble(file_path)

if memory is not None:
    write_to_file(memory,dataMemory)