create enrichment sfaccount as
select
    acc.SFAccount_Type as SFAccount_Type
from :fact_table t
left join (
    select
        User_id,
        max(COALESCE(SFAccount_Type, SFTopParentAccount_type))::varchar(128) as SFAccount_Type
    from DMA.salesforce_usermapping
    where COALESCE(SFAccount_Type, SFTopParentAccount_type) is not null
    group by 1
) acc on acc.User_id = t.item_user_id
;