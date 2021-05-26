import psycopg2
import sys
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
#standard passwords for postgres
password = ("", "postgres" ,"master")

# connect to database
def get_connection(db):
    for pwd in password:
        try:
            con = psycopg2.connect(database=db, user="postgres", password=pwd, host="localhost")
            #clearly see begin and commit
            con.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
            return con
        except Exception as e:
            #print e
            pass
    sys.exit()

# execute any query; only daily_dictionary database
def execute(query, *p):
    #print 'query = ', query
    #print 'p = ', p
    con = get_connection("daily_dictionary")
    try:
        cur = con.cursor()
        cur.execute(query, p)
        result = cur.fetchall()
    except Exception as e:
        #print e
        result = None
    finally:
        con.close()
        return result
    
# create new database
def create_db():
    con = get_connection("postgres")
    try:
        cur = con.cursor()
        cur.execute("CREATE DATABASE daily_dictionary;")
        result = cur.fetchall()
    except Exception as e:
        #print e
        result = None
    finally:
        con.close()
        return result

def create_tables():
# create table with words
    execute("CREATE TABLE words(" +
            "engword         VARCHAR(255)    NOT NULL," +
            "transcription   VARCHAR(255)," +
            "rusword         VARCHAR(255)    NOT NULL," +
            "memorized       BOOLEAN, "
            "PRIMARY KEY (engword, rusword));")

# create table with topics
    execute("CREATE TABLE topics(" +
            "name            VARCHAR(255)    PRIMARY KEY," +
            "num_words       INTEGER," +
            "knowl_lvl       INTEGER         CHECK(knowl_lvl >= 0 AND knowl_lvl <= 100));")
    
# create table bonding words and topics
    execute("CREATE TABLE bondWT(" +
            "topic_name      VARCHAR(255)    REFERENCES topics(name) ON DELETE CASCADE ON UPDATE CASCADE," +
            "engword_rf      VARCHAR(255)," +
            "rusword_rf      VARCHAR(255)," +
            "FOREIGN KEY (engword_rf, rusword_rf) REFERENCES words(engword, rusword) ON DELETE CASCADE ON UPDATE CASCADE);")
    
# create history_learning
    execute("CREATE TABLE history_learning(" +
            "engword_rf      VARCHAR(255)," +
            "rusword_rf      VARCHAR(255)," +
            "num_checking    INTEGER         NOT NULL," +
            "success         INTEGER," +
            "fail            INTEGER," +
            "data_create     DATE," +
            "data_last_check DATE," +
            "FOREIGN KEY (engword_rf, rusword_rf) REFERENCES words(engword, rusword) ON DELETE CASCADE ON UPDATE CASCADE);")

# create table with not learned words
    execute("CREATE TABLE badwords("+
            "engword_rf      VARCHAR(255)," +
            "rusword_rf      VARCHAR(255)," +
            "success         INTEGER         NOT NULL," +
            "fail            INTEGER         NOT NULL," +
            "knowl_lvl       INTEGER         NOT NULL," +
            "FOREIGN KEY (engword_rf, rusword_rf) REFERENCES words(engword, rusword) ON DELETE CASCADE ON UPDATE CASCADE);")


def trig_modification_words():
# automatically add data in the history_learning and bondWT after insert in the words
    execute("DROP FUNCTION IF EXISTS modification_word() CASCADE;")
    execute("CREATE OR REPLACE FUNCTION modification_word() RETURNS trigger AS $modification_word$ " +
            "BEGIN " +
            "INSERT INTO history_learning (rusword_rf, engword_rf, num_checking, success, fail, data_create, data_last_check)" +
            "VALUES( NEW.rusword, NEW.engword, 0, 0, 0, now(), now()); " +
            "INSERT INTO bondWT (rusword_rf, engword_rf)" +
            "VALUES( NEW.rusword, NEW.engword); " +
            "RETURN NULL; " + 
            "END; " +
            "$modification_word$ LANGUAGE plpgsql;")
    execute("CREATE TRIGGER modification_word AFTER INSERT ON words " +
            "FOR EACH ROW EXECUTE PROCEDURE modification_word();")
    
def trig_modification_topics():
# automatically add data in the bondWT after insert in the topics
    execute("DROP FUNCTION IF EXISTS modification_topic() CASCADE;")
    execute("CREATE OR REPLACE FUNCTION modification_topic() RETURNS trigger AS $modification_topic$ " +
            "BEGIN " +
            "INSERT INTO bondWT (topic_name)" +
            "VALUES( NEW.name); " +
            "RETURN NULL; " + 
            "END; " +
            "$modification_topic$ LANGUAGE plpgsql;")
    execute("CREATE TRIGGER modification_topic AFTER INSERT ON topics " +
            "FOR EACH ROW EXECUTE PROCEDURE modification_topic();")

