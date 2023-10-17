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
	
	# struct bola
	#     short x -> coordenada x
	#     short y -> coordenada y
	#     byte dx -> direção x da bola
	#     byte dy -> direção y da bola
	#     byte r  -> raio da bola
	# Total: 7 bytes
	
	# Alocação:
	#     2 raquetes + 1 bola + variável byte
	addiu $sp, $sp, -24
	
	# Inicializa os dados das raquetes
	li $t1, 0x000f0064
	
	li $t0, 0x000a0000
	sw $t0, -4($fp)
	sw $t1, -8($fp)
	
	li $t0, 0x023f0000
	sw $t0, -12($fp)
	sw $t1, -16($fp)
	
	# Inicializa os dados da bola
	li $t0, 0x012c00f0
	sw $t0, -20($fp)
	li $t1, 0x0000000
	sh $t1, -22($fp)
	li $t1, 0x0a
	sb $t1, -23($fp)
	
	# Indica se o jogo iniciou
	#     0 não iniciou
	#     1 acabou de iniciar
	#     2 está rodando
	li $t0, 0x0
	sb $t0, -24($fp)
	
.gameloop:
	# Verifica se o jogo foi iniciado
	lb $t0, -24($fp)
	beq $t0, 0, .init
	
	# Inica o estado do jogo caso não iniciado
	bne $t0, 1, .update
	
	# Finaliza a inicialização do jogo
	li $t0, 2
	sb $t0, -24($fp)
	
.update:
	# Atualiza a posição da raquete do jogador
	protocol_geti (PROTOCOL_MOUSE_Y, $t0)
	
	# Verifica se a raquete está dentro do limite superior da tela
	addi $t0, $t0, -50                    # -50 = - metade do tamanho da raquete
	bgt $t0, 0, .dentro_cima
	# Caso a raquete está fora da tela faz ela ficar dentro
	li $t0, 0
	
.dentro_cima:
	# Verifica se a raquete está dentro do limite superior
	addi $t1, $t0, 100                    # 100 = altura da raquete
	blt $t1, 480, .dentro_tela            # 480 é a altura da tela
	
	# Caso a raquete está fora da tela faz ela ficar dentro
	li $t0, 380                           # largura da tela - largura da raquete
.dentro_tela:
	# Atualiza a posição da raquete
	sh $t0, -12($fp)
	
	protocol_emit (PROTOCOL_SET_COLOR, 0, 0, 0)
	protocol_emit (PROTOCOL_CLEAR_SCREEN)
	
	# Pula a verificação de tecla
	j .draw
	
.init:
	# Verifica se a tecla enter (13) foi pressionada para começar o jogo
	protocol_geti (PROTOCOL_KEY, $t0)
	bne $t0, 13, .draw
	
	# Caso apertou põe o jogo no próximo estado: inicializaçõa
	li $t0, 1
	sb $t0, -24($fp)
	
.draw:
	protocol_emit (PROTOCOL_SET_COLOR, 255, 255, 255)
	lwl $a0, -3($fp)
	lwr $a0, -2($fp)
	lwl $a1, -7($fp)
	lwr $a1, -6($fp)
	jal draw_racket
	
	lwl $a0, -11($fp)
	lwr $a0, -10($fp)
	lwl $a1, -15($fp)
	lwr $a1, -14($fp)
	jal draw_racket
	
	lwl $a0, -19($fp)
	lwr $a0, -18($fp)
	lb $a1, -23($fp)
	jal draw_ball
	
	j .gameloop
	
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

draw_ball:
	and $t0, $a0, 0xFFFF
	srl $t1, $a0, 16
	
	protocol_emit (PROTOCOL_DRAW_CIRCLE, $t0, $t1, $a1)
	jr $ra

# vim: ft=asm
