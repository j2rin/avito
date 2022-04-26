create dictionary is_cookie_new as
select is_cookie_new
from (
    select              1 as is_cookie_new
    union all   select  0
) _
;
