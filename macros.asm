# Macro para terminar a execução do programa
.macro exit (%exit_code)
	.text
	li $v0, SYSCALL_EXIT
	add $a0, $zero, %exit_code
	syscall
.end_macro

# Gera um número entre 0 <= num < %end
.macro randint (%end)
	randint (0, %end)
.end_macro

# Mesmo que o de cima, mas para saber a real diferença consulte a documentação
# da syscall 42
.macro randint (%id, %end)
	li $v0, SYSCALL_RND_RANGE
	li $a0, %id
	
	li $a1, %end
	syscall
	
	move $v0, $a0
.end_macro

# vim: ft=asm
