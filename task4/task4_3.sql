-- Вывести все департаменты где нет ни одного из указанных сотрудников
-- 1) Через EXISTS
SELECT department.name 
FROM department
WHERE NOT EXISTS (SELECT customer.department_id FROM customer WHERE customer.department_id = department.id);

SELECT department.name
FROM department
WHERE id NOT IN (SELECT customer.department_id FROM customer WHERE department.id = customer.department_id);

-- 2) Через обычное объединение
SELECT department.name
FROM department
EXCEPT
SELECT department.name
FROM department, customer
WHERE department.id = customer.department_id;

-- 3) Через JOIN
SELECT department.name
FROM department LEFT OUTER JOIN customer ON customer.department_id = department.id WHERE customer.department_id IS NULL;
