@ ARM32 CLI

.data @ known strings and variables

cli_prompt:	.asciz "ARM32_cli> "
input_format:   .asciz "%s"


.bss		@ for the input buffer

buffer: .space 200



@ All the codes
.text

@ write all the functions here


.global main

@main loop
main:

shell_loop:

	@ printing the prompt
	ldr r0, =cli_prompt
	bl printf

	@ taking inputs
	ldr r0, =input_format
	ldr r1, =buffer
	bl scanf

	@ repeating
	b shell_loop

exit:

