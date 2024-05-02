select
    ldap_user,
    user_hash,
    event_date,
    eid,
    case
        when eid = 9199 then exp_create_eid
        when eid = 9203 then prj_create_eid
        when eid = 9205 then prt_create_eid
        when eid = 9206 then slt_create_eid
    else null end as ref_eid,
    case
        when eid = 9199 then datediff('second', exp_create_time, dtm)
        when eid = 9203 then datediff('second', prj_create_time, dtm)
        when eid = 9205 then datediff('second', prt_create_time, dtm)
        when eid = 9206 then datediff('second', slt_create_time, dtm)
    else null end as duration
from (
    select
        ldap_user,
        user_hash,
        event_date,
        dtm,
        eid,
        lag(dtm) over (partition by ldap_user, event_date, exp_create_flag order by dtm) as exp_create_time,
        lag(eid) over (partition by ldap_user, event_date, exp_create_flag order by dtm) as exp_create_eid,
        lag(dtm) over (partition by ldap_user, event_date, prj_create_flag order by dtm) as prj_create_time,
        lag(eid) over (partition by ldap_user, event_date, prj_create_flag order by dtm) as prj_create_eid,
        lag(dtm) over (partition by ldap_user, event_date, prt_create_flag order by dtm) as prt_create_time,
        lag(eid) over (partition by ldap_user, event_date, prt_create_flag order by dtm) as prt_create_eid,
        lag(dtm) over (partition by ldap_user, event_date, slt_create_flag order by dtm) as slt_create_time,
        lag(eid) over (partition by ldap_user, event_date, slt_create_flag order by dtm) as slt_create_eid
    from (
        select
            hash(ldap_user) as user_hash,
            ldap_user,
            dtm,
            event_date,
            eid,
            case when eid in (8696, 8697, 8698, 9199) then 1 end as exp_create_flag,
            case when eid in (9200, 9201, 9202, 9203) then 1 end as prj_create_flag,
            case when eid in (8747, 9206) then 1 end as slt_create_flag,
            case when eid in (9204, 9205) then 1 end as prt_create_flag
        from DWHCS.clickstream_data_platform
        where
            1=1
        and event_date between :first_date and :last_date
        and src_id = 1746
        and eid in (
            8697, 8698, 8696, 9197, 9199, -- exp
            9200, 9201, 9202, 9203, -- project
            8747, 9206, -- portfolio
            9204, 9205  -- calendar slot
            )
        ) _
    ) _

