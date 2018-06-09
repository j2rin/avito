create local temp table split_groups on commit preserve rows direct as (
    select  sg.ab_split_group_id,
            sg.split_group,
            sg.is_control,
            t.ab_test_ext_id
    from    dma.v_ab_split_group sg
    join    dma.v_ab_test        t  on t.ab_test_id = sg.ab_test_id
    where   t.ab_test_ext_id in (128)
) order by ab_split_group_id segmented by hash(ab_split_group_id) all nodes;


create local temp table exposures on commit preserve rows direct as (
    select  /*+syntactic_join*/
            wsg.weblog_id,
            sg.ab_split_group_id
    from
        dds.L_WebLog_AbSplitGroup wsg inner join /*+jtype(fm)*/
         split_groups sg
        on wsg.AbSplitGroup = sg.ab_split_group_id
) order by weblog_id segmented by hash(weblog_id) all nodes;

create local temp table cookies on commit preserve rows direct as (
    select  /*+syntactic_join*/
            wc.Cookie_id,
            e.ab_split_group_id,
            min(we.EventDate) as first_exposure_time
    from
        dds.S_WebLog_EventDate we  inner join /*+jtype(fm)*/
         dds.L_WebLog_Cookie wc inner join /*+jtype(fm)*/
          exposures e
         on sc.WebLog_id = e.WebLog_id
        on we.WebLog_id = e.WebLog_id
    group by 1, 2 
) order by Cookie_id segmented by hash(Cookie_id) all nodes;

create local temp table click_stream on commit preserve rows direct as (
    select  cs.*
    from    dma.click_stream_raw cs
    where   cs.eventdate::date = current_date
) order by cookie_id segmented by hash(cookie_id) all nodes;

drop table if exists public.ab_click_stream;
create table public.ab_click_stream direct as (
    select  /*+syntactic_join*/
            cs.*,
            sg.ab_split_group_id
    from
        click_stream cs inner join /*+jtype(fm)*/
         cookies sg
        on sg.cookie_id = cs.cookie_id
    where   cs.eventdate >= sg.first_exposure_time
) order by weblog_id segmented by hash(weblog_id) all nodes;

select  et.EventType_ext as eid,
        et.Slug,
        events_count,
        events_count * (cookies_count_all_sg / nullifzero(cookies_count)) / nullifzero(events_count_all_sg) as relative_bias
from (
    select  eventtype_id,
            ab_split_group_id,
            sum(1) as cookies_count,
            sum(events_count) as events_count,
            sum(sum(1)) over(partition by eventtype_id) as cookies_count_all_sg,
            sum(sum(events_count)) over(partition by eventtype_id) as events_count_all_sg,
            count(*) over(partition by eventtype_id) as split_groups_count
    from (
        select  eventtype_id,
                ab_split_group_id,
                cookie_id,
                sum(1) as events_count
        from    public.ab_mav_item_page_click_stream
        group by 1, 2, 3
    ) c
) cs
join    dma.current_eventTypes et on et.EventType_id = cs.eventtype_id
;

