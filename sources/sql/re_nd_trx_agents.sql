with calendar as (
select 
    distinct
    date_trunc('month', event_date)::date as to_date,
    event_date,
    add_months(to_date, -6) as from_date 
from 
    dict.calendar
order by 1 desc
), 
hashing as (
select 
    distinct 
    c.event_date,
    trx.eid,
    trx.user_id,
    from_big_endian_64(xxhash64(to_big_endian_64(coalesce(trx.user_id, 0)) || to_big_endian_64(date_diff('day', date('2000-01-01'), c.to_date))))  as user_month_hash
from dma.re_nd_trx_stream trx 
join dma.ev_nd_trx_agents a using (user_id)
left join calendar c on date_trunc('month', trx.event_date)::date >= from_date 
    and date_trunc('month', trx.event_date)::date <= to_date
left join dma.current_locations using (Location_id)
where 1
and a.source = 'dict'
and ifnull(a.comment, '') != 'тест'
and cast(c.event_date as date) between :first_date and :last_date
)
select 
    event_date, 
    user_id,
    user_month_hash,
    sum(1) pvs,
    sum(case when eid = 8484 then 1 else 0 end)  searches,
    sum(case when eid in (8492, 8503) then 1 else 0 end) cv,
    sum(case when eid = 8498 then 1 else 0 end) bookings
from hashing
group by 1,2,3
