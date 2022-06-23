TITLE String Primitives & Macros     (Proj6_claphand.asm)

; Author: David Claphan
; Last Modified: 06/05/2022
; OSU email address: claphand@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number: Project 6     Due Date: 06/05/2022
; Description: This program prompts the user for 10 integer values that fall within a specific range (fits inside a 32-bit register).
;              An error message is displayed if the user provides invalid input. After the integers are gathered, the
;			   program calculates the sum and average of the inputs. It then converts all the integers, their sum, and average,
;			   to strings and displayes them as output with header descriptions for each. 

INCLUDE Irvine32.inc

;----------------------------------------------------------------------------------------------
; Name: mGetString
;
; Prompts the user to enter a string, then reads the string that is entered. Uses ReadString procedure.
;
; Preconditions: Do not use ECX, EDX as arguments.
;
; Receives:
;	strAddr = string address, this string intended to be a prompt for the user
;
; Returns: 
;	strAddr = prints prompt as output
;	entered string is added to byte array 'num_string' 
;	string length moved to 'num_str_len' variable
;----------------------------------------------------------------------------------------------
mGetString	MACRO strAddr:REQ
	
	PUSH	ECX
	PUSH	EDX

	MOV		EDX, strAddr
	CALL	WriteString
	MOV		EDX, OFFSET	num_string
	MOV		ECX, 25
	CALL	ReadString
	MOV		num_str_len, EAX

	POP		EDX
	POP		ECX

ENDM


;----------------------------------------------------------------------------------------------
; Name: mDisplayString
;
; Displays a string that is passed as an argument.
;
; Preconditions: Do not use EDX as an argument. Passed argument will only print correctly if it's a string. (i.e. INT)
;		will not display correctly.	
;
; Receives:
;	str1 = string to be printed as output
;
; Returns:
;	str1 = prints string passed as argument
;----------------------------------------------------------------------------------------------
mDisplayString MACRO str1:REQ

	PUSH	EDX
	MOV		EDX, str1
	CALL	WriteString

	POP		EDX

ENDM

; ASCII Table values as constants
LO = 48
HI = 57
PLUS = 43
MINUS = 45
POSMAX = 2147483647    ; used in validation: max positive value
NEGMAX = 2147483648    ; used in validation: largest negative value

.data
introduction	BYTE	"CS271 Project 6: String Primitives & Macros",13,10
				BYTE	"By David Claphan",13,10,13,10
				BYTE	"Please provide 10 signed decimal integers.",13,10
				BYTE	"Each number needs to be small enough to fit inside a 32 bit register.",13,10
				BYTE	"If you're reading this and you're not sure what that means... use the range [-2,147,483,648:2,147,483,647]",13,10  
				BYTE	"After you have finished inputting the numbers, I will display the integers, their sum, and their average value.",13,10,13,10,0 
goodbye			BYTE	"Wow, look at all those numbers! That's all for CS271, thank you and goodbye!",13,10,0
prompt1			BYTE	"Please enter a signed number: ",0
error_msg		BYTE	"ERROR: You did not enter a signed number or your number was out of range!",13,10
				BYTE	"Please try again: ",0
summary_header	BYTE	"You entered the following numbers:",13,10,0
sum_sentence	BYTE	"The sum of these numbers is: ",0
avg_sentence	BYTE	"The truncated average is: ",0
num_string		BYTE	20 DUP(0)
num_str_len		SDWORD	?
count_loop		DWORD	10
val_array	    SDWORD	10 DUP(?)
current_total	SDWORD	0
array_sum		SDWORD	?
array_avg		SDWORD	?
write_sum		BYTE	20 DUP(?)
write_avg		BYTE	20 DUP(?)
write_array		BYTE	12 DUP(0)
write_loop		DWORD	1

.code
main PROC
; Header and Instructions for User
	mDisplayString  OFFSET introduction

; Ask user for, and validate input values via Loop
	MOV		EDI, OFFSET val_array  ; move INT array to EDI

