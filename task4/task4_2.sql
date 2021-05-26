SELECT task_out.id, task_out.title
FROM task task_out 
WHERE task_out.priority = (
    SELECT MAX(priority) FROM task task_int 
    WHERE task_int.author_id = task_out.author_id);
    
SELECT task_out.id, task_out.title
FROM task task_out LEFT OUTER JOIN task task_int ON task_int.author_id = task_out.author_id AND task_out.priority < task_int.priority 
WHERE task_int.author_id is NULL;
