select
    create_date,
    ticket_id,
    coalesce(cht.user_id, 0) as user_id,
    case when cht.user_id is not null and (subject = 'Работа с объявлениями'
              or problem = 'Проблемы при подаче, активации или редактировании'
              or tags ilike '%seller_x%')
    then 1 else 0 end as helpdesk_seller_tickets,
    timestampdiff('second', create_date, first_public_comment_date) / 3600 as hours_to_reply,
    case when coalesce(close_reason, '') not in ('Спам', 'Дубль') then True else False end as is_normal,
    case when submitter_admuser_id is not null then True else False end as by_amuser,
    satisfaction_score,
    first_line,
    cht.logical_category_id_30d as logical_category_id,
    cht.logical_category_30d as logical_category,
    cht.vertical_id_30d as vertical_id,
    cht.vertical_30d as vertical,
    cht.is_asd,
    cht.user_segment_market,
    l.location_id,
    l.Region as region,
    decode(l.level, 3, l.parentlocation_id, l.location_id) as region_id,
    l.City as city,
    decode(l.level, 3, l.location_id, null) as city_id
from dma.current_helpdesk_ticket cht
left join dma.current_user_profile cup using(user_id)
left join dma.current_locations l on l.location_id = cup.top_item_location_id
where cht.user_id not in (select user_id from dma.current_user where IsTest)
    and cht.create_date::date between :first_date and :last_date
