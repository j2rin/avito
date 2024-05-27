select distinct
        vrf_type value
from dma.verification_day
where True
    -- and event_year is not null -- @trino
    and vrf_type is not NULL
    and vrf_status = 'verified'
union all
select
        'not_verified' value
;

