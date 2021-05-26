-- 1) Все сотрудники делающие задачи
SELECT customer.name, group_users.group_id
FROM customer INNER JOIN group_users ON customer.id = group_users.user_id;

-- 2) Все сотрудники делающие и не делающие задачи
SELECT customer.name, group_users.group_id
FROM customer LEFT OUTER JOIN group_users ON customer.id = group_users.user_id;

-- 3) Все задачи (могут быть без сотрудников)
SELECT customer.name, group_users.group_id
FROM customer RIGHT OUTER JOIN group_users ON customer.id = group_users.user_id;

-- 4) LEFT and RIGHT
SELECT customer.name, group_users.group_id
FROM customer FULL OUTER JOIN group_users ON customer.id = group_users.user_id;

-- 5) Сотрудники невыполняющие задачи
SELECT customer.name, group_users.group_id
FROM customer LEFT OUTER JOIN group_users ON customer.id = group_users.user_id WHERE group_users.user_id IS NULL;

-- 6) Все задачи без сотрудников
SELECT customer.name, group_users.group_id
FROM customer RIGHT OUTER JOIN group_users ON customer.id = group_users.user_id WHERE group_users.user_id IS NULL;

-- 7) Все задачи без сотрудников + сотрудники невыполняющие задачи
SELECT customer.name, group_users.group_id
FROM customer FULL OUTER JOIN group_users ON customer.id = group_users.user_id WHERE customer.id is NULL OR group_users.user_id IS NULL;
