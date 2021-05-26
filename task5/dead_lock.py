import psycopg2, time
from threading import Thread

NumIter = 1000

def getConnection():
    return psycopg2.connect(database="task5", user="andrew", password="12345", host="127.0.0.1")


query1 = """UPDATE Students SET name = 'Bobos' WHERE id = 1"""
query2 = """UPDATE Students SET name = 'Jhonos' WHERE id = 2;"""

def transaction1():
    global query1
    global query2

    con = connection.cursor()
    try:
        for i in range(NumIter):
            con.execute(query1)
            con.execute(query2)
        connection.commit() 
    except:
        print 'interlock1'

def transaction2():
    global query1
    global query2

    con = connection.cursor()
    try:
        for i in range(NumIter):
            con.execute(query2)
            con.execute(query1)
        connection.commit()
    except:
        print 'interlock2'

try:
    connection = getConnection()

    Thread1 = Thread(target=transaction1)
    Thread2 = Thread(target=transaction2)

    Thread1.start()
    Thread2.start()

    Thread1.join()
    Thread2.join()
except:
    print "Something wrong happened"
finally:
    connection.close()
