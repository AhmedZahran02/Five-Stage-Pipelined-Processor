.data 
4294967295
2
3
4
5
6
7
54
568
561548
879654
9844
545
1
51
51
8
6
165
1
.code

.ORG 5
NOP
NOT R0
NEG R1
ADDI R3,R3,10
OUT R3
IN R4
SWAP R5,R6
ADD R7,R0,R1
ADDI R2,R3,5
SUB R7,R1,R0
AND R5,R7,R0
OR R5,R5,R5
XOR R3,R3,R3
CMP R0,R1
BITSET R5,30
RCL R7, 3
RCR R6, 8
PUSH R0
POP R1
LDM R5,16
LDD R2, 1048575
STD R2, 0
PROtect R0
Free R1
JZ R5
JMP R7
CALL R0
RET 
RTI