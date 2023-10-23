.include "syscalls.asm"
.include "macros.asm"
.include "protocol.asm"

.eqv SCREEN_WIDTH 600
.eqv SCREEN_HEIGHT 480

.text
main:
	# Aloca espaço na stack para guardar os registradores $fp e $ra
	addiu $sp, $sp, -8
	sw $fp, 4($sp)    # guarda o registrador $fp
	sw $ra, 0($sp)    # guarda o registrador $ra
	move $fp, $sp     # utiliza a stack através do registrador $fp e não $sp
	
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
	# quando for alocado memória para essa struct será alocado 8 bytes, se for
	# necessário duas structs dessa então serão 16 bytes e assim por diante.
	#
	# Para referência de alocação:
	#   byte   1 byte
	#   short  2 bytes
	#   int    4 bytes
	#   long   8 bytes
	#
	#   float  4 bytes
	#   double 8 bytes
	
	# struct raquete
	#     short x -> coordenada x
	#     short y -> coordenada y
	#     short w -> largura
	#     short h -> altura
	# Total: 8 bytes
	
	# struct bola
	#     float x -> coordenada x
	#     float y -> coordenada y
	#     byte r  -> raio da bola
	#     byte d  -> direção da bola
	#     short s -> velocidade da bola
	# Total: 12 bytes
	
	# Observações sobre alocação: não é só simplesmente por um valor aleatório,
	# por diversos pontos: a pilha não é infinita, o processador trabalha com
	# palavras de 4 bytes, logo você não pode só alocar uma quantidade sem pensar
	# em alinhamento de memória, por exemplo:
	#
	#     addiu $sp, $sp, -3
	#     sh $t0, 0($sp)
	#
	# O sh falha pois não é possível guardar $t0 em um lugar que não é alinhado
	# para meia palavra (2 bytes) no caso visualmente é isso que acontece:
	#               sp
	#               v
	#   | 0 1 2 3 | 4 5 6 7 | <- endereços
	#
	# Com sp - 3 fica:
	#       sp
	#       v
	#   | 0 1 2 3 | 4 5 6 7 | <- endereços
	#
	# Como pode perceber o endereço 1 não está alinhado, está no final de uma
	# meia palavra, dado essa explicação aconselho que quando for alocar algo,
	# sempre prefira múltiplos de 4.
	#
	# No exemplo acima, era resolvido alocado 4 bytes e não 3, o quarto byte é
	# chamado de padding (preenchimento) é usado apenas para manter a memória
	# alinhada, é uma prática comum ter preenchimento quando necessário.
	
	# Alocação:
	#     2 raquetes + 1 bola + variável byte + preenchimento 3 bytes
	#
	addiu $sp, $sp, -36
	
	# Variáveis:
	#    s0 -> primeira raquete
	#    s1 -> segunda raquete
	#    s2 -> bola
	#    s3 -> inicialização de jogo
	#    s4 -> delta time
	addi $s0, $fp, -8
	addi $s1, $fp, -16
	addi $s2, $fp, -28
	addi $s3, $fp, -32
	addi $s4, $fp, -36
	
	# Inicializa os dados das raquetes
	li $t0, 0x0064000f         # Largura e altura da raquete: 15x100
	
	li $t1, 0x00be000a         # Coordenadas (x,y) da raquete: 15,190
	sw $t1, 0($s0)
	sw $t0, 4($s0)
	
	li $t1, 0x00be023f         # Coordenadas (x,y) da raquete: 575,190
	sw $t1, 0($s1)
	sw $t0, 4($s1)
	
	# Inicializa os dados da bola
	li $t0, 0x43960000         # Coordenadas x da bola: 300.0
	sw $t0, 0($s2)
	
	li $t0, 0x43700000         # Coordenadas y da bola: 240.0
	sw $t0, 4($s2)
	
	li $t0, 0x03e8000a           # Tamanho, direção e velocidade da bola
	sw $t0, 8($s2)
	
	# Indica se o jogo iniciou
	#     0 não iniciou
	#     1 acabou de iniciar
	#     2 está rodando
	li $t0, 0x0
	sb $t0, 0($s3)
	
.gameloop:
	# Verifica se o jogo foi iniciado
	lb $t0, 0($s3)
	beq $t0, 0, .init
	
	# Inicia o estado do jogo caso não iniciado
	bne $t0, 1, .update
	
	# Finaliza a inicialização do jogo
	li $t0, 2
	sb $t0, 0($s3)
	
