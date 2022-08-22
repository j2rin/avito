create fact buyer_comp as
select
    t.event_date::date as __date__,
    *
from public.vo_buyer_comp t
;

create metrics buyer_comp as
select
    sum(value_1) as wip_buyers_comp_1,
    sum(value_review_chain) as wip_buyers_comp_review_chain,
    sum(value_review_chain_marg) as wip_buyers_comp_review_chain_marg,
    sum(value_review_count) as wip_buyers_comp_review_count,
    sum(value_review_count_marg) as wip_buyers_comp_review_count_marg,
    sum(value_review_user) as wip_buyers_comp_review_user,
    sum(value_review_user_marg) as wip_buyers_comp_review_user_marg,
    sum(value_soa_chain_marg) as wip_buyers_comp_soa_chain_marg,
    sum(value_soa_count_marg) as wip_buyers_comp_soa_count_marg,
    sum(value_soa_user_marg) as wip_buyers_comp_soa_user_marg
from buyer_comp t
;
