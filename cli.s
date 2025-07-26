@ --------------------------------------------
@ ARM32 CLI
@ Group 56
@ E/22/421  -  W P T H Weerasinghe 
@ E/22/182  -  K P W D R Kariyawasam
@ --------------------------------------------

.data			@@ known strings and variables +++++++++++++++++++++++++++++++++++++++++++++++++++++

	cli_prompt:		.asciz "ARM32_cli> "
	input_format:   .asciz "%49[^\n]"		@ read upto 49 char or '\n' is met

@ to clear up the buffers

	flush_buffer: .asciz "%*[^\n]"			@ read and discard until '\n' is met
	flush_newline: .asciz "%*c"				@ to read and discard a single char ('\n')

	hello_cmd: .asciz "hello"				@ command to trigger hello()
	hello_msg: .asciz "Hello World!\n"		@ hello message to print

	exit_cmd: .asciz "exit"					@ command to trigger exit
	exit_msg: .asciz "Exiting the Shell\n"	@ Exiting message

	help_cmd: .asciz "help"
    help_msg: .asciz "Available commands:\n - hello\n - exit\n - help\n - clear\n - encrypt <shift> <text>\n"

    clear_cmd: .asciz "clear"
    clear_seq: .asciz "\033[2J\033[H"     @ ANSI escape to clear terminal

	encrypt_cmd:        .asciz "encrypt"
	encrypt_input:      .space 128           @ Full command input
	encrypt_shift_buf:  .space 16            @ Buffer for shift string
	encrypt_text_buf:   .space 128           @ Buffer for text to encrypt
	encrypt_out_buf:    .space 128           @ Buffer for result
	encrypt_format:     .asciz "%d %s"
	encrypt_format_full: .asciz "encrypt %d %s"
	encrypt_usage:      .asciz "Usage: encrypt <shift> <text>\n"

@just for testing, clear up afterwards
	test_input: .asciz "You entered : %s\n"	




.bss			@@ for memory allocations +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	buffer: .space 50					@to take user inputs





@@ All the codes and instructions ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
.text

.global main

@@@@@@@@@@@@@@@@@@@@ write all the functions here

flush_input_buffer:

@ ----------------------------------------
@ Function: flush_input_buffer
@ Description: Clears any leftover characters from the input buffer.
@ This includes characters beyond expected limit and the final newline.
@ This also handles the empty line just 'Enter' intances
@ ----------------------------------------

	@ Store the returning address in Stack
	push {lr}

	@ clear up the additional input buffer clutter (if there is..)
	ldr r0, =flush_buffer
	bl scanf

	@ clear final '\n' from the input buffer
	ldr r0, =flush_newline
	bl scanf

	@ Return by loading the stored lr to pc
	pop {pc}



clear_string_buffer:

@ ----------------------------------------
@ Function: clear_string_buffer
@ Description: Reset whats already in memory as the string input
@ Changes the first char of buffer to 0, therefore considered empty
@ To handle empty 'Enter' after a valid command
@ Otherwise previous command will be executed since no buffer change
@ ----------------------------------------
	
	push {lr}

	ldr r0, =buffer
    mov r1, #0
    strb r1, [r0]     @ buffer[0] = 0
	@ buffer is reset

	pop {pc}


hello:

@ ----------------------------------------
@ Function: hello
@ Cli command: hello  (hello_cmd)
@ Description: Prints "Hello World!"
@ ----------------------------------------

	@ Store the returning address in Stack
	push {lr}

	@ loading the hello msg to the r0
	ldr r0, =hello_msg
	bl printf

	@ Return by loading the stored lr to pc
	pop {pc}



exit_:

@ ----------------------------------------
@ Function: exit
@ Cli command: exit  (exit_cmd)
@ Description: Exits from the program
@ ----------------------------------------
	ldr r0, =exit_msg
	bl printf

	mov r0, #0      @ exit code = 0 (success)
    mov r7, #1      @ sys_exit and software inturrupt
    svc #0     
	

help:

@ ----------------------------------------
@ Function: help
@ Cli command: help
@ Description: Lists available commands
@ ----------------------------------------
    push {lr}
    ldr r0, =help_msg
    bl printf
    pop {pc}


clear:

@ ----------------------------------------
@ Function: clear
@ Cli command: clear
@ Description: Clears the screen using ANSI escape sequences
@ ----------------------------------------
    push {lr}
    ldr r0, =clear_seq
    bl printf
    pop {pc}



encrypt:
@ ----------------------------------------
@ Function: encrypt
@ CLI command: encrypt <shift> <string>
@ Description: Encrypts a given word by shifting it by a constant (Caesar cipher)
@ ----------------------------------------
    push {r4-r10, lr}

    @ Start parsing after "encrypt "
    ldr r4, =buffer
    add r4, r4, #8          @ Skip "encrypt " (7 chars + 1 space)

    @ Parse shift value manually
    mov r5, #0              @ Initialize shift value
    mov r8, #1              @ Sign multiplier (1 for positive, -1 for negative)

    @ Check for negative sign
    ldrb r0, [r4]
    cmp r0, #'-'
    bne parse_shift_digits
    mov r8, #-1             @ Set negative
    add r4, r4, #1          @ Skip the '-'

