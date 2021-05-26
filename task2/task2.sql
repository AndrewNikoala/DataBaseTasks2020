-- 1) Напишите запрос, который выведет трех пользователей с наивысшим средним приоритетом по всем своим 
-- задачам (задачи, где они исполнители).

SELECT customer.*, AVG(task.priority) AS "avg_priority"  
FROM customer, group_users, task 
WHERE customer.id=group_users.user_id AND task.id=group_users.group_id
GROUP BY customer.id
ORDER BY "avg_priority" DESC 
LIMIT 3;

-- 2) Напишите запрос, который выведет для каждого пользователя количество задач созданных им по месяцам
-- на 2015 год в формате: "C - M - ID", где C - количество задач, M - месяц, ID - id пользователя.

SELECT COUNT(customer.id) AS "num_of_tasks", date_part('month', project.data_start) AS "month", customer.id 
FROM customer, task, project
WHERE task.author_id=customer.id AND task.project_id=project.id AND date_part('year', project.data_start)=2015
GROUP BY customer.id, "month"
ORDER BY "month";

-- 3) Напишите запрос двумя способами (без вложенных / с вложенными подзапросов), который выведет для
-- каждого исполнителя сумму всех переработок и недоработок по задачам. Результирующая выборка должна 
-- иметь три колонки id_executor, '-', '+'.

SELECT customer.id AS "id_executor"
    ,SUM(
    CASE
    WHEN overwork.real_time - overwork.estimation_time<=0 THEN overwork.real_time - overwork.estimation_time
    ELSE NULL
    END) "-"
    ,SUM(
    CASE
    WHEN weaknesses.estimation_time - weaknesses.real_time<=0 THEN weaknesses.real_time -  weaknesses.estimation_time  
    ELSE NULL
    END) "+"
FROM customer, task overwork, task weaknesses, group_users
WHERE customer.id=group_users.user_id 
    AND group_users.group_id=overwork.id 
    AND group_users.group_id=weaknesses.id
GROUP BY id_executor
ORDER BY customer.id;

SELECT customer.id AS "id_executor"
    ,SUM(overwork.real_time - overwork.estimation_time) AS "-"
    ,SUM(weaknesses.real_time -  weaknesses.estimation_time) AS "+"
FROM customer, task overwork, task weaknesses, group_users
WHERE customer.id=group_users.user_id 
    AND group_users.group_id=overwork.id 
    AND group_users.group_id=weaknesses.id 
    AND (overwork.real_time - overwork.estimation_time) IN ( SELECT (real_time - estimation_time)
        FROM task
        WHERE real_time - estimation_time <= 0)
    AND (weaknesses.real_time -  weaknesses.estimation_time) IN ( SELECT (real_time -  estimation_time)
        FROM task
        WHERE estimation_time - real_time <= 0)
GROUP BY id_executor
ORDER BY customer.id;

-- 4) Найти все уникальные пары постановщик-исполнитель (login - login). Порядок неважен, т.е. пары 
-- petorva-ivanov и ivanov-petorva считаем одинаковыми.
-- Лексикографическаы проверка

SELECT DISTINCT
    CASE 
    WHEN creator.login >= employee.login THEN creator.login 
    ELSE employee.login
    END "login1",
    CASE WHEN creator.login >= employee.login THEN employee.login 
    ELSE creator.login
    END "login2"
FROM customer creator LEFT OUTER JOIN task ON (creator.id=author_id), group_users, customer employee
WHERE (employee.id=group_users.user_id AND group_users.group_id=task.id);

-- 5) Напишите запрос, который выводит login с наиболее длинным названием и количеством букв в нем.

SELECT customer.login, length(customer.login) AS "num_of_letters"
FROM customer
--GROUP BY customer.login
ORDER BY "num_of_letters" DESC
LIMIT 1;

-- 6) В задании 1 при создании таблиц вы столкнулись с типами данных CHAR и VARCHAR. Продемонстрируйте эффективность хранения названия данных в стоблце типа VARCHAR по сравнению с CHAR.
DROP TABLE table_char;
DROP TABLE table_varchar;

CREATE TABLE table_char
(
    id          SERIAL          PRIMARY KEY,
    str CHAR(1000000)
);

CREATE TABLE table_varchar
(
    id          SERIAL          PRIMARY KEY,
    str VARCHAR(1000000)
);

INSERT INTO table_char (str) VALUES ('aaaa');
INSERT INTO table_varchar (str) VALUES ('aaaa');

-- Для преобразования в лучший вид использую pg_size_pretty
-- pg_relation_size - объём, который занимает на диске указанный слой заданной таблицы
-- pg_total_relation_size - общий объём, который занимает на диске заданная таблица, включая все индексы и данные TOAST
-- pg_catalog содержит системные таблицы и все встроенные типы данных, функции и операторы
-- relid - OID таблицы для индекса // relname - имя таблицы для индекса

