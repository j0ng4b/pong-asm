.macro exit (%exit_code)
	.text
	li $v0, SYSCALL_EXIT
	add $a0, $zero, %exit_code
	syscall
.end_macro

.macro randint (%end)
	randint (0, %end)
.end_macro

.macro randint (%id, %end)
	li $v0, SYSCALL_RND_RANGE
	li $a0, %id
	
	li $a1, %end
	syscall
	
	move $v0, $a0
.end_macro

# vim: ft=asm