_gatherNums:
	PUSH	OFFSET num_string      ; [EBP+20]
	PUSH	OFFSET prompt1	       ; [EBP+16]
	PUSH	OFFSET error_msg       ; [EBP+12]
	PUSH	current_total          ; [EBP+8]
	CALL	ReadVal
	MOV		[EDI], EAX             ; add validated value to val_array
	ADD		EDI, 4				   ; move to next position in val_array, then loop
	
	; LOOP code
	DEC		count_loop             ; loops until 10 valid numbers provided
	CMP		count_loop, 0
	JA		_gatherNums
	CALL	CrLf

; Calc Sum
	MOV		EDI, OFFSET val_array
	MOV		count_loop, 10
_sumCalc:	
	MOV		EAX, [EDI]
	ADD		array_sum, EAX		   ; move sum to variable for use later w/ WriteVal
	ADD		EDI, 4

	DEC		count_loop
	CMP		count_loop, 0
	JA		_sumCalc

; Calc avg (positive val)
	MOV		EDX, 0
	MOV		EAX, array_sum
	IMUL	EAX, 1
	JNS		_positiveSum		   ; if sum is positive, JMP past next code block

; If the sum of entered values is negative, this block of code converts the sum back to positive, to be averaged
;   then converts it back to a negative value to be used later. This code is skipped if the sum is positive.
	NEG		EAX				       ; convert back to positive
	MOV		EBX, 10	
	IDIV	EBX
	NEG		EAX					   ; convert avg to negative value
	MOV		array_avg, EAX		   ; move avg to variable for use later w/ WriteVal

	; Display Gathered List
	MOV		EDI, OFFSET val_array
	MOV		count_loop, 10
	mDisplayString OFFSET summary_header

	JMP		_writeLoop			   ; avg already calculated so skip to the code that displays INTs as strings

	; calculated the avg for the sum if values are positive, then moves on to begin displaying the provided INTs as strings
	_positiveSum:
	MOV		EBX, 10	
	IDIV	EBX
	MOV		array_avg, EAX

; Display Gathered List 
	MOV		EDI, OFFSET val_array		; initially empty and cleared after each element printed as string
	MOV		count_loop, 10
	mDisplayString OFFSET summary_header

; This loop will take each value, CALL WriteVal, convert to a string, then for elements 1-9 in the array
;    a comma and blank space are printed after each value. After all 10 elements are printed as output, the program
;    moves on to display sum and avg.
_writeLoop:
	PUSH	OFFSET write_array  ; EBP+12
	PUSH	[EDI]				; EBP+8
	CALL	WriteVal

	; Loop through elements in INT array (val_array)
	MOV		EDI, OFFSET val_array
	MOV		EAX, write_loop            ; write_loop used to help iterate through val_array
	MOV		EBX, 4					   ; initalized to 1 and helps increment EDI by 4's to properly move through array
	MUL		EBX
	ADD		EDI, EAX
	INC		write_loop
	DEC		count_loop
	CMP		count_loop, 0
	JA		_stillWriting
	JMP		_doneWriting

_stillWriting:
	MOV		AL, 44
	CALL	WriteChar				  ; print comma after element
	MOV		AL, 32
	CALL	WriteChar	              ; print space after comma
	JMP		_writeLoop

_doneWriting:
	CALL	CrLf
	CALL	CrLf

; Display Sum
	mDisplayString OFFSET sum_sentence
	PUSH	OFFSET write_sum
	PUSH	array_sum
	CALL	WriteVal
	CALL	CrLf

; Display Average
	mDisplayString OFFSET avg_sentence
	PUSH	OFFSET write_avg
	PUSH	array_avg
	CALL	WriteVal
	CALL	CrLf
	CALL	CrLf

; Goodbye
	mDisplayString OFFSET goodbye
	
	Invoke ExitProcess,0	; exit to operating system
main ENDP



