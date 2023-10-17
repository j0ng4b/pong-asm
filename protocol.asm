##
## Cabeçalho e rodapé
##

# Usados para indicar que o programa está inicializado
.eqv PROTOCOL_READY "ready$"

# Indica que o programa deve encerrar a comunição
.eqv PROTOCOL_DONE "done$"

##
## Comandos
##

# Define a cor de desenho e do fundo da tela
# argumentos:
#   r,g,b -> cor rgb
.eqv PROTOCOL_SET_COLOR "setcolor$"

# Limpa a tela, não tem argumentos
.eqv PROTOCOL_CLEAR_SCREEN "clear$"

# Desenha um retângulo na tela
# argumentos:
#   x,y -> posição do retângulo
#   w,h -> largura e altura do retângulo
.eqv PROTOCOL_DRAW_RECT "rect$"

# Desenha um círculo na tela
# argumentos:
#   cx,cy -> coordenadas do centro do círculo
#   r -> raio do círculo
.eqv PROTOCOL_DRAW_CIRCLE "circle$"

# Desenha uma linha na tela
# argumentos:
#   sx, sy -> posição inicial da linha
#   ex, ey -> posição final da linha
.eqv PROTOCOL_DRAW_LINE "line$"

# Não deve ser usada diretamente, apenas pela macro protocol_emit
# pois é usada para emitir um comando.
.macro __emit_cmd (%cmd)
	.data 
protocol_cmd_lb: .asciiz %cmd

	.text
	li $v0, SYSCALL_PRINT_STRING
	la $a0, protocol_cmd_lb
	syscall
.end_macro

# Não deve ser usada diretamente, apenas pela macro protocol_emit
# pois é usada para emitir um argumento de um comando.
.macro __emit_arg (%arg)
	.text
	li $v0, SYSCALL_PRINT_INT
	add $a0, $zero, %arg
	syscall
	
	li $v0, SYSCALL_PRINT_CHAR
	li $a0, 0x3B
	syscall
.end_macro

# As macros abaixo são usadas para emitir um comando do protocolo
# não há problema delas terem o mesmo nome desde que tenha quantidade
# de parâmetros diferente, é o mesmo que overload.
.macro protocol_emit (%cmd)
	.text
	__emit_cmd (%cmd)
	
	li $v0, SYSCALL_PRINT_CHAR
	li $a0, 0x24
	syscall
.end_macro

.macro protocol_emit (%cmd, %arg1)
	.text
	__emit_cmd (%cmd)
	
	__emit_arg (%arg1)
	
	li $v0, SYSCALL_PRINT_CHAR
	li $a0, 0x24
	syscall
.end_macro

.macro protocol_emit (%cmd, %arg1, %arg2)
	.text
	__emit_cmd (%cmd)
	
	__emit_arg (%arg1)
	__emit_arg (%arg2)
	
	li $v0, SYSCALL_PRINT_CHAR
	li $a0, 0x24
	syscall
.end_macro

.macro protocol_emit (%cmd, %arg1, %arg2, %arg3)
	.text
	__emit_cmd (%cmd)
	
	__emit_arg (%arg1)
	__emit_arg (%arg2)
	__emit_arg (%arg3)
	
	li $v0, SYSCALL_PRINT_CHAR
	li $a0, 0x24
	syscall
.end_macro

.macro protocol_emit (%cmd, %arg1, %arg2, %arg3, %arg4)
	.text
	__emit_cmd (%cmd)
	
	__emit_arg (%arg1)
	__emit_arg (%arg2)
	__emit_arg (%arg3)
	__emit_arg (%arg4)
	
	li $v0, SYSCALL_PRINT_CHAR
	li $a0, 0x24
	syscall
.end_macro

# vim: ft=asm
