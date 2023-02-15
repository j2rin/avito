select
    bic.event_date,
    bic.participant_id cookie_id,
    bic.item_id,
    bic.platform_id,
    --
    (   bic.ph_proxy
        + bic.ph_anon
        + bic.iac
        + bic.msg_reply
        + bic.del_order
        )                                                           as c_deal,
    --
    (   bic.ph_proxy * w.ph_proxy
        + (bic.ph_anon+iac) * w.ph_anon
        + bic.msg_reply * w.msg_reply
        + bic.del_order * w.del_order
        )                                                           as c_deal_weight,
    --
    (   1 / (1 + EXP(- (zeroifnull(wl.inter)
        + zeroifnull(wl.ph_view) *
            case
            when (bic.ph_view>0 or bic.ph_chat>0) and (bic.ph_proxy=0 and bic.iac=0)
                and (bic.msg_first+bic.msg_prep+bic.msg_reply+bic.del_order=0)
                and bic.platform_id = 3
            then 1
            when (bic.ph_view>0 or bic.ph_chat>0) and (bic.ph_proxy=0 and bic.ph_anon=0 and bic.iac=0)
                and bic.platform_id = 4
            then 1
            when (bic.ph_view>0 or bic.ph_chat>0)
                and bic.platform_id in (1,2)
            then 1
            else 0
            end
        + zeroifnull(wl.ph_proxy) * decode(bic.ph_proxy>0 and (bic.ph_anon=0 and bic.iac=0),true,1,0)
        + zeroifnull(wl.ph_anon) * decode((bic.ph_anon>0 and decode(bic.platform_id=3,true,bic.ph_proxy>0,true)) or bic.iac>0,true,1,0)
        + zeroifnull(wl.msg) * decode((bic.msg_first>0 or bic.msg_prep>0) and bic.msg_reply=0,true,1,0)
        + zeroifnull(wl.msg_reply) * decode(bic.msg_reply>0,true,1,0)
        + zeroifnull(wl.del_click) * decode(bic.del_click>0 and bic.del_order=0,true,1,0)
        + zeroifnull(wl.del_order) * decode(bic.del_order>0,true,1,0)
        + zeroifnull(wl.fav) * decode(bic.fav_add-bic.fav_remove>0 or bic.share>0,true,1,0)
        ))))
                                                                    as c_deal_logit,
    --
    cm.vertical_id                                                  as vertical_id,
    cm.logical_category_id                                          as logical_category_id,
    cm.category_id                                                  as category_id,
    cm.subcategory_id                                               as subcategory_id,
    cm.Param1_microcat_id                                           as param1_id,
    cm.Param2_microcat_id                                           as param2_id,
    cm.Param3_microcat_id                                           as param3_id,
    cm.Param4_microcat_id                                           as param4_id,
    decode(cl.level, 3, cl.ParentLocation_id, cl.Location_id)       as region_id,
    decode(cl.level, 3, cl.Location_id, null)                       as city_id,
    cl.LocationGroup_id                                             as location_group_id,
    cl.City_Population_Group                                        as population_group,
    cl.Logical_Level                                                as location_level_id
from dma.buyer_item_contact bic
    join dma.current_item ci on ci.item_id=bic.item_id
    join dma.current_microcategories cm on cm.microcat_id=ci.microcat_id
    join dma.current_locations cl on cl.location_id=ci.location_id
    join dict.contact_deal_weight w
        on w.logical_category_id=cm.logical_category_id
        and w.platform_id=bic.platform_id
    join dict.contact_deal_logit wl
        on wl.logical_category_id=cm.logical_category_id
        and wl.platform_id=bic.platform_id
where bic.participant_type = 'visitor'
    and bic.event_date::date between :first_date and :last_date
