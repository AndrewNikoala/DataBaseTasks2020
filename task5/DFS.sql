---------------------------------------------------------------------------------------------------------
-- Создаём таблицы: узел и файл -------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS nodes CASCADE;
DROP TABLE IF EXISTS files CASCADE;
DROP FUNCTION IF EXISTS get_id(VARCHAR, INT, INT);
DROP FUNCTION IF EXISTS add_file(VARCHAR, VARCHAR, INT, INT, DATE, DATE);
DROP FUNCTION IF EXISTS remove_file(VARCHAR, INT);
DROP FUNCTION IF EXISTS rename_file(VARCHAR, INT, VARCHAR);
DROP FUNCTION IF EXISTS get_dir(VARCHAR);
DROP FUNCTION IF EXISTS get_lvl_dir(VARCHAR);
DROP FUNCTION IF EXISTS get_file_name(VARCHAR);
DROP FUNCTION IF EXISTS copy_file(VARCHAR, INT, VARCHAR, INT);
DROP FUNCTION IF EXISTS move_file(VARCHAR, INT, VARCHAR, INT);
DROP FUNCTION IF EXISTS list_files(fpath VARCHAR, fnode_id INT) CASCADE;

CREATE TABLE nodes (
    id SERIAL NOT NULL PRIMARY KEY,
    path VARCHAR(255)
); 

CREATE TABLE files (
    id SERIAL NOT NULL PRIMARY KEY,
    name VARCHAR(255),
    dir INTEGER NOT NULL,
    node_id INTEGER NOT NULL,
    file_size INTEGER,
    cr_data DATE,
    wr_data DATE,
    mod_data DATE,
    FOREIGN KEY (node_id) REFERENCES nodes(id)
);

---------------------------------------------------------------------------------------------------------
-- Создаём узлы и файлы ---------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
INSERT INTO nodes (path) VALUES ('A'), ('B'), ('C');

INSERT INTO files (name, dir, node_id, file_size, cr_data, wr_data, mod_data) VALUES 
('folder1', 0, 1, 1024, '2020-01-22', '2020-01-23', '2020-01-22'),
('file1',   1, 1, 2048, '2020-02-22', '2020-02-23', '2020-02-22'),
('folder2', 0, 2, 3072, '2020-03-22', '2020-03-23', '2020-03-22'),
('file2',   1, 2, 4096, '2020-04-22', '2020-04-23', '2020-04-22'),
('file3',   0, 3, 5120, '2020-05-22', '2020-05-23', '2020-05-22');

---------------------------------------------------------------------------------------------------------
-- Реализация процедур и функций ------------------------------------------------------------------------ ---------------------------------------------------------------------------------------------------------

-- Получить id файла или поддиректории и заодно проверить, что такое есть -------------------------------
CREATE OR REPLACE FUNCTION get_id(fpath VARCHAR, fdir INT, fnode INT) RETURNS INT AS $$
DECLARE 
    position INT;
    result_id INT;
BEGIN
-- Проверяем, что есть поддиректории или нет
    SELECT position('/' IN fpath) INTO position;
-- Если это не поддиректория, то проверяем наличие такого файла в системе
    IF position = 0 THEN
        SELECT id FROM files
        WHERE files.node_id = fnode AND files.dir = fdir AND files.name = fpath INTO result_id;
        RETURN coalesce(result_id, -1);
-- Если это вложенная поддиректория, то проверяем по рекурсии
    ELSE
        SELECT id FROM files 
        WHERE files.node_id = fnode AND files.dir = fdir AND files.name = (SELECT substr(fpath, 1, position-1)) INTO result_id;
        IF result_id is NULL THEN RETURN -1;
        ELSE
            RETURN get_id((SELECT substr(fpath, position+1)), fdir + 1, fnode);
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Создать файл ------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION add_file(fname VARCHAR, fpath VARCHAR, fnode_id INT, file_size INT, cr_data DATE, mod_data DATE) 
    RETURNS VARCHAR AS $$
DECLARE
    parrent_id INT;
BEGIN
-- Проверяем есть ли такой узел
    IF NOT EXISTS (SELECT *FROM nodes WHERE id = fnode_id) THEN RETURN 'Such node doesn`t exist'; 
    END IF;
-- Проверка есть ли такая директория
    SELECT get_id(fpath, 0, fnode_id) INTO parrent_id;
    IF parrent_id = -1 OR NOT EXISTS (SELECT * FROM files WHERE files.id = parrent_id) THEN 
        RETURN 'Parent directory doesn`t exist';
    ELSIF EXISTS (SELECT * FROM files WHERE files.node_id = fnode_id AND files.name = fname AND files.dir = parrent_id) THEN 
        RETURN 'The file already exists';
    ELSE
        INSERT INTO files (name, dir, node_id, file_size, cr_data, wr_data, mod_data) VALUES  (fname, parrent_id, fnode_id, file_size, cr_data, now(), mod_data);
        RETURN 'OK';
    END IF;
END;
$$ LANGUAGE plpgsql;


-- Удалить файл -----------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION remove_file(fpath VARCHAR, fnode_id INT)
    RETURNS VARCHAR AS $$
DECLARE
    f_id INT;
BEGIN
    SELECT get_id(fpath, 0, fnode_id) INTO f_id;
    IF f_id = -1 THEN 
        RETURN 'The file doesn`t exist';
    ELSE
        DELETE FROM files CASCADE WHERE id = f_id AND node_id = fnode_id;
        RETURN 'OK';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Переименовать файл -----------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION rename_file(fpath VARCHAR, fnode_id INT, new_name VARCHAR)
    RETURNS VARCHAR AS $$
