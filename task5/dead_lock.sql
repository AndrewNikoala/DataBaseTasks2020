DROP TABLE IF EXISTS Students;

CREATE TABLE Students(
    id SERIAL PRIMARY KEY,
    name char(50)
);

INSERT INTO Students (name) VALUES ('Bob'), ('John');

BEGIN TRANSACTION;
UPDATE Students set name = 'Bobos' WHERE id = 1;
UPDATE Students set name = 'Jhonos' WHERE id = 2;
COMMIT;

SELECT *FROM Students;

BEGIN TRANSACTION;
UPDATE Students set name = 'Jhonotan' WHERE id = 2;
UPDATE Students set name = 'Bobophet' WHERE id = 1;
COMMIT;

SELECT *FROM Students;