;-----------------------------------------------------------------------------------------------------------------------------
; Name: ReadVal
;
; Uses the mGetString macro to get a string of digits, and then reads each digit (character) in the string to converts
;	the string to it's integer equivalent. For example, the string "1234" would be converted to an integer 1234. There are
;	validation checks to make sure what is entered can be converted to an integer equivalent, and that the input falls within
;	the specified range for the program. The integer values are stored in an array 'val_array'.
; 
; Preconditions: 
;	An empty array for storing integer values must be moved to EDI prior to procedure call.
;
; Postconditions:
;	EAX holds the Integer equivalent value after procedure is called.
; 
; Receives:
;	[EBP+20] The byte string used in mGetString MACRO (OFFSET)
;	[EBP+16] The standard prompt printed as instructions to user (OFFSET)
;	[EBP+12] A prompt to displayed if a non-numerical value is printed that is not a "+" or "-" to start the string entry (OFFSET)
;	[EBP+8] A variable initalized to 0 to use in the algorithm converting a string to the integer equivalent.
;	HI, LO, PLUS, and MINUS are global constants - ASCII codes for 9, 0, "+" and "-"
;	NEGMAX & POSMAX are global constants equal to the largest negative and positive numbers that fit in a 32-bit register
;
; Returns:
;	EAX = integer equivalent to string value from mGetString
;	mGetString prints valid input prompt as output 10 times + an error message for every invalid entry
;	Registers used: EAX/AL, EBX, ECX, EDX, EBP, ESP, ESI (all changed in procedure)
;------------------------------------------------------------------------------------------------------------------------------
ReadVal PROC
	PUSH	EBP
	MOV		EBP, ESP
	
	mGetString	[EBP+16]
	JMP	_validateNum

_validateNum:
	CLD
	MOV		ECX, EAX			; STRING LENGTH from MACRO
	MOV		ESI, [EBP+20]		; Digit String
	MOV		EBX, [EBP+8]		; current cummulative value for digits
	
	LODSB						; Puts byte in AL
	CMP		AL, MINUS           ; checks for minus sign
	JE		_negativeVal
	CMP		AL, PLUS			; checks for plus sign
	JE		_positiveVal
	JMP		_firstLoop

 _validLoop:
	LODSB						; loads next value

 _firstLoop:
	CMP		AL, LO				; checks for ASCII less than code equal to 0
	JL		_errorNum
	CMP		AL, HI				; checks for ASCII greater than code equal to 9
	JG		_errorNum

	SUB		AL, 48
	IMUL	EBX, 10
	JO		_errorNum			; Cummulative value multiplied by 10 before adding each digit to sum. If too large
	MOVZX	EDX, AL				;    for 32-bit reg, overflow flag will be SET and number is not valid. 
	ADD		EBX, EDX

	LOOP	_validLoop
	
	JMP		_validNum


; Displays an error message if input is invalid. Starts the validation process over without
;	existing procedure, this holds the value of the loop counter so it only decrements for valid entries.
  _errorNum:
	mGetString [EBP+12]
	JMP		_validateNum


; If the input has a minus sign as the first "digit" this block of code executes, ignoring the minus sign as a "string"
;     value and passes the value to a specific subprocedure to be negated later.
_negativeVal:
	DEC		ECX	

_negativeLoop:
	LODSB						; loads next value

	CMP		AL, LO				; checks for ASCII less than code equal to 0
	JL		_errorNum
	CMP		AL, HI				; checks for ASCII greater than code equal to 9
	JG		_errorNum

	SUB		AL, 48
	IMUL	EBX, 10
	JO		_errorNum           ; Cummulative value multiplied by 10 before adding each digit to sum. If too large
	MOVZX	EDX, AL				;    for 32-bit reg, overflow flag will be SET and number is not valid. 
	ADD		EBX, EDX

	LOOP	_negativeLoop
	JMP		_validNegativeNum

; If the input has a plus sign as the first "digit" this block of code executes, ignoring the plus sign as a "string"
;     value and passes the value to a specific subprocedure at the end.
_positiveVal:
	DEC		ECX

  _positiveLoop:
	LODSB						; loads next value

	CMP		AL, LO				; checks for ASCII less than code equal to 0
	JL		_errorNum
	CMP		AL, HI				; checks for ASCII greater than code equal to 9
	JG		_errorNum

	SUB		AL, 48
	IMUL	EBX, 10
	MOVZX	EDX, AL
	JO		_errorNum			; Cummulative value multiplied by 10 before adding each digit to sum. If too large
	ADD		EBX, EDX			;    for 32-bit reg, overflow flag will be SET and number is not valid. 

	LOOP	_positiveLoop

	JMP		_validNum

; Final validation steps for negative inputs.
_validNegativeNum:
	MOV		EAX, EBX
	CMP		EAX, NEGMAX         ; check that value in negative val range
	JA		_errorNum

	NEG		EAX
	JMP		_end

; Final validation steps for inputs with plus sign or NO sign.
  _validNum:
	MOV		EAX, EBX
	CMP		EAX, POSMAX		    ; check that value in positive val range
	JA		_errorNum

	JMP		_end

_end:
	POP		EBP
	RET		16

ReadVal ENDP

;-----------------------------------------------------------------------------------------------------------------------------
; Name: WriteVal
;
; Uses the mDisplayString macro to take a provided integer value and convert it to a string. There is a validation check 
;	for negative integer values that will print a minus sign ("-") before printing any numerical digits. After calling the
;	mDisplayString macro the proocedure clears the byte string it uses to print the string as output.
;	
; Preconditions: 
;	The array for storing string values before printing must be empty before it's pushed to the stack ahead of procedure call.
;
; Postconditions: None
; 
; Receives:
;	[EBP+12] An empty array that is used to store the string of the converted integer before it's printed. (OFFSET)
;	[EBP+8] An integer value that will be converted to a string to be printed. (e.g. single integer value, sum, average)
;
; Returns:
;	mDisplayString prints converted integers as string output
;	Registers used: EAX/AL, EBX, ECX, EDX, EBP, ESP, ESI, EDI (all changed in procedure)
;------------------------------------------------------------------------------------------------------------------------------
WriteVal PROC
	PUSH	EBP
	MOV		EBP, ESP

	MOV		ESI, [EBP+8]		; MOV first num to ESI
	MOV		ECX, 0
	MOV		EAX, ESI

	IMUL	EAX, 1				; Check if current value is negative. This line will set sign flag if negative.
	JNS		_readValLoop    
	
	PUSH	EAX
	MOV		AL, 45
	CALL	WriteChar			; Minus sign printed to output
	POP		EAX
	NEG		EAX					; Minus sign already added as output, remaining digits should be printed same as positive
								;    values so negate value and proceed through procedure.

; Reads integer values and pushes ASCII equivalents to stack
_readValLoop:
	MOV		EDX, 0
	MOV		EBX, 10				; divide current value by 10
	IDIV	EBX

	ADD		EDX, 48				; add 48 to get ASCII code
	PUSH	EDX					; push digit to stack 

	INC		ECX
	CMP		EAX, 0
	JNE		_readValLoop		; repeat above steps for all digits in value
	
	MOV		EDI, [EBP+12]

	MOV		EBX, 0

; Pops pushed ASCII values off stack and stores them in byte array to be displayed
_convertLoop:
	CLD 
	POP		EAX					; POP ASCII value off stack
	STOSB						; Store in byte array
	
	INC		EBX
	DEC		ECX
	CMP		ECX, 0
	JNE		_convertLoop		; repeat until all ASCII values off stack

	mDisplayString [EBP+12]     ; display byte array of ASCII values

	MOV		EDI, [EBP+12]

; After the byte array is displayed as output, it must be cleared so it can be used for the next INT
_clearArray:	
	MOV		EAX, 0
	STOSB						; Store 0 in place of all ASCII values from printed value

	DEC		EBX
	CMP		EBX, 0
	JNE		_clearArray			; Loop until all values cleared

	POP		EBP
	RET		8

WriteVal ENDP



END main
