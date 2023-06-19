select
user_id,
created_at::date event_date,
avg(decode(answer,'Отлично',5,'Хорошо',4,'Нейтрально',3,'Плохо',2,'Ужасно',1)) grade,
sum(1) obs_value
from EXTERNAL_DATA.uxfeedback_answers
join dma.current_user on External_id = user_id_ext::!int
where question_number = 1
and created_at::date between :first_date and :last_date
group by 1,2

