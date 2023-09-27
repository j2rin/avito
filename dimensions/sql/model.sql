select value::varchar(64)
from (
    select public.transpose(* using parameters dimentions='cnt_cookie') over ()
    from (
        select
            app_version, vendor, type_device, os_version, os_name, model, browser, app_category, app, display_size, display_X, display_Y, browser_version, sum(cnt_cookie) as cnt_cookie
        from dma.useragent_day
        group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
    ) u
) u
where col = 'model'
group by 1
having sum(cnt_cookie) > 1000