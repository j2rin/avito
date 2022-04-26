create dictionary user_segment as
select user_segment
from (
    select              'Private' as user_segment
    union all   select  'Pro'
    union all   select  'ASD'
) _
;

create dictionary user_segment_market as
select  distinct segment as user_segment_market
from    dict.segmentation_ranks
;

create dictionary is_asd as
select is_asd
from (
    select              1 as is_asd
    union all   select  0
) _
;