SELECT
   relname as "Table",
   pg_size_pretty(pg_total_relation_size(relid)) As "Size",
   pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) as "External Size"
   FROM pg_catalog.pg_statio_user_tables
   WHERE relname IN ('table_char','table_varchar') ORDER BY pg_total_relation_size(relid) DESC;

-- 7) Напишите запрос, который выведет для каждого пользователя задачу с максимальным приоритетом.

SELECT customer.name, MAX(task.priority)
FROM customer, task, group_users
WHERE task.id=group_users.group_id AND customer.id=group_users.user_id
GROUP BY customer.id;

-- 8) Напишите запрос, который выведет для каждого пользователя(исполнителя) суммарную оценку всех открытых задач, у которых оценка больше, чем среднестатистическая оценка по всем задачам.

SELECT customer.name, SUM(open_task.priority) AS "sum"
FROM customer, task open_task, group_users
WHERE open_task.id=group_users.group_id AND customer.id=group_users.user_id AND open_task.status!='Закрыта'
GROUP BY customer.name
HAVING SUM(open_task.priority) > AVG(open_task.priority);

-- 9) Создайте представление, которое будет выводить для каждого пользователя статистику по задачам:
-- - сколько всего задач на пользователе, сколько задач выполнено в срок, сколько было задержано;
-- - сколько открыто/ закрыто/ выполняется;
-- - суммарное потраченное время, суммарная переработка/ недоработка

DROP VIEW IF EXISTS stat_1;
CREATE VIEW stat_1 AS
SELECT customer.id, customer.name,
    (SELECT COUNT(total.group_id) AS "total"
    FROM group_users total 
    WHERE customer.id = total.user_id ),
    (SELECT COUNT(completed_task.group_id) AS "tasks on time"
    FROM group_users completed_task, task 
    WHERE customer.id = completed_task.user_id AND completed_task.group_id = task.id AND (task.estimation_time - task.real_time) >= 0 AND task.real_time IS NOT NULL),
    (SELECT COUNT(del_task.group_id) AS "on time tasks"
    FROM group_users del_task, task 
    WHERE customer.id = del_task.user_id AND del_task.group_id = task.id AND (task.estimation_time - task.real_time) < 0 AND task.real_time IS NOT NULL) AS "delayed tasks"
FROM customer
GROUP BY customer.id;

SELECT *FROM stat_1;
---------------------------------------------------------------------------------------------------------

DROP VIEW IF EXISTS stat_2;
CREATE VIEW stat_2 AS

SELECT customer.id, customer.name,
    (SELECT COUNT(open_task.group_id) AS "open task"
    FROM group_users open_task, task 
    WHERE customer.id = open_task.user_id AND open_task.group_id = task.id AND task.status != 'Закрыта'),
    (SELECT COUNT(close_task.group_id) AS "close task"
    FROM group_users close_task, task 
    WHERE customer.id = close_task.user_id AND close_task.group_id = task.id AND task.status = 'Закрыта'),
    (SELECT COUNT(exec_task.group_id) AS "execute task"
    FROM group_users exec_task, task 
    WHERE customer.id = exec_task.user_id AND exec_task.group_id = task.id AND task.status = 'Выполняется')
FROM customer
GROUP BY customer.id;

SELECT *FROM stat_2;
---------------------------------------------------------------------------------------------------------

DROP VIEW IF EXISTS stat_3;
CREATE VIEW stat_3 AS

SELECT customer.id, customer.name,
    (SELECT SUM(total.real_time) AS "total"
    FROM task total, group_users 
    WHERE customer.id = group_users.user_id AND group_users.group_id = total.id),
    (SELECT SUM(over_task.real_time - over_task.estimation_time) AS "overtime"
    FROM task over_task, group_users 
    WHERE customer.id = group_users.user_id AND group_users.group_id = over_task.id AND (over_task.real_time - over_task.estimation_time > 0) AND over_task.real_time IS NOT NULL),
    (SELECT SUM(undertime.estimation_time - undertime.real_time) AS "undertime"
    FROM task undertime, group_users 
    WHERE customer.id = group_users.user_id AND group_users.group_id = undertime.id AND (undertime.real_time - undertime.estimation_time < 0) AND undertime.real_time IS NOT NULL)
FROM customer
GROUP BY customer.id;

SELECT *FROM stat_3;

-- 10) Придумайте и напишите запрос тремя способами, который демонстрирует три типа горизонтального объединения: простое объединение, с вложенным подзапросом и с соотнесённым подзапросом.

SELECT group_users.group_id, task.title
FROM group_users, task
WHERE group_users.group_id = task.id
ORDER BY group_users.group_id;

SELECT group_users.group_id, task.title
FROM group_users, task
WHERE (group_users.group_id, task.title) IN (SELECT group_users.group_id, task.title FROM group_users, task WHERE group_users.group_id=task.id)
ORDER BY group_users.group_id;

SELECT group_users.group_id, (SELECT task.title FROM task WHERE task.id=group_users.group_id)
FROM group_users
ORDER BY group_users.group_id;

-- 3 ,6, 9, 10