.update:
	# Obtém o delta time através do protocolo
	protocol_getf(PROTOCOL_DELTA_TIME, $f0)
	s.s $f0, 0($s4)
	
	# Atualiza a posição da bola, passa um ponteiro para a função move_ball,
	# ponteiros são endereços de memória é o que está sendo passa para a
	# função.
	move $a0, $s2
	l.s $f0, 0($s4)           # Delta time é usado para criar um movimento mais suave
	jal move_ball
	
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
	sh $t0, 2($s1)
	
	protocol_emit (PROTOCOL_SET_COLOR, 0, 0, 0)
	protocol_emit (PROTOCOL_CLEAR_SCREEN)
	
	# Pula a verificação de tecla
	j .draw
	
.init:
	# Verifica se a tecla enter (13) foi pressionada para começar o jogo
	protocol_geti (PROTOCOL_KEY, $t0)
	bne $t0, 13, .draw
	
	# Caso apertou põe o jogo no próximo estado: inicialização
	li $t0, 1
	sb $t0, 0($s3)
	
.draw:
	protocol_emit (PROTOCOL_SET_COLOR, 255, 255, 255)
	
	lw $a0, 0($s0)
	lw $a1, 4($s0)
	jal draw_racket
	
	lw $a0, 0($s1)
	lw $a1, 4($s1)
	jal draw_racket
	
	l.s $f0, 0($s2)
	l.s $f1, 4($s2)
	lb $a0, 8($s2)
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
    and $t0, $a0, 0xFFFF    # extrai a posição x da raquete 0x____XXXX
    srl $t1, $a0, 16        # extrai a posição y da raquete 0xYYYY____
	
    and $t2, $a1, 0xFFFF    # extrai a largura 0x____LLLL
    srl $t3, $a1, 16        # extrai a altura 0xAAAA____
	
	protocol_emit (PROTOCOL_DRAW_RECT, $t0, $t1, $t2, $t3)
	jr $ra
	
move_ball:
	lb $t0, 9($a0)             # direção
	
	# Direções:
	#   0 não muda
	#   1 superior esquerda
	#   2 superior direita
	#   3 inferior direita
	#   4 inferior esquerda
	bne $t0, 0, .ball_dir_1
	jr $ra
.ball_dir_1:
	# Apenas lê a posição e velocidade se for movimentar a bola, ou seja, quando
	# a direção é não é zero.
	lhu $t1, 10($a0)            # velocidade
	mtc1 $t1, $f2               # move a velocidade para FPU (Float Process Unit)
	cvt.s.w $f2, $f2            # O número movido precisa ser convertido para ser considerado um float
	
	# É aqui onde deixa o movimento suave, multiplica a velocidade pelo delta time,
	# a explicação mais simples é que o movimento vai acontecer x pixels em 1 segundo
	# para formar o segundo tem a soma de todos o delta times, então um delta time é
	# uma fração do movimento, confuso, mas é isso.
	mul.s $f2, $f2, $f0
	
	# A partir desse ponto delta time ($f0) deixa de exitir sendo agora a posição x da bola
	l.s $f0, 0($a0)             # posição x
	l.s $f1, 4($a0)             # posição y
	
	bne $t0, 1, .ball_dir_2
	# Implementar o movimento
	j .ball_update_pos
	
.ball_dir_2:
	bne $t0, 2, .ball_dir_3
	# Implementar o movimento
	j .ball_update_pos

.ball_dir_3:
	bne $t0, 2, .ball_dir_4
	# Implementar o movimento
	j .ball_update_pos

.ball_dir_4:
	# Implementar o movimento
	
.ball_update_pos:
	s.s $f0, 0($a0)             # guarda a posição x
	s.s $f1, 4($a0)             # guarda a posição y
	
	jr $ra
	
draw_ball:
	# Converte de uma posição float para uma posição inteira
	cvt.w.s $f0, $f0
	cvt.w.s $f1, $f1
	
	# Move dos registradores float pra os registradores inteiros
	mfc1 $t0, $f0
	mfc1 $t1, $f1
	
	# Só para evitar dor de cabeça move o tamanho da bola para um
	# registrador temporário
	move $t2, $a0
	
	protocol_emit (PROTOCOL_DRAW_CIRCLE, $t0, $t1, $t2)
	jr $ra

# vim: ft=asm
