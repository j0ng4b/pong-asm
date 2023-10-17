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
    clock = pygame.time.Clock()
    color = pygame.Color(0, 0, 0)

    proc = subprocess.Popen(['java', '-jar', 'Mars.jar', 'pong-client.asm'],
                            stdin=subprocess.PIPE, stdout=subprocess.PIPE)

    # Ignorar as primeira linhas de saída padrão do Mars
    proc.stdout.read1(68)

    while proc.poll() == None and running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False

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

        pygame.display.flip()
        clock.tick(60)

    proc.kill()
    pygame.quit()

if __name__ == '__main__':
    main()

