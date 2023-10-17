.include "syscalls.asm"
.include "macros.asm"
.include "protocol.asm"

.data

.text
main:
	# Aloca espaço na stack para guardar os registradores $fp e $ra
	addiu $sp, $sp, -8
	sw $fp, 4($sp)    # guarda o registrador $fp
	sw $ra, 0($sp)    # guarda o registrador $ra
	move $fp, $sp     # utiliza a stack átraves do registrador $fp e não $sp
	
	# Aloca espaço na stack para armazenar variáveis locais. Nesse caso usa o
	# $sp para fazer a alocação mas a utilizar esse espaço é pelo $fp

$gameloop:
	protocol_emit (PROTOCOL_SET_COLOR, 0, 0, 0)
	protocol_emit (PROTOCOL_CLEAR_SCREEN)
	j $gameloop

	# Libera o espaço alocado na stack para as variáveis locais.
	# Nota: isso funciona porque o $fp guarda o endereço da stack antes da
	# alocação então se mover esse valor para o $sp a memória é liberada.
	move $sp, $fp
	lw $ra, 0($fp)    # restaura o valor de $ra
	lw $fp, 4($fp)    # restaura o valor de $fp
	addiu $sp, $sp, 8 # libera o espaço alocado para o $fp e $ra

	# Fecha o pong
	exit (0)

# vim: ft=asm
