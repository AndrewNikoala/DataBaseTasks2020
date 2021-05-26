#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fileencoding=utf-8
from initDB import execute
import sys
    
# add word in the table with words
add_word =                                lambda engword, rusword, transcription = '': execute("INSERT INTO words VALUES (%s, %s, %s);", engword, transcription, rusword)
# update word | rusword
update_word_rusw =                                                 lambda engword_pk, rusword_pk, rusword: execute("UPDATE words SET rusword = %s WHERE rusword=%s AND engword=%s", rusword, rusword_pk, engword_pk)
# update word | engword
update_word_engw =                                                 lambda engword_pk, rusword_pk, engword: execute("UPDATE words SET engword = %s WHERE rusword=%s AND engword=%s", engword, rusword_pk, engword_pk)
# update word | transcription
update_word_trscr =                                       lambda engword_pk, rusword_pk, transcription: execute("UPDATE words SET transcription = %s WHERE rusword=%s AND engword=%s", transcription, rusword_pk, engword_pk)
# update word | memorized
update_word_mem =                                       lambda engword_pk, rusword_pk, memorized: execute("UPDATE words SET memorized = %s WHERE rusword=%s AND engword=%s", memorized, rusword_pk, engword_pk)
# delete word
delete_word =                                                       lambda engword_pk, rusword_pk:        execute("DELETE FROM words WHERE rusword=%s AND engword=%s", rusword_pk, engword_pk)

# create topic in the table with topics
create_topic =                               lambda name: execute("INSERT INTO topics VALUES (%s);", name)
# update topic
update_topic =                                                      lambda name_pk, name:     execute("UPDATE topics SET name = %s WHERE name=%s", name, name_pk)
# delete topic
delete_topic = lambda name: execute("DELETE FROM topics WHERE name=%s", name)
# view a list of words in the certain topic
select_words_in_topic =                                                                   lambda topic: execute("SELECT DISTINCT words.engword FROM words, topics, bondWT WHERE bondWT.topic_name = %s AND bondWT.rusword_rf = words.rusword AND bondWT.engword_rf = words.engword", topic)
# view a list of words in the certain topic with translation
select_words_in_topic_tr =                                                                lambda topic: execute("SELECT DISTINCT words.rusword, words.transcription, words.engword FROM words, topics, bondWT WHERE bondWT.topic_name = %s AND bondWT.rusword_rf = words.rusword AND bondWT.engword_rf = words.engword", topic)

def translate_word(engword):
    res = execute("SELECT engword, rusword FROM words WHERE engword = %s", engword)
    print " ~~~~~~~~~~~~~~~ "
    print " Translation \n ~~~~~~~~~~~~~~~"
    for r in res:
        print "   {} | {}".format(r[0], r[1])

def list_words():
    res = execute("SELECT engword FROM words;")
    print " ~~~~~~~~~~~~~~~ "
    print " List of words  \n ~~~~~~~~~~~~~~~"
    for r in res:
        print "   {}".format(r[0])
        
def list_word_translation():
    res = execute("SELECT *FROM words;")
    print " ~~~~~~~~~~~~~~~ "
    print " List of words  \n ~~~~~~~~~~~~~~~"
    for r in res:
        print "{} | {} | {}".format(r[0], r[1], r[2])
        
def list_topics():
    res = execute("SELECT *FROM topics;")
    print " ~~~~~~~~~~~~~~~ "
    print " List of topics \n ~~~~~~~~~~~~~~~"
    for r in res:
        print "   {}".format(r[0])

def list_topic_word(topic):
    res = select_words_in_topic(topic)
    print " ~~~~~~~~~~~~~~~~~~~~ "
    print " List of {} words \n ~~~~~~~~~~~~~~~~~~~~".format(topic)
    for r in res:
        print "   {}".format(r[0])
        
def list_topic_word_translation(topic):
    res = select_words_in_topic_tr(topic)
    print " ~~~~~~~~~~~~~~~~~~~~ "
    print " List of {} words \n ~~~~~~~~~~~~~~~~~~~~".format(topic)
    for r in res:
        print "{} | {} | {}".format(r[0], r[1], r[2])
        
