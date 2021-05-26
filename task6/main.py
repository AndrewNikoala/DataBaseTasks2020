import commands
import initDB
import parser

import os, sys

def get_command(c):
    if c in commands.__dict__:
        return commands.__dict__[c]

def main():
    print "<<< Daily dictionary >>>"
    print "Enter <info> to know more info"
    initDB.init_db()
    commands.start_pack()
    while 1:
        # input command
        print "\n\n=========================================================================================================="
        title_cmd = sys.stdin.readline()
        print ".........................................................................................................."
        if title_cmd.strip() == 'exit':
            break
        title_cmd = parser.determine_command(title_cmd)
        if not title_cmd:
            print 'Wrong command'
            continue
        cmd = get_command(title_cmd['cmd'])
        # input attributes for command then execute the command
        if title_cmd['mode'] == 'w':
            attr = sys.stdin.readline()
            parser.exec_cmd(cmd, attr, title_cmd['title'])
        else:
            cmd()

if __name__ == '__main__':
	main()
