#!/usr/bin/env python3

import subprocess
import pygame

def read_protocol(proc):
    # Ler o comando que deve ser executado
    cmd = ''
    byte = proc.stdout.read1(1).decode()

    while byte != '$':
        cmd += byte
        byte = proc.stdout.read1(1).decode()

    # Ler os argumentos do commando
    arg = ''
    args = []
    byte = proc.stdout.read1(1).decode()
    while byte != '$':
        if byte == ';':
            args.append(arg)
            arg = ''
        else:
            arg += byte
        byte = proc.stdout.read1(1).decode()

    return [cmd, args]


def main():
    WIDTH = 600
    HEIGHT = 480

    try:
        subprocess.run(['java', '--version'], stdout=subprocess.DEVNULL,
                       stderr=subprocess.DEVNULL)
    except FileNotFoundError:
        print('Certifique-se que o java está instalado!')
        return

    pygame.init()

    running = True
    screen = pygame.display.set_mode((WIDTH, HEIGHT))
    color = pygame.Color(0, 0, 0)

    last_key = -1
    key_pending = False

    proc = subprocess.Popen(['java', '-jar', 'Mars.jar', 'pong-client.asm'],
                            stdin=subprocess.PIPE, stdout=subprocess.PIPE)

    # Ignorar as primeira linhas de saída padrão do Mars
    proc.stdout.read1(68)

    while proc.poll() == None and running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.KEYDOWN:
                last_key = (str(event.key) + '\n').encode()

        if not key_pending:
            cmd, args = read_protocol(proc)

        if cmd == 'done':
            running = False
        elif cmd == 'clear':
            screen.fill(color)
        elif cmd == 'setcolor':
            color.update([int(x) for x in args])
        elif cmd == 'rect':
            rect = pygame.Rect((int(args[0]), int(args[1])),
                               (int(args[2]), int(args[3])))
            pygame.draw.rect(screen, color, rect)
        elif cmd == 'circle':
            pygame.draw.circle(screen, color, (int(args[0]), int(args[1])),
                               int(args[2]))
        elif cmd == 'key':
            if last_key == -1:
                key_pending = True
            else:
                proc.stdin.write(last_key)
                proc.stdin.flush()

                last_key = -1
                key_pending = False
        elif cmd == 'mousex':
            proc.stdin.write(str(pygame.mouse.get_pos()[0]).encode())
            proc.stdin.write(b'\n')
            proc.stdin.flush()
        elif cmd == 'mousey':
            proc.stdin.write(str(pygame.mouse.get_pos()[1]).encode())
            proc.stdin.write(b'\n')
            proc.stdin.flush()
        else:
            print('Comando não reconhecido:')
            print(cmd, args)
            running = False

        pygame.display.flip()

    proc.kill()
    pygame.quit()

if __name__ == '__main__':
    main()

