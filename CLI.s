@ --------------------------------------------
@ ARM32 CLI
@ Group 56
@ E/22/421  -  W P T H Weerasinghe 
@ E/22/182  -  K P W D R Kariyawasam
@ --------------------------------------------

.data			@@ known strings and variables +++++++++++++++++++++++++++++++++++++++++++++++++++++
__data_start:


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

    uptime_cmd:  .asciz "performance"			@ command to trigger show_performance()
	uptime_msg:  .asciz "Uptime: %02d:%02d:%02d\n"		@to show uptime

	@ CPU time showing format
	cpu_msg: .asciz "CPU Time:\n\tApplication: %d.%06ds, \n\tSystem: %d.%06ds\n"

											@ idle time showing format()
	idle_time: .asciz "\nIdle Time: %02d:%02d:%02d\n"
	idle_precent: .asciz "Idle Precentage: %02d.%d \%\n\n"
	const_value:  .word 1000000				@ Store the constant value in memory

	@ memory usage showing format strings
	total_size_: .asciz "Total memory used: %d KB\n"
	segment_size_msg: .asciz "Segment sizes\n"
	text_size_:  .asciz "\t.text  : %d bytes\n"
	data_size_:  .asciz "\t.data  : %d bytes\n"
	bss_size_:   .asciz "\t.bss   : %d bytes\n"


@just for testing, clear up afterwards
	test_input: .asciz "You entered : %s\n"	

 __data_end:


.bss			@@ for memory allocations +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

__bss_start:
	buffer: .space 50					@to take user inputs
	start_time: .space 4				@ to store start time
	rusage_buf: .space 96				@ enough space for cpu info

__bss_end:



@@ All the codes and instructions ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
.text
__text_start:


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





show_performance:



	push {lr}

	@@ for UpTime
    bl get_time					@ get current time (r0 contains it)

    @ subtract start_time from current_time
    ldr r2, =start_time
    ldr r2, [r2]				@ loading stored start_time

    sub r0, r0, r2				@ r0 = uptime in seconds
	mov r9, r0					@ copied for future use

    @ convert r0 to hh:mm:ss
    bl time_format				@ result: r0=hh, r1=mm, r2=ss

    @ print uptime
    mov r3, r2					@ r2 = ss
    mov r2, r1					@ r1 = mm
    mov r1, r0					@ r0 = hh
	ldr r0, =uptime_msg
    bl printf					@ printing Uptime


	@@ CPU time for application
	ldr r0, =0					@ current process as an argument(0)
    ldr r1, =rusage_buf     
    mov r7, #77					@ syscall number for getrusage
    svc #0						@ software inturrupt

								@ Extracting values from rusage_buf
    ldr r5, =rusage_buf
    ldr r1, [r5]				@ CPU time for application
    ldr r2, [r5, #4]			@ decimal part (microsec)
    ldr r3, [r5, #8]			@ CPU time for sys calls
    ldr r4, [r5, #12]			@ decimal part (microsec)
	ldr r10, [r5, #16]			@ Total memory used
	ldr r0, =cpu_msg
    bl printf					@ printing CPU times



	@@ Idle time
	ldr r8, =const_value		@Load the address of the constant
	ldr r8, [r8] 


	mul r5, r1, r8				@ CPU time appl in microsec
	mul r6, r3, r8				@ CPU time sys in microsec

	add r5, r5, r2				
	add r6, r6, r4
	add r5, r5, r6				@ Total CPU time

	mul r6, r9, r8				@ UpTime in microsec

	sub r5, r6, r5				@ Idle time in microsec = UpTime - Total CPU time

	mov r0, r5
	mov r1, r8
	bl divider					@ idle time in seconds
	mov r4, r0					@ r4 <- Idle time in seconds
	bl time_format				@ Converting to correct format
	push {r0,r1,r2}				@ Storing idle time for easiness

	ldr r0, =idle_time	
	pop {r1,r2,r3}				@ Restoring idle time
    bl printf					@ Printing Idle time

	mov r2,#100					
	mov r1, r9					@ r1 <- uptime
	mul r0, r4, r2				@ r0 <- idle time *100

	bl divider					@ r0 = (idle time/uptime) *100
	mov r2, r1
	mov r1, r0
	ldr r0, =idle_precent		
	bl printf					@ printing idle precentage

	@@ Memory usage
	ldr r0, =total_size_
	mov r1, r10					@ previously stored total memory size
	bl printf
	bl section_size

    pop {pc}


section_size:
    push {lr}

	@ the size of each segment in the program
	ldr r0, =segment_size_msg
	bl printf

    @ for .text section
    ldr r0, =__text_end
    ldr r1, =__text_start
    sub r1, r0, r1             @ r1 = .text section size
    ldr r0, =text_size_
    bl printf

    @ for .data section 
    ldr r0, =__data_end
    ldr r1, =__data_start
    sub r1, r0, r1             @ r1 = .data section size
    ldr r0, =data_size_
    bl printf

    @ for .bss section
    ldr r0, =__bss_end
    ldr r1, =__bss_start
    sub r1, r0, r1             @ r2 = bss size
    ldr r0, =bss_size_
    bl printf


    pop {pc}


get_time:

@ ------------------------------------------
@ Function: get_time
@ Return value: r0 <- current time in Unix Timestamp
@ Description: Do a system call, returns current time
@ System call time() invoking and software intuurupt happens
@ ------------------------------------------

	@ Get current time
    mov r0, #0            @ NULL argument to time()
    mov r7, #13           @ syscall for time() in Linux
    svc #0				  @ software inturrupt and invoke kernel
	bx lr				  @ return with r0



time_format:

@ -----------------------------------------------------
@ Function: time_format
@ input:  r0 = total seconds
@ output: r0 = hours, r1 = minutes, r2 = seconds
@ Description: Convert given time of seconds to hours, minutes, seconds
@ ------------------------------------------------------

	push {lr}
    mov r1, #3600
	bl divider				@ total hours
	mov r3, r0				@ r3 = hours = answer
	mov r0, r1				@ r0 remaining seconds

	mov r1, #60
	bl divider				@ total minutes

	mov r2, r1				@ r2 = ss
	mov r1, r0				@ r1 = min
	mov r0, r3				@ r0 = hh

    pop {pc}


divider:

@ ------------------------------------------
@ Function: divider
@ input:  r0 = dividend, r1 = divisor
@ output: r0 = answer, r1 = remainder
@ Description: divide number in ro by r1
@ Return the quotient and remainder
@ ------------------------------------------


	push {r2,lr}		@ save the previous value

	mov r2,#0			@ 
	while_loop:
		cmp r0, r1
		blt return_divider

		sub r0, r1
		add r2, r2, #1
		b while_loop


	return_divider:
	mov r1, r0				@ r1 = remainder
	mov r0, r2				@ r0 = answer
	pop {r2,pc}



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
    
    @ Check if it''s a digit
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
__text_end: