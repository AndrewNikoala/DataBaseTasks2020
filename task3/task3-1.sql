----------------------------------------------------------------------------------------------------------
-------- TABLE LEVEL -------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS B;
DROP TABLE IF EXISTS A;

CREATE TABLE A(
    id INTEGER PRIMARY KEY,
    data VARCHAR(255)
);

CREATE TABLE B(
    id INTEGER PRIMARY KEY,
    data VARCHAR(255),
    aid INTEGER REFERENCES A(id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO A (id, data) VALUES (1, 'HELLO');
INSERT INTO B (id, data, aid) VALUES (1, 'BYE', 1);

SELECT *FROM A;
SELECT *FROM B;

UPDATE A SET id=2 WHERE id=1;
SELECT *FROM A;
SELECT *FROM B;

DELETE FROM A WHERE id=2;
SELECT *FROM A;
SELECT *FROM B;

----------------------------------------------------------------------------------------------------------
-------- SQL LEVEL ---------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS B;
DROP TABLE IF EXISTS A;

CREATE TABLE A(
    id INTEGER,
    data VARCHAR(255),
    CONSTRAINT id PRIMARY KEY (id)
);

CREATE TABLE B(
    id INTEGER,
    data VARCHAR(255),
    aid INTEGER,
    FOREIGN KEY (aid) REFERENCES A (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT perk PRIMARY KEY (id)     
);

INSERT INTO A (id, data) VALUES (1, 'HELLO');
INSERT INTO B (id, data, aid) VALUES (1, 'BYE', 1);

SELECT *FROM A;
SELECT *FROM B;

UPDATE A SET id=2 WHERE id=1;
SELECT *FROM A;
SELECT *FROM B;

DELETE FROM A WHERE id=2;
SELECT *FROM A;
SELECT *FROM B;
