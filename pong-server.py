#!/usr/bin/env python3

import signal
import subprocess

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
    try:
        subprocess.run(['java', '--version'], stdout=subprocess.DEVNULL,
                       stderr=subprocess.DEVNULL)
    except FileNotFoundError:
        print('Certifique-se que o java está instalado!')
        return

    proc = subprocess.Popen(['java', '-jar', 'Mars.jar', 'pong-client.asm'],
                            stdin=subprocess.PIPE, stdout=subprocess.PIPE)

    # Ignorar as primeira linhas de saída padrão do Mars
    proc.stdout.read1(68)

    while proc.poll() == None:
        cmd, args = read_protocol(proc)

    proc.kill()

if __name__ == '__main__':
    main()

