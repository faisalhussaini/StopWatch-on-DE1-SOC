// Timer/Stopwatch that counts in seconds and tens of milliseconds. Wraps around from 59:99 to 00:00. any key to pause
	.text
	.global _start

_start: LDR R0, =0xFF200020       // R0 has Hex 0
	LDR R1, =0xFF20005C       // R1 has Edgecapture
 	LDR R2, =BITCODE          // R2 has hex codes
	MOV R3, #0                // flag to keep track of edgecapture, true when key is pressed
	MOV R4, #-1               // Initilize to -1 so will display 0 after incrementing ms
	MOV R5, #0		  // Initilize to -1 so will display 0 after incrementing s
 	LDR R9, =0xFFFEC600       // R9 has Private Timer

EDGECAPTURE:
	LDR R6, [R1]             
	CMP R6, #1
	BGE EDGERESET             // if key is pressed, then edgeregister has 1
	
	CMP R3, #0                // if flag is false, increment
	BGE INCREMENT

	B EDGECAPTURE             // flag is true, pause by continuting to loop 

EDGERESET:
	//To avoid "missing" button presses. When KEY is pressed, bit in edgecapture is set to 1
	// remains set until reset to 0. Reset by writing 1
	
	MOV R6, #RESETCODE
	LDR R6, [R6]
	STR R6, [R1] 		// reset the Edgecapture
	
	MVN R3, R3   		// flip edgecapture flag
	CMP R3, #0   		// if flag is false, increment cause key is not pressed
	BGE INCREMENT

	B EDGECAPTURE           // flag is true, pause by continuting to loop 

INCREMENT:
	CMP R4, #99 		// reset if ms 99 else increment
	BGE RESET

	ADD R4, #1
	B PREDIVIDE

RESET: 	MOV R4, #0 		//reset ms
	
	CMP R5, #59
	MOVGE R5, #-1 		//if 59 then reset
	
	
	ADD R5, #1		// else increment the seconds

PREDIVIDE:
	//display the seconds
	PUSH {R1, R3}
	
	MOV R3, R5
	BL DIVIDE
 
	LDRB R7, [R2, R1] 	//R1 holds tens, R3 Holds ones
	LDRB R8, [R2, R3]

	LSL R7, #8
	ADD R7, R8 	  	// concatonate the numbers seconds

	//display the ms
	MOV R3, R4
	BL DIVIDE

	LDRB R8, [R2, R1]
	LSL R7, #8
	ADD R7, R8	

	LDRB R8, [R2, R3]
	LSL R7, #8
	ADD R7, R8		// concatonate the ms

	STR R7, [R0]		// write to hex

	POP {R1, R3}
	B DELAY

DIVIDE:	MOV R1, #0 		//counter for 10s place

COUNT:	CMP R3, #10
   	MOVLT PC, LR 		//return to predivide
    	SUB R3, #10
    	ADD R1, #1
    	B COUNT	

DELAY:	LDR R8, =DELAYCOUNT
	LDR R8, [R8]	
	STR R8, [R9] 		// write to timer the load value
	
	MOV R8, #1		// Set Enable in the control register to 1 to start the timer
	STR R8, [R9, #0x8]

LOOP:	LDR R8, [R9, #0xC]	// Load in the F bit in the interupt status
	CMP R8, #1		// The timer is done counting when the F bit is 1, so continue if its not
	BNE LOOP		
	MOV R8, #1		// Reset the timer (F bit) by writing 1 to the F bit
	STR R8, [R9, #0xC]
	B EDGECAPTURE

DELAYCOUNT: .word 2000000 // 0.01 s
RESETCODE: .word   0b11111111 //reset the edgecapture register by writing 1 to it
BITCODE: .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111,  0b01100110, 0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111, 0b0000000
         .skip   2      // pad with 2 bytes to maintain word alignment
	 .end	
