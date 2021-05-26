SELECT creator.login AS "creator", executor.login AS "executor"
FROM customer creator LEFT OUTER JOIN task ON (creator.id=author_id), group_users, customer executor
WHERE executor.id=group_users.user_id AND group_users.group_id=task.id AND creator.login >= executor.login 
UNION
SELECT creator.login AS "creator", executor.login AS "executor"
FROM customer creator LEFT OUTER JOIN task ON (creator.id=author_id), group_users, customer executor
WHERE executor.id=group_users.user_id AND group_users.group_id=task.id AND creator.login < executor.login;
