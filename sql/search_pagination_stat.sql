create local temp table click_stream on commit preserve rows direct as (
select  weblog_id,
        urlrel_id,
       CASE
         -- Avito.ru:
         WHEN cs.apptype_id IN (2, 500010) THEN 1
         -- m.Avito.ru:
         WHEN cs.apptype_id = 4 OR (apptype_id = 5 and clientsideapp_id = 113625250001) THEN 2
         -- Android:
         WHEN cs.apptype_id IN (5, 500006) AND cs.clientsideapp_id = 3 THEN 3
         -- iOS:
         WHEN cs.apptype_id IN (5, 500006) AND cs.clientsideapp_id = 2 THEN 4
       END
       AS platform_id
from    dma.click_stream_raw cs
where   cs.eventtype_id = 10
) order by weblog_id segmented by hash(weblog_id) all nodes;


select count(*) from click_stream;


create local temp table click_stream_url on commit preserve rows direct as (
select  /*+syntactic_join*/
        cs.platform_id,
        o.OutputOffset,
        l.SearchLimit,
        cs.urlrel_id,
        cs.weblog_id
from  click_stream                     cs
left join /*+jtype(fm)*/ dds.S_WebLog_OutputOffset    o on o.WebLog_id = cs.Weblog_id
left join /*+jtype(fm)*/ dds.S_WebLog_SearchLimit     l on l.WebLog_id = cs.WebLog_id
) order by urlrel_id segmented by hash(urlrel_id) all nodes;
;

create table public.dl_search_pagination_stat as (
    select  /*+syntactic_join*/
            cs.platform_id,
            cs.OutputOffset,
            cs.SearchLimit,
            pd.External_ID as page,
            count(*) as searches
    from    click_stream_url                               cs
    left join /*+jtype(fm)*/ dds.L_UrlRel_PaginationDepth  d  on d.UrlRel_id = cs.UrlRel_id
    left join /*+jtype(fm)*/ dds.H_PaginationDepth         pd on pd.PaginationDepth_id = d.PaginationDepth_id
    group by 1, 2, 3, 4
) order by platform_id, OutputOffset, SearchLimit, page segmented by hash(platform_id, OutputOffset, SearchLimit, page) all nodes;


select  platform_id, outputoffset < 100, sum(sum(searches)) over(partition by platform_id order by sum(searches) desc) / sum(sum(searches)) over(partition by platform_id) as share_cum
from    public.dl_search_pagination_stat
group by 1, 2

select  mod(10, 2)

pd.External_ID as page,
        

select  *
from    dds.H_PaginationDepth
