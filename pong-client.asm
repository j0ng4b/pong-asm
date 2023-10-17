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
	
	# Noções de structs em assembly:
	# Basicamente assembly so entende "bytes" então uma struct em assembly é
	# definida em termos de bytes para exemplificar considere:
	#
	# struct foo {
	#     int x;
	#     int y;
	# };
	#
	# É uma struct com dois ints ou seja 8 bytes (4 bytes para cada int) então
	# quando for alocado mémoria para essa struct será alocado 8 bytes, se for
	# necessário duas structs dessa então serão 16 bytes e assim por diante.
	#
	# Para referência de alocação:
	#   byte  1 byte
	#   short 2 bytes
	#   int   4 bytes
	#   long  8 bytes
	
	# struct raquete
	#     short x -> coordenada x
	#     short y -> coordenada y
	#     short w -> largura
	#     short h -> altura
	# Total: 8 bytes
	
	# Alocação:
	#     2 raquetes
	addiu $sp, $sp, -16
	
	# Inicializa os dados das raquetes
	li $t0, 15
	li $t1, 100
	
	li $at, 10
	sh $at, -2($fp)
	li $at, 0
	sh $at, -4($fp)
	sh $t0, -6($fp)
	sh $t1, -8($fp)
	
	li $at, 575
	sh $at, -10($fp)
	li $at, 0
	sh $at, -12($fp)
	sh $t0, -14($fp)
	sh $t1, -16($fp)
	
	protocol_emit (PROTOCOL_SET_COLOR, 0, 0, 0)
	protocol_emit (PROTOCOL_CLEAR_SCREEN)
$gameloop:
	
	protocol_emit (PROTOCOL_SET_COLOR, 255, 255, 255)
	lwl $a0, -3($fp)
	lwr $a0, -2($fp)
	lwl $a1, -7($fp)
	lwr $a1, -6($fp)
	jal draw_racket
	
	protocol_emit (PROTOCOL_SET_COLOR, 255, 255, 255)
	lwl $a0, -11($fp)
	lwr $a0, -10($fp)
	lwl $a1, -15($fp)
	lwr $a1, -14($fp)
	jal draw_racket
	
	#jal draw_racket
	
	j $gameloop
	
	protocol_emit (PROTOCOL_DONE)

	# Libera o espaço alocado na stack para as variáveis locais.
	# Nota: isso funciona porque o $fp guarda o endereço da stack antes da
	# alocação então se mover esse valor para o $sp a memória é liberada.
	move $sp, $fp
	lw $ra, 0($fp)    # restaura o valor de $ra
	lw $fp, 4($fp)    # restaura o valor de $fp
	addiu $sp, $sp, 8 # libera o espaço alocado para o $fp e $ra

	# Fecha o pong
	exit (0)

draw_racket:
    and $t0, $a0, 0xFFFF
    srl $t1, $a0, 16
    
    and $t2, $a1, 0xFFFF
	srl $t3, $a1, 16
    
	protocol_emit (PROTOCOL_DRAW_RECT, $t0, $t1, $t2, $t3)
	
	jr $ra

# vim: ft=asm
