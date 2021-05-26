COMMANDS = [
    {
    'title' : 'add word',
    'cmd'   : 'add_word',
    'mode'  : 'w'
    },
    {
    'title' : 'alt rusword',
    'cmd'   : 'update_word_rusw',
    'mode'  : 'w'
    },
    {
    'title' : 'alt engword',
    'cmd'   : 'update_word_engw',
    'mode'  : 'w'
    },
    {
    'title' : 'alt mem',
    'cmd'   : 'update_word_mem',
    'mode'  : 'w'
    },
    {
    'title' : 'alt trscr',
    'cmd'   : 'update_word_trscr',
    'mode'  : 'w'
    },
    {
    'title' : 'list words',
    'cmd'   : 'list_words',
    'mode'  : 'r'
    },
    {
    'title' : 'list trwords',
    'cmd'   : 'list_word_translation',
    'mode'  : 'r'
    },
    {
    'title' : 'list topics',
    'cmd'   : 'list_topics',
    'mode'  : 'r'
    },
    {
    'title' : 'list tw',
    'cmd'   : 'list_topic_word',
    'mode'  : 'w'
    },
    {
    'title' : 'list trtw',
    'cmd'   : 'list_topic_word_translation',
    'mode'  : 'w'
    },
    {
    'title' : 'delete word',
    'cmd'   : 'delete_word',
    'mode'  : 'w'
    },
    {
    'title' : 'create topic',
    'cmd'   : 'create_topic',
    'mode'  : 'w'
    },
    {
    'title' : 'alt topic',
    'cmd'   : 'update_topic',
    'mode'  : 'w'
    },
    {
    'title' : 'delete topic',
    'cmd'   : 'delete_topic',
    'mode'  : 'w'
    },
    {
    'title' : 'add wint',
    'cmd'   : 'add_word_in_topic',
    'mode'  : 'w'
    },
    {
    'title' : 'random test',
    'cmd'   : 'check_random_words',
    'mode'  : 'r'
    },
    {
    'title' : 'del badw',
    'cmd'   : 'delete_badword',
    'mode'  : 'w'
    },
    {
    'title' : 'info',
    'cmd'   : 'info',
    'mode'  : 'r'
    }
]
    
def determine_command(title):
    for cmd in COMMANDS:
        if cmd['title'] == title.strip():
            return cmd
    return False

def exec_cmd(cmd, attr, title):
    attr = attr.split()
    if title == 'add word':
        if len(attr) == 3:
            cmd(attr[0], attr[1], attr[2])
        if len(attr) == 2:
            cmd(attr[0], attr[1])
        elif len(attr) > 3 or len(attr) < 2:
            print 'Wrong number of arguments'
        return
    if title == 'alt rusword':
        if len(attr) == 3:
            cmd(attr[0], attr[1], attr[2])
        else:
            print 'Wrong number of arguments'
        return
    if title == 'alt engword':
        if len(attr) == 3:
            cmd(attr[0], attr[1], attr[2])
        else:
            print 'Wrong number of arguments'
        return
    if title == 'alt mem':
        if len(attr) == 3:
            cmd(attr[0], attr[1], attr[2])
        else:
            print 'Wrong number of arguments'
        return
    if title == 'alt trscr':
        if len(attr) == 3:
            cmd(attr[0], attr[1], attr[2])
        else:
            print 'Wrong number of arguments'
        return
    if title == 'list tw':
        if len(attr) == 1:
            cmd(attr[0])
        else:
            print 'Wrong number of arguments'
        return
    if title == 'list trtw':
        if len(attr) == 1:
            cmd(attr[0])
        else:
            print 'Wrong number of arguments'
        return
    if title == 'delete word':
        if len(attr) == 2:
            cmd(attr[0], attr[1])
        else:
            print 'Wrong number of arguments'
        return
    if title == 'create topic':
        if len(attr) == 1:
            cmd(attr[0])
        else:
            print 'Wrong number of arguments'
        return
    if title == 'alt topic':
        if len(attr) == 2:
            cmd(attr[0], attr[1])
        else:
            print 'Wrong number of arguments'
        return
    if title == 'delete topic':
        if len(attr) == 1:
            cmd(attr[0])
        else:
            print 'Wrong number of arguments'
        return
    if title == 'add wint':
        if len(attr) == 3:
            cmd(attr[0], attr[1], attr[2])
        else:
            print 'Wrong number of arguments'
        return
    if title == 'del badw':
        if len(attr) == 2:
            cmd(attr[0], attr[1])
        else:
            print 'Wrong number of arguments'
        return
