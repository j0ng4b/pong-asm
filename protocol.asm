# Cabeçalho e rodapé do protocolo

# Comandos
.eqv PROTOCOL_SET_COLOR    "setcolor$"
.eqv PROTOCOL_CLEAR_SCREEN "clear$"

.macro __emit_arg (%arg)
	.text
	li $v0, SYSCALL_PRINT_INT
	add $a0, $zero, %arg
	syscall
	
	li $v0, SYSCALL_PRINT_CHAR
	li $a0, 0x3B
	syscall
.end_macro

.macro protocol_emit (%cmd)
	.data 
protocol_cmd_lb: .asciiz %cmd

	.text
	li $v0, SYSCALL_PRINT_STRING
	la $a0, protocol_cmd_lb
	syscall
.end_macro

.macro protocol_emit (%cmd, %arg1, %arg2, %arg3)
	.text
	protocol_emit (%cmd)
	
	__emit_arg (%arg1)
	__emit_arg (%arg2)
	__emit_arg (%arg3)
	
	li $v0, SYSCALL_PRINT_CHAR
	li $a0, 0x24
	syscall
.end_macro

# vim: ft=asm
