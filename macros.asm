.macro exit (%exit_code)
	.text
	li $v0, SYSCALL_EXIT
	add $a0, $zero, %exit_code
	syscall
.end_macro

# vim: ft=asm