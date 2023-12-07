select
user_id,
cast(created_at as date) event_date,
max(case answer when 'Отлично' then 5 when 'Хорошо' then 4 when 'Нейтрально' then 3 when 'Плохо' then 2 when 'Ужасно' then 1 end) grade,
sum(1) obs_count,
sum(case answer when 'Отлично' then 5 when 'Хорошо' then 4 when 'Нейтрально' then 3 when 'Плохо' then 2 when 'Ужасно' then 1 end) as obs_sum_grade
from EXTERNAL_DATA.uxfeedback_answers
join dma."current_user" on External_id =
                                        -- user_id_ext::!int --@vertica
                                        -- try_cast(user_id_ext as bigint) --@trino
where question_number = 1
and cast(created_at as date) between :first_date and :last_date
group by 1,2