parse_shift_digits:
    ldrb r0, [r4]
    cmp r0, #' '            @ Check for space (end of number)
    beq shift_parsed
    cmp r0, #0              @ Check for null terminator
    beq encrypt_error
    
    @ Check if it's a digit
    cmp r0, #'0'
    blt encrypt_error
    cmp r0, #'9'
    bgt encrypt_error
    
    @ Convert digit and add to shift value
    sub r0, r0, #'0'        @ Convert ASCII to number
    mov r1, #10
    mul r2, r5, r1          @ r2 = shift * 10 (using different registers)
    mov r5, r2              @ shift = r2
    add r5, r5, r0          @ shift += digit
    
    add r4, r4, #1          @ Move to next character
    b parse_shift_digits

shift_parsed:
    mul r6, r5, r8          @ Apply sign to get final shift value (r6 = r5 * r8)

    @ Skip spaces before text
skip_spaces_before_text:
    ldrb r0, [r4]
    cmp r0, #' '
    bne text_found
    add r4, r4, #1
    b skip_spaces_before_text

text_found:
    @ Check if we have text
    ldrb r0, [r4]
    cmp r0, #0
    beq encrypt_error

    @ Copy text to encrypt_text_buf
    ldr r1, =encrypt_text_buf
copy_text:
    ldrb r0, [r4]
    cmp r0, #0
    beq text_copied
    strb r0, [r1]
    add r4, r4, #1
    add r1, r1, #1
    b copy_text

text_copied:
    mov r0, #0
    strb r0, [r1]           @ Null terminate

    @ Process the text
    ldr r1, =encrypt_text_buf
    ldr r7, =encrypt_out_buf

encrypt_loop:
    ldrb r2, [r1]           @ Load current character
    cmp r2, #0              @ Check for null terminator
    beq encrypt_done

    mov r3, r2              @ Copy character to r3

    @ Check if lowercase letter
    cmp r3, #'a'
    blt check_upper
    cmp r3, #'z'
    bgt check_upper

    @ Process lowercase letter
    sub r3, r3, #'a'        @ Convert to 0-25
    add r3, r3, r6          @ Add shift
    @ Handle negative shifts
    cmp r3, #0
    bge positive_lower
    add r3, r3, #26         @ Add 26 if negative
positive_lower:
    mov r4, #26
    udiv r5, r3, r4         @ r5 = r3 / 26
    mls r3, r5, r4, r3      @ r3 = r3 % 26
    add r3, r3, #'a'        @ Convert back to ASCII
    b store_char

check_upper:
    @ Check if uppercase letter
    cmp r2, #'A'
    blt store_char          @ Not a letter, keep as is
    cmp r2, #'Z'
    bgt store_char          @ Not a letter, keep as is

    @ Process uppercase letter
    sub r3, r3, #'A'        @ Convert to 0-25
    add r3, r3, r6          @ Add shift
    @ Handle negative shifts
    cmp r3, #0
    bge positive_upper
    add r3, r3, #26         @ Add 26 if negative
positive_upper:
    mov r4, #26
    udiv r5, r3, r4         @ r5 = r3 / 26
    mls r3, r5, r4, r3      @ r3 = r3 % 26
    add r3, r3, #'A'        @ Convert back to ASCII

store_char:
    strb r3, [r7]           @ Store encrypted character
    add r1, r1, #1          @ Move to next input character
    add r7, r7, #1          @ Move to next output position
    b encrypt_loop

encrypt_done:
    mov r3, #0              @ Null terminator
    strb r3, [r7]           @ Terminate string

    @ Print the encrypted result
    ldr r0, =encrypt_out_buf
    bl puts

    pop {r4-r10, pc}

encrypt_error:
    @ Print usage message if wrong arguments
    ldr r0, =encrypt_usage
    bl printf
    pop {r4-r10, pc}


main:

@ -------------------------------------------
@ Main Program
@ Description: The CLI input taking loop goes here
@ The input taken from the user is stored in variable 'buffer'
@ ------------------------------------------

shell_loop:
    ldr r0, =cli_prompt
    bl printf

    ldr r0, =input_format
    ldr r1, =buffer
    bl scanf

    bl flush_input_buffer

    @ Check for hello command
    ldr r0, =buffer
    ldr r1, =hello_cmd
    bl strcmp
    cmp r0, #0
    beq call_hello

    @ Check for exit command
    ldr r0, =buffer
    ldr r1, =exit_cmd
    bl strcmp
    cmp r0, #0
    beq call_exit

    @ Check for help command
    ldr r0, =buffer
    ldr r1, =help_cmd
    bl strcmp
    cmp r0, #0
    beq call_help

    @ Check for clear command
    ldr r0, =buffer
    ldr r1, =clear_cmd
    bl strcmp
    cmp r0, #0
    beq call_clear

    @ Check for encrypt command (using strncmp for partial match)
    ldr r0, =buffer
    ldr r1, =encrypt_cmd
    mov r2, #7              @ Length of "encrypt"
    bl strncmp
    cmp r0, #0
    beq call_encrypt

    b skip_command          @ If no command matched, skip to loop

call_hello:
    bl hello
    b skip_command

call_exit:


    bl exit_                @ This function calls svc #0 to terminate

call_help:
    bl help
    b skip_command

call_clear:
    bl clear
    b skip_command

call_encrypt:
    bl encrypt
    b skip_command

skip_command:
    bl clear_string_buffer
    b shell_loop

exit: