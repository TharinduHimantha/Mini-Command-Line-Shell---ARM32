@ --------------------------------------------
@ Assembly Project
@ Group 56
@ E/22/421  -  W P T H Weerasinghe 
@ E/22/182  -  K P W D R Kariyawasam
@ --------------------------------------------

.data			@@ known strings and variables +++++++++++++++++++++++++++++++++++++++++++++++++++++

	cli_prompt:		.asciz "shell56>> "		    @ Command prompt string
	input_format:   .asciz "%49[^\n]"			@ Read up to 49 char or until '\n'

@ to clear up the buffers
	flush_buffer: .asciz "%*[^\n]"				@ Read and discard until '\n'
	flush_newline: .asciz "%*c"					@ Read and discard a single char

	hello_cmd: .asciz "hello"					@ Command string to trigger hello()
	hello_msg: .asciz "Hello World!\n"			@ Hello message to print

	exit_cmd: .asciz "exit"						@ Command string to trigger exit
	exit_msg: .asciz "Exiting the Shell\n"		@ Exit message

	help_cmd: .asciz "help"						@ Command string for help
    help_msg: .asciz "Available commands:\n - hello\n - exit\n - help\n - clear\n - encrypt <shift> <text>\n"

    clear_cmd: .asciz "clear"					@ Command string for clear
    clear_seq: .asciz "\033[2J\033[H"			@ ANSI escape to clear terminal

	encrypt_cmd:        .asciz "encrypt"		@ Command string for encryption
	encrypt_input:      .space 128				@ Buffer for full command input
	encrypt_shift_buf:  .space 16				@ Buffer for shift value string
	encrypt_text_buf:   .space 128				@ Buffer for text to encrypt
	encrypt_out_buf:    .space 128				@ Buffer for encrypted result
	encrypt_format:     .asciz "%d %s"			@ Format for parsing shift and text
	encrypt_format_full: .asciz "encrypt %d %s"	@ Format including command name
	encrypt_usage:      .asciz "Usage: encrypt <shift> <text>\n"	@ Usage error message

.bss			@@ for memory allocations +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	buffer: .space 50							@ Buffer to store user input

.text

.global main

flush_input_buffer:
	push {lr}									@ Save return address
	ldr r0, =flush_buffer						@ Load flush format string
	bl scanf									@ Clear extra input buffer
	ldr r0, =flush_newline						@ Load newline flush format
	bl scanf									@ Clear final '\n'
	pop {pc}									@ Return to caller

clear_string_buffer:
	push {lr}									@ Save return address
	ldr r0, =buffer								@ Load buffer address
    mov r1, #0									@ Load zero value
    strb r1, [r0]								@ Set buffer[0] = 0 (empty string)
	pop {pc}									@ Return to caller

hello:
	push {lr}									@ Save return address
	ldr r0, =hello_msg							@ Load hello message
	bl printf									@ Print hello message
	pop {pc}									@ Return to caller

exit_:
	ldr r0, =exit_msg							@ Load exit message
	bl printf									@ Print exit message
	mov r0, #0									@ Set exit code = 0
    mov r7, #1									@ Set syscall number for sys_exit
    svc #0										@ Make system call to exit

help:
    push {lr}									@ Save return address
    ldr r0, =help_msg							@ Load help message
    bl printf									@ Print help message
    pop {pc}									@ Return to caller

clear:
    push {lr}									@ Save return address
    ldr r0, =clear_seq							@ Load ANSI clear sequence
    bl printf									@ Send clear sequence to terminal
    pop {pc}									@ Return to caller

encrypt:
    push {r4-r10, lr}							@ Save registers and return address
    ldr r4, =buffer								@ Load buffer address
    add r4, r4, #8								@ Skip past "encrypt " (8 chars)
    mov r5, #0									@ Initialize shift value accumulator
    mov r8, #1									@ Initialize sign multiplier (positive)

    ldrb r0, [r4]								@ Load first character of shift
    cmp r0, #'-'								@ Check if negative sign
    bne parse_shift_digits						@ If not negative, parse digits
    mov r8, #-1									@ Set sign multiplier to negative
    add r4, r4, #1								@ Skip past the '-' sign

parse_shift_digits:
    ldrb r0, [r4]								@ Load current character
    cmp r0, #' '								@ Check for space (end of number)
    beq shift_parsed							@ If space, done parsing number
    cmp r0, #0									@ Check for null terminator
    beq encrypt_error							@ If null, missing arguments
    
    cmp r0, #'0'								@ Check if less than '0'
    blt encrypt_error							@ If not digit, error
    cmp r0, #'9'								@ Check if greater than '9'
    bgt encrypt_error							@ If not digit, error
    
    sub r0, r0, #'0'							@ Convert ASCII digit to number
    mov r1, #10									@ Load decimal multiplier
    mul r2, r5, r1								@ Multiply current value by 10
    mov r5, r2									@ Store shifted value
    add r5, r5, r0								@ Add new digit
    
    add r4, r4, #1								@ Move to next character
    b parse_shift_digits						@ Continue parsing

shift_parsed:
    mul r6, r5, r8								@ Apply sign to get final shift

skip_spaces_before_text:
    ldrb r0, [r4]								@ Load current character
    cmp r0, #' '								@ Check if space
    bne text_found								@ If not space, found text
    add r4, r4, #1								@ Skip space
    b skip_spaces_before_text					@ Check next character

text_found:
    ldrb r0, [r4]								@ Load first text character
    cmp r0, #0									@ Check if null terminator
    beq encrypt_error							@ If no text, show error

    ldr r1, =encrypt_text_buf					@ Load text buffer address
copy_text:
    ldrb r0, [r4]								@ Load character from input
    cmp r0, #0									@ Check for end of string
    beq text_copied								@ If null, done copying
    strb r0, [r1]								@ Store char in text buffer
    add r4, r4, #1								@ Move input pointer
    add r1, r1, #1								@ Move buffer pointer
    b copy_text									@ Continue copying

text_copied:
    mov r0, #0									@ Load null terminator
    strb r0, [r1]								@ Null-terminate copied text

    ldr r1, =encrypt_text_buf					@ Load source text address
    ldr r7, =encrypt_out_buf					@ Load output buffer address

encrypt_loop:
    ldrb r2, [r1]								@ Load current character
    cmp r2, #0									@ Check for null terminator
    beq encrypt_done							@ If null, encryption complete

    mov r3, r2									@ Copy character for processing

    cmp r3, #'a'								@ Check if >= 'a'
    blt check_upper								@ If not, check uppercase
    cmp r3, #'z'								@ Check if <= 'z'
    bgt check_upper								@ If not, check uppercase

    sub r3, r3, #'a'							@ Convert to 0-25 range
    add r3, r3, r6								@ Add shift value
    cmp r3, #0									@ Check if negative
    bge positive_lower							@ If positive, handle normally
    add r3, r3, #26								@ Add 26 if negative (wrap)
positive_lower:
    mov r4, #26									@ Load modulo divisor
    udiv r5, r3, r4								@ Calculate quotient
    mls r3, r5, r4, r3							@ Calculate remainder (modulo)
    add r3, r3, #'a'							@ Convert back to lowercase ASCII
    b store_char								@ Store encrypted character

check_upper:
    cmp r2, #'A'								@ Check if >= 'A'
    blt store_char								@ If not letter, keep unchanged
    cmp r2, #'Z'								@ Check if <= 'Z'
    bgt store_char								@ If not letter, keep unchanged

    sub r3, r3, #'A'							@ Convert to 0-25 range
    add r3, r3, r6								@ Add shift value
    cmp r3, #0									@ Check if negative
    bge positive_upper							@ If positive, handle normally
    add r3, r3, #26								@ Add 26 if negative (wrap)
positive_upper:
    mov r4, #26									@ Load modulo divisor
    udiv r5, r3, r4								@ Calculate quotient
    mls r3, r5, r4, r3							@ Calculate remainder (modulo)
    add r3, r3, #'A'							@ Convert back to uppercase ASCII

store_char:
    strb r3, [r7]								@ Store character in output
    add r1, r1, #1								@ Move to next input character
    add r7, r7, #1								@ Move to next output position
    b encrypt_loop								@ Continue with next character

encrypt_done:
    mov r3, #0									@ Load null terminator
    strb r3, [r7]								@ Null-terminate output string
    ldr r0, =encrypt_out_buf					@ Load encrypted text address
    bl puts										@ Print encrypted result
    pop {r4-r10, pc}							@ Restore registers and return

encrypt_error:
    ldr r0, =encrypt_usage						@ Load usage message
    bl printf									@ Print usage instructions
    pop {r4-r10, pc}							@ Restore registers and return

main:

shell_loop:
    ldr r0, =cli_prompt							@ Load prompt string
    bl printf									@ Display prompt

    ldr r0, =input_format						@ Load input format string
    ldr r1, =buffer								@ Load buffer address
    bl scanf									@ Read user input

    bl flush_input_buffer						@ Clean input buffer

    ldr r0, =buffer								@ Load user input
    ldr r1, =hello_cmd							@ Load "hello" command
    bl strcmp									@ Compare strings
    cmp r0, #0									@ Check if equal
    beq call_hello								@ If equal, call hello

    ldr r0, =buffer								@ Load user input
    ldr r1, =exit_cmd							@ Load "exit" command
    bl strcmp									@ Compare strings
    cmp r0, #0									@ Check if equal
    beq call_exit								@ If equal, call exit

	ldr r0, =buffer								@ Load user input
    ldr r1, =help_cmd							@ Load "help" command
    bl strcmp									@ Compare strings
    cmp r0, #0									@ Check if equal
    beq call_help								@ If equal, call help

    ldr r0, =buffer								@ Load user input
    ldr r1, =clear_cmd							@ Load "clear" command
    bl strcmp									@ Compare strings
    cmp r0, #0									@ Check if equal
    beq call_clear								@ If equal, call clear

    ldr r0, =buffer								@ Load user input
    ldr r1, =encrypt_cmd						@ Load "encrypt" command
    mov r2, #7									@ Set comparison length
    bl strncmp									@ Compare first 7 characters
    cmp r0, #0									@ Check if equal
    beq call_encrypt							@ If equal, call encrypt

    b skip_command								@ No command matched, skip

call_hello:
    bl hello									@ Call hello function
    b skip_command								@ Jump to loop continuation

call_exit:
    bl exit_									@ Call exit function (terminates)

call_help:
    bl help										@ Call help function
    b skip_command								@ Jump to loop continuation

call_clear:
    bl clear									@ Call clear function
    b skip_command								@ Jump to loop continuation

call_encrypt:
    bl encrypt									@ Call encrypt function
    b skip_command								@ Jump to loop continuation

skip_command:
    bl clear_string_buffer						@ Clear buffer for next input
    b shell_loop								@ Return to main loop

exit: