select platform_id, event_date, cookie_id,
    case when delay >= 0 and delay <= 10000 then delay end as delay,
    (eid_4203 is not null and eid_4233 is not null)::int as both_event,
    (eid_4203 is null and eid_4233 is not null)::int as only_click,
    (eid_4203 is not null and eid_4233 is null)::int as only_show
from (select
    platform_id, event_date, cookie_id,
    TIMESTAMPDIFF('ms',
        max(case when eid=4203 then event_time end),
        max(case when eid=4233 then event_time end))
    as delay,
    max(case when eid=4203 then 1 end) as eid_4203,
    max(case when eid=4233 then 1 end) as eid_4233
    from (select
            business_platform as platform_id,
            cookie_id,
            event_date,
            eid,
            min(event_timestamp + nvl(client_timedelta,0)*interval '1 second') as event_time
        from dwhcs.clickstream_canon
        where event_date between :first_date and :last_date
          and eid in (4203,4233)
        group by 1,2,3,4
        order by cookie_id) T
    group by 1,2,3
    )_

