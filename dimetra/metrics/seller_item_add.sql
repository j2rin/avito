create fact seller_item_add as
select
    t.event_date as __date__,
    t.chain_item_confirm_time,
    t.chain_item_create_time,
    t.chain_last_form_input_time,
    t.chain_title_suggest_click_count,
    t.chain_title_suggest_show_count,
    t.chain_wizard_click_time,
    t.chain_wizard_last_click_time,
    t.cookie_id as cookie,
    t.cookie_id,
    t.event_date
from dma.vo_seller_item_add t
;

create metrics seller_item_add as
select
    sum(case when chain_wizard_click_time is not null then 1 end) as item_add_category_first_clicks,
    sum(case when chain_wizard_last_click_time is not null then 1 end) as item_add_category_last_clicks,
    sum(case when chain_item_confirm_time is not null then 1 end) as item_add_chains_confirm,
    sum(case when chain_last_form_input_time is not null then 1 end) as item_add_chains_form_input,
    sum(1) as item_chains_started,
    sum(case when chain_item_create_time is not null then 1 end) as items_created,
    sum(chain_title_suggest_click_count) as title_suggest_clicks,
    sum(chain_title_suggest_show_count) as title_suggest_shows
from seller_item_add t
;

create metrics seller_item_add_cookie as
select
    sum(case when item_add_category_first_clicks > 0 then 1 end) as users_item_add_category_first_click,
    sum(case when item_add_category_last_clicks > 0 then 1 end) as users_item_add_category_last_click,
    sum(case when item_add_chains_confirm > 0 then 1 end) as users_item_add_confirm,
    sum(case when items_created > 0 then 1 end) as users_item_add_created,
    sum(case when item_add_chains_form_input > 0 then 1 end) as users_item_add_form_input,
    sum(case when item_chains_started > 0 then 1 end) as users_item_chain_started,
    sum(case when title_suggest_clicks > 0 then 1 end) as users_title_suggest_click,
    sum(case when title_suggest_shows > 0 then 1 end) as users_title_suggest_show
from (
    select
        cookie_id, cookie,
        sum(case when chain_wizard_click_time is not null then 1 end) as item_add_category_first_clicks,
        sum(case when chain_wizard_last_click_time is not null then 1 end) as item_add_category_last_clicks,
        sum(case when chain_item_confirm_time is not null then 1 end) as item_add_chains_confirm,
        sum(case when chain_last_form_input_time is not null then 1 end) as item_add_chains_form_input,
        sum(1) as item_chains_started,
        sum(case when chain_item_create_time is not null then 1 end) as items_created,
        sum(chain_title_suggest_click_count) as title_suggest_clicks,
        sum(chain_title_suggest_show_count) as title_suggest_shows
    from seller_item_add t
    group by cookie_id, cookie
) _
;