DECLARE
    f_id INT;
BEGIN
    SELECT get_id(fpath, 0, fnode_id) INTO f_id;
    IF f_id = -1 THEN 
        RETURN 'The file doesn`t exist';
    ELSE
        UPDATE files SET name = new_name, mod_data = now() WHERE id = f_id;
        RETURN 'OK';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Вспомогательная функция, возвращающая родительскую директорию файла ----------------------------------
CREATE OR REPLACE FUNCTION get_dir(fpath VARCHAR)
    RETURNS VARCHAR AS $$
DECLARE
    dir VARCHAR;
BEGIN
    SELECT reverse(substr(reverse(fpath), position('/' IN reverse(fpath)) + 1)) INTO dir;
    RETURN dir;
END;
$$ LANGUAGE plpgsql;

-- Определение уровня вложенности файла или директории ----------------------------------------------
CREATE OR REPLACE FUNCTION get_lvl_dir(fpath VARCHAR)
    RETURNS INT AS $$
DECLARE
    lvl_dir INT;
BEGIN
    SELECT array_length(string_to_array(fpath, '/'), 1) - 1 INTO lvl_dir;
    RETURN lvl_dir;
END;
$$ LANGUAGE plpgsql;

-- Получить имя файла из path -----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_file_name(fpath VARCHAR)
    RETURNS VARCHAR AS $$
DECLARE
    file_name VARCHAR;
    position INT;
BEGIN
    SELECT position('/' IN fpath) INTO position;
    IF position = 0 THEN 
        RETURN fpath;
    ELSE
        SELECT right(fpath, position('/' IN reverse(fpath)) - 1) INTO file_name;
        RETURN file_name;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Копирование файла --------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION copy_file(fpath VARCHAR, fnode_id INT, new_path VARCHAR, new_fnode_id INT)
    RETURNS VARCHAR AS $$
DECLARE
    file_id INT;
    copy_parrent_id INT;
BEGIN
-- проверяем, что директория существует
    SELECT get_id(new_path, 0, new_fnode_id) INTO copy_parrent_id;
    IF copy_parrent_id = -1 THEN 
        RETURN 'New parent directory doesn`t exist';
    ELSE
        SELECT get_id(fpath, 0, fnode_id) INTO file_id;
-- Проверяем что существует или нет файл
        IF file_id = -1 THEN 
            RETURN 'The file doesn`t exist';
        ELSIF fnode_id = new_fnode_id AND get_dir(fpath) = new_path THEN
            RETURN 'The files with this name already exists in this folder';
        ELSE INSERT INTO files (name, dir, node_id, file_size, cr_data, wr_data, mod_data) VALUES
        (get_file_name(fpath), get_lvl_dir(new_path) + 1, new_fnode_id, (SELECT file_size FROM files WHERE files.id = file_id), now(), now(), now());
            RETURN 'OK';
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Переместить файл ---------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION move_file(fpath VARCHAR, fnode_id INT, new_path VARCHAR, new_fnode_id INT)
    RETURNS VARCHAR AS $$
DECLARE
    file_id INT;
    move_parrent_id INT;
BEGIN
    SELECT get_id(new_path, 0, new_fnode_id) INTO move_parrent_id;
    IF move_parrent_id = -1 THEN 
        RETURN 'New parent directory does not exist';
    ELSE
        SELECT get_id(fpath, 0, fnode_id) INTO file_id;
        IF file_id = -1 THEN 
            RETURN 'The file does not exist';
        ELSIF fnode_id = new_fnode_id AND get_dir(fpath) = new_path THEN 
            RETURN 'The files with this name already exists in this folder';
        ELSE UPDATE files SET dir = get_lvl_dir(new_path) + 1 , node_id = new_fnode_id, mod_data = now() WHERE files.id = file_id;
            RETURN 'OK';
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Поиск по маске с указанием глубины поиска --------------------------------------------------------
CREATE OR REPLACE FUNCTION list_files(fpath VARCHAR, fnode_id INT)
    RETURNS setof files AS $$
DECLARE
     r files%ROWTYPE;
     file_id INT;
BEGIN
    SELECT get_id(fpath, 0, fnode_id) INTO file_id;
    IF file_id != 0 AND NOT EXISTS (SELECT * FROM files WHERE files.id = file_id) THEN 
        RETURN QUERY (SELECT *FROM files);
    ELSE
        FOR r IN
            SELECT * FROM files WHERE dir > get_lvl_dir(fpath) AND node_id = fnode_id
        LOOP
            RETURN NEXT r;
        END LOOP;
        RETURN;
    END IF;
END;
$$ LANGUAGE plpgsql;


-- Проверка -----------------------------------------------------------------------------------------
SELECT add_file('new_file', 'folder1', 1, 1024, '2020-05-23', '2020-05-23');
SELECT *FROM files;

SELECT remove_file('folder1/new_file', 1);
SELECT *FROM files;

SELECT rename_file('folder1/file1', 1, 'rename_file');
SELECT *FROM files;

SELECT copy_file('file3', 3, 'folder1', 1);
SELECT *FROM files;

SELECT move_file('folder2/file2', 2, 'folder1', 1);
SELECT *FROM files;

SELECT list_files('folder1', 1);
SELECT list_files('folder11', 121);
