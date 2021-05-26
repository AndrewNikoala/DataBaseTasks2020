-- 5.2 Придумать и реализовать хранимую процедуру / триггер:
DROP TABLE IF EXISTS counter;

CREATE TABLE counter(
    id SERIAL PRIMARY KEY,
    num INTEGER
);

----------------------------------------------------------------------------------------------------------
-- Демонстрация работы транзакции
BEGIN;
    INSERT INTO counter (num) VALUES (1);
    SAVEPOINT sp_1;
    INSERT INTO counter (num) VALUES (2);
    ROLLBACK TO sp_1;
    INSERT INTO counter (num) VALUES (3);
COMMIT;
SELECT *FROM counter;

----------------------------------------------------------------------------------------------------------    
-- процедура
CREATE OR REPLACE PROCEDURE insert_data(a INTEGER, b INTEGER)
LANGUAGE SQL
AS $$
    INSERT INTO counter (num) VALUES (a);
    INSERT INTO counter (num) VALUES (b);
$$;
CALL insert_data(4, 5);
SELECT *FROM counter;

----------------------------------------------------------------------------------------------------------
-- триггерная функция
CREATE OR REPLACE FUNCTION  update_data() RETURNS trigger AS $update_data$
    BEGIN
        UPDATE counter SET num = 111 WHERE id = 1;
        RETURN NULL;
    END;
$update_data$ LANGUAGE plpgsql;

CREATE TRIGGER update_data AFTER INSERT ON counter
    FOR EACH ROW EXECUTE PROCEDURE update_data();
    
    

CREATE OR REPLACE FUNCTION  insert_data() RETURNS trigger AS $insert_data$
    BEGIN
        INSERT INTO counter (num) VALUES (777);
        RETURN NULL;
    END;
$insert_data$ LANGUAGE plpgsql;

CREATE TRIGGER insert_data AFTER UPDATE ON counter
    FOR EACH ROW EXECUTE PROCEDURE insert_data();    
    
-- стриггерим и зациклим     
INSERT INTO counter (num) VALUES(6);
SELECT *FROM counter;

----------------------------------------------------------------------------------------------------------