def add_word_in_topic(topic, engword, rusword):
    execute("DELETE FROM bondWT WHERE topic_name = %s AND (rusword_rf IS NULL OR engword_rf IS NULL);", topic)
    execute("DELETE FROM bondWT WHERE rusword_rf = %s AND engword_rf = %s AND topic_name IS NULL", rusword, engword)
    execute("INSERT INTO bondWT (topic_name, engword_rf, rusword_rf) VALUES(" +
            "%s, %s, %s)", topic, engword, rusword)
    
def check_word(engword):
    while 1:
        print ">>>", engword
        response = sys.stdin.readline()
        if response.upper().strip() == "Y": 
            execute("CALL check_hl(%s, %s, %s)", 1, 0, engword)
            execute("CALL check_bw(%s, %s, %s)", 1, 0, engword)
            break
        elif response.upper().strip() == "N": 
            execute("CALL check_hl(%s, %s, %s)", 0, 1, engword)
            execute("CALL check_bw(%s, %s, %s)", 0, 1, engword)
            break
        else:
            print "Wrong response"
            continue
        
def check_random_words():
    print "Do you know the translation of these words:"
    print "<< Answer 'Y' if you know the word, 'N' otherwise >> : ".strip()
    res = execute("SELECT engword FROM words ORDER BY random() LIMIT 10;")
    for r in res:
        check_word(r[0])
        ans = execute("SELECT engword, transcription, rusword FROM words WHERE engword = %s", r[0])
        for a in ans:
            print "{} | {} | {}".format(a[0], a[1], a[2])
        
def info():
    print "Hello! This is your dictionary."
    print "You can add and change new words." 
    print "Daily checking of words will allow you improve your vocabulary.\n"
    print "In order for you to use a command with attributes, you need to enter the command first then enter attributes."
    print "These commands allow you to manage the dictionary:"
    print "<add word>     - add new word in the dictionary.                      {engword|rusword|[transcription]}"
    print "<create topic> - create new topic.                                    {name of topic}"
    print "<add wint>     - add word in the topic.                               {name of topic|engword_pk|rusword_pk}"
    print "<alt rusword>  - alter russian word if you made mistake.              {engword_pk|rusword_pk|rusword}"
    print "<alt engword>  - alter english word if you made mistake.              {engword_pk|rusword_pk|engword}"
    print "<alt trscr>    - alter transcription if you made mistake.             {engword_pk|rusword_pk|transcription}"
    print "<alt mem>      - alter condition of the word (learned or unlearned).  {engword_pk|rusword_pk|memorized}"
    print "<alt topic>    - alter name of topic if you made mistake.             {name.pk|name of topic}"
    print "<delete word>  - delete word.                                         {engword_pk|rusword_pk}"
    print "<delete topic> - delete topic.                                        {name of topic}"
    print "<list words>   - show list of words without translation."
    print "<list trwords> - show list of words with translation."
    print "<list topics>  - show list of topics."
    print "<list tw>      - show list of topic words without translation.        {name of topic}"
    print "<list trtw>    - show list of topic words with translation.           {name of topic}"
    print "<random test>  - run test with 10 random words."
    print "<exit>         - exit from the application."
    print "\n"
    
def start_pack():
    execute(open("start_pack.sql", "r").read())
    add_word_in_topic('food', 'vegetables', 'овощи')
    add_word_in_topic('food', 'fruits', 'фрукты')
    add_word_in_topic('food', 'fish', 'рыба')
    add_word_in_topic('food', 'diet', 'диета')
    add_word_in_topic('food', 'dessert', 'десерт')
    add_word_in_topic('animal', 'frog', 'лягушка')
    add_word_in_topic('animal', 'newt', 'тритон')
    add_word_in_topic('animal', 'jay', 'сойка')
    add_word_in_topic('animal', 'pike', 'щука')
    add_word_in_topic('insects', 'aphid', 'тля')
    add_word_in_topic('insects', 'dragonfly', 'стрекоза')
    add_word_in_topic('insects', 'larva', 'личинка')
    add_word_in_topic('insects', 'wasp', 'оса')
    add_word_in_topic('transport', 'ferries', 'паром')
    add_word_in_topic('transport', 'lorries', 'грузовики')
