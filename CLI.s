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

	b shell_loop					@ repeating

exit:

