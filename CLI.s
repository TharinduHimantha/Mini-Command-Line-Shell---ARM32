@ --------------------------------------------
@ ARM32 CLI
@ Group 56
@ E/22/421  -  W P T H Weerasinghe 
@ E/22/182  -  Dinith Kariyawasam
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
	

main:

@ -------------------------------------------
@ Main Program
@ Description: The CLI input taking loop goes here
@ The input taken from the user is stored in variable 'buffer'
@ ------------------------------------------

shell_loop:

	ldr r0, =cli_prompt				@ printing the prompt
	bl printf


	ldr r0, =input_format			@ taking inputs
	ldr r1, =buffer
	bl scanf

	bl flush_input_buffer			@ clearing the input buffer



	@ Uncooment and test whether is input taken properly
	@ ldr r0, =test_input
	@ ldr r1, =buffer
	@ bl printf

	bl clear_string_buffer			@ clear input string in memory
	b shell_loop					@ repeating

exit:
	

