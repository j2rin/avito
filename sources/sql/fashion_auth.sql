with item_checks as (
select 
    ich.item_id,
    ich.AuthCheck_id,
    ch.Status as status,
    ch.Actual_date as actual_time,
    date(ch.actual_date) as event_date,
    param1,
    param2,
    ci.user_id
from DDS.L_Item_AuthCheck ich
join DDS.S_AuthCheck_Status ch
    on ich.AuthCheck_id = ch.AuthCheck_id
join dma.current_item ci on ich.item_Id = ci.item_id
where date(ch.actual_date) between :first_date and :last_date
),
first_check as (
select 
    min(ch.Actual_date) as min_check_time,
    ci.user_id
from DDS.L_Item_AuthCheck ich
join DDS.S_AuthCheck_Status ch
    on ich.AuthCheck_id = ch.AuthCheck_id
join dma.current_item ci on ich.item_Id = ci.item_id
where status in ('verified', 'fake', 'declined_unknown')
group by 2
),
first_check_id as (
select distinct ci.user_id, ch.AuthCheck_id
from DDS.L_Item_AuthCheck ich
join DDS.S_AuthCheck_Status ch
    on ich.AuthCheck_id = ch.AuthCheck_id
join dma.current_item ci on ich.item_Id = ci.item_id
join first_check fc on fc. user_id = ci.user_id and ch.actual_date = min_check_time
where status in ('verified', 'fake', 'declined_unknown')
),
total_auth as (
select item_id, 
       ic.AuthCheck_id, 
       ic.status, 
       event_date, 
       param1, 
       param2, 
       ic.user_id,
       case when fc.user_id is null or fci.AuthCheck_id is not null then 'first' else 'second+' end as is_first_auth,
       case when param1 in ('Аксессуары') then 'Accessories'
            when param1 in ('Женская обувь', 'Мужская обувь') then 'Shoes'
            when param1 in ('Женская одежда', 'Мужская одежда') then 'Clothes'
            when param1 in ('Сумки, рюкзаки и чемоданы') then 'Bags' end as auth_category
from item_checks ic
left join first_check fc on ic.user_id = fc.user_id and actual_time > min_check_time
left join first_check_id fci on ic.user_id = fci.user_id and fci.AuthCheck_id = ic.AuthCheck_id
),
total as (
select * from total_auth
union all
select cai.item_id, 
       null as AuthCheck_id, 
       'item_new' as status, 
       date(StartTime) as event_date, 
       ci.param1, 
       ci.param2, 
       ci.user_id,
       case when fc.user_id is null then 'first' else 'second+' end as is_first_auth,
       case when ci.param1 in ('Аксессуары') then 'Accessories'
            when ci.param1 in ('Женская обувь', 'Мужская обувь') then 'Shoes'
            when ci.param1 in ('Женская одежда', 'Мужская одежда') then 'Clothes'
            when ci.param1 in ('Сумки, рюкзаки и чемоданы') then 'Bags' end as auth_category
from dma.current_auth_item cai
join dma.current_item ci on ci.item_id = cai.item_id
left join first_check fc on fc.user_id = cai.user_id and ci.StartTime > fc.min_check_time
where true 
and lg_category not in ('not_defined') 
and brand_name not in ('Adidas', 'Asics', 'Armani Exchange',
                  'Adidas Originals', 'New Balance', 
                  'Lee', 'Lacoste', 'Oakley',
                  'Dr Martens', 'Carhartt', 
                  'Vans', 'Nike', 'UGG', 
                  'Converse', 'Salomon', 'Adidas By Stella McCartney', 
                  'The North Face', 'Under Armour', 'Champion', 'Stone Island', 'Moncler')
and price between 5000 and 150000
and rating >= 4
and reviews_cnt >= 4 
and frod_reviews_share <= 0.1 
and is_verif 
and isDeliveryActive
and date(StartTime) between :first_date and :last_date
)
select * from total