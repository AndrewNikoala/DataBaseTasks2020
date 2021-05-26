DROP TABLE IF EXISTS history CASCADE;
DROP TABLE IF EXISTS task;
DROP FUNCTION IF EXISTS modification();
DROP FUNCTION IF EXISTS task_history(INT);
DROP FUNCTION IF EXISTS viewing_del_tasks();

CREATE TABLE task(
    id                  SERIAL        PRIMARY KEY,
    title               VARCHAR(255),
    priority            SMALLINT,
    description         TEXT,
    status              VARCHAR(25)   CHECK (status IN ('Новая','Переоткрыта','Выполняется','Закрыта')),
    estimation_time     INTEGER,
    real_time           INTEGER,
    author_id           INTEGER,
    project_id          INTEGER
);

CREATE TABLE history(
    id                  SERIAL        PRIMARY KEY,
    task_id             INTEGER,
    title               VARCHAR(255),
    exist               BOOLEAN,
    priority            SMALLINT,
    description         TEXT,
    status              VARCHAR(25)   CHECK (status IN ('Новая','Переоткрыта','Выполняется','Закрыта')),
    estimation_time     INTEGER,
    real_time           INTEGER,
    author_id           INTEGER,
    project_id          INTEGER,
    time_change         TIMESTAMP
);

CREATE OR REPLACE FUNCTION modification() RETURNS TRIGGER AS $$
	BEGIN 
	IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN 
		INSERT INTO history (task_id, title, exist, priority, description, status, estimation_time, real_time, author_id, project_id, time_change) 
		    VALUES (NEW.id, NEW.title, true, NEW.priority, NEW.description, NEW.status, NEW.estimation_time, NEW.real_time, NEW.author_id, NEW.project_id, now());
	ELSIF TG_OP = 'DELETE' THEN 
		INSERT INTO history (task_id, title, exist, priority, description, status, estimation_time, real_time, author_id, project_id, time_change) 
		    VALUES (OLD.id, OLD.title, FALSE, OLD.priority, OLD.description, OLD.status, OLD.estimation_time, OLD.real_time,  OLD.author_id, OLD.project_id, now());
	END IF;
	RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

CREATE  TRIGGER modification_trigger
	AFTER INSERT OR UPDATE OR DELETE ON task
	FOR EACH ROW EXECUTE PROCEDURE modification();
	
-- удаление задачи
CREATE OR REPLACE FUNCTION delete_task(i INT) RETURNS VARCHAR as $$
BEGIN
    DELETE FROM task WHERE id = i;
    RETURN 'Task deleted';
END;
$$ LANGUAGE plpgsql;

-- просмотр удаленных задач
CREATE OR REPLACE FUNCTION viewing_del_tasks() RETURNS setof history as $$
BEGIN 
    RETURN QUERY
        SELECT * FROM history WHERE exist IS FALSE;
END;
$$ LANGUAGE plpgsql;

-- просмотр истории по задаче
CREATE OR REPLACE FUNCTION task_history(i INT) RETURNS setof history as $$
BEGIN 
    RETURN QUERY
        SELECT * FROM history WHERE task_id = i;
END;
$$ LANGUAGE plpgsql;


-- Добавили в историю
SELECT *FROM history;
INSERT INTO task (title, priority, description, status, estimation_time, real_time, author_id, project_id) VALUES ('task1', 1, 'task1', 'Новая', 10, 9, 1, 1);
SELECT *FROM task;
SELECT *FROM history;
-- Удалил задачу и добавили в историю
SELECT delete_task(1);
SELECT *FROM task;
SELECT *FROM history;
-- Просмотрим удаленные задачи
SELECT viewing_del_tasks();
-- Просмотр истории по отдельной задаче
SELECT task_history(1);