def trig_modification_bondWT():    
# automatically add data in the topic after update in the bondWT
    execute("DROP FUNCTION IF EXISTS modification_bondWT() CASCADE;")
    execute("CREATE OR REPLACE FUNCTION modification_bondWT() RETURNS trigger AS $modification_bondWT$ "+
            "BEGIN " +
            "UPDATE topics SET num_words = (SELECT COUNT(topic_name) " + 
            "FROM bondWT WHERE topic_name = NEW.topic_name) WHERE name = NEW.topic_name; " +
            "RETURN NULL; " +
            "END; " +
            "$modification_bondWT$ LANGUAGE plpgsql;")
    execute("CREATE TRIGGER modification_bondWT AFTER INSERT OR UPDATE ON bondWT " +
            "FOR EACH ROW EXECUTE PROCEDURE modification_bondWT();")
    
def trig_add_badword():
# automatically add badword in the table badwords
    execute("DROP FUNCTION IF EXISTS add_badword() CASCADE;")
    execute("CREATE OR REPLACE FUNCTION add_badword() RETURNS trigger AS $add_badword$ " +
            "BEGIN " +
            "IF EXISTS(SELECT *FROM words WHERE memorized = FALSE) THEN " +
            "INSERT INTO badwords (engword_rf, rusword_rf, success, fail, knowl_lvl) VALUES(" +
            "NEW.engword, NEW.rusword, 0, 0, 0); " +
            "END IF; " +
            "RETURN NULL; " +
            "END; " +
            "$add_badword$ LANGUAGE plpgsql; ")
    execute("CREATE TRIGGER add_badword AFTER UPDATE ON words " +
            "FOR EACH ROW EXECUTE PROCEDURE add_badword();")
    
def trig_del_badword():
# automatically delete badword in the table badwords
    execute("DROP FUNCTION IF EXISTS del_badword() CASCADE;")
    execute("CREATE OR REPLACE FUNCTION del_badword() RETURNS trigger AS $del_badword$ " +
            "BEGIN " +
            "IF EXISTS(SELECT *FROM words WHERE memorized = TRUE) THEN " +
            #"UPDATE words SET memorized = TRUE WHERE engword = OLD.engword_rf AND rusword = OLD.rusword_rf; " +
            "DELETE FROM badwords WHERE engword_rf = NEW.engword AND rusword_rf = NEW.rusword; " +
            "END IF; " +
            "RETURN NULL; " +
            "END; " +
            "$del_badword$ LANGUAGE plpgsql; ")
    execute("CREATE TRIGGER del_badword AFTER UPDATE ON words " +
            "FOR EACH ROW EXECUTE PROCEDURE del_badword();")
def create_procedures():
# automotically add changes in history_learning and badwords
    execute("DROP PROCEDURE IF EXISTS check_hl(INTEGER, INTEGER, VARCHAR) CASCADE;")
    execute("CREATE OR REPLACE PROCEDURE check_hl(s_count INTEGER, f_count INTEGER, engword VARCHAR) " +
            "LANGUAGE SQL " +
            "AS $$ " +
            "UPDATE history_learning SET num_checking = num_checking + 1, success = success + s_count, "+
            "fail = fail + f_count, data_last_check = now() WHERE engword_rf = engword " +
            "$$;")
    
    execute("DROP PROCEDURE IF EXISTS check_bw(INTEGER, INTEGER, VARCHAR) CASCADE;")
    execute("CREATE OR REPLACE PROCEDURE check_bw(s_count INTEGER, f_count INTEGER, engword VARCHAR) " +
            "LANGUAGE SQL " +
            "AS $$ " +
            "UPDATE badwords SET success = success + s_count, "+
            "fail = fail + f_count WHERE engword_rf = engword " +
            "$$;")

def create_triggers():
    trig_modification_words()
    trig_modification_topics()
    trig_modification_bondWT()
    trig_add_badword()
    trig_del_badword()
    

def delete_all():
    execute("DROP TABLE words CASCADE;")
    execute("DROP TABLE topics CASCADE;")
    execute("DROP TABLE bondWT;")
    execute("DROP TABLE history_learning;")
    execute("DROP TABLE badwords;")
 
# init to database
def init_db():
    create_db()
    create_tables()
    create_triggers()
    create_procedures()
