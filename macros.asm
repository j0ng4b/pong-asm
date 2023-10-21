# Macro para terminar a execução do programa
.macro exit (%exit_code)
	.text
	li $v0, SYSCALL_EXIT
	add $a0, $zero, %exit_code
	syscall
.end_macro

# Gera um número entre 0 <= num < %end
.macro randint (%start, %end, %out)
	li $v0, SYSCALL_RND_RANGE
	li $a0, 0                # id, para saber o que é veja a syscall 42
	
	add $a1, $zero, %end     # move o valor de %end para $a1
	addi $a1, $a1, 1         # adiciona 1 para poder gerar [%start, %end] e não [%start, %end[
	sub $a1, $a1, %start
	syscall
	
	add %out, $a0, %start
.end_macro

# vim: ft=asm
