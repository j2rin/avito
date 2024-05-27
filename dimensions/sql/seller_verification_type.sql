with vrf_types as (
    select distinct
            cast(vrf_type as varchar(80)) as value
    from dma.verification_day
    where True
        -- and event_year is not null -- @trino
        and vrf_type is not NULL
        and vrf_status = 'verified'
    union all
    select
            cast('not_verified' as varchar(80)) as value
)
select
        value
    ,   'is_seller_verified' as parent_dimension
    ,   value != 'not_verified' as parent_value
from vrf_types
;
