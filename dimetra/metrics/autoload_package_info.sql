create fact autoload_package_info as
select
    t.event_date as __date__,
    t.add_attempt_items,
    t.add_success_items,
    t.add_time_spent_for_success_sec,
    t.add_total_attempts,
    t.add_total_success_attempts,
    t.alarm_items,
    t.autoload_package,
    t.deactivate_attempt_items,
    t.deactivate_success_items,
    t.deactivate_total_attempts,
    t.deactivate_total_success_attempts,
    t.deactivate_total_time_spent_for_success_sec,
    t.error_items,
    t.event_date,
    t.no_touch_items,
    t.reactivate_attempt_items,
    t.reactivate_success_items,
    t.reactivate_total_attempts,
    t.reactivate_total_success_attempts,
    t.reactivate_total_time_spent_for_success_sec,
    t.success_validation_items,
    t.update_attempt_items,
    t.update_success_items,
    t.update_total_attempts,
    t.update_total_success_attempts,
    t.update_total_time_spent_for_success_sec,
    t.user_id,
    t.validation_alarms,
    t.validation_end,
    t.validation_errors,
    t.validation_warnings,
    t.warning_items
from dma.autoload_feed_item_flow t
;

create metrics autoload_package_info as
select
    sum(add_time_spent_for_success_sec) as autoload_add_total_time_sec,
    sum(case when validation_end is not null then alarm_items end) as autoload_alarm_validation_items,
    sum(deactivate_total_time_spent_for_success_sec) as autoload_deactivate_total_time_sec,
    sum(case when validation_end is not null then error_items end) as autoload_error_validation_items,
    sum(case when validation_end is not null then no_touch_items end) as autoload_feed_validation_items_out_of_action,
    sum(add_attempt_items) as autoload_item_add_attempt_items,
    sum(add_total_attempts) as autoload_item_add_attempts,
    sum(add_total_success_attempts) as autoload_item_add_success,
    sum(add_success_items) as autoload_item_add_success_items,
    sum(deactivate_attempt_items) as autoload_item_deactivate_attempt_items,
    sum(deactivate_total_attempts) as autoload_item_deactivate_attempts,
    sum(deactivate_total_success_attempts) as autoload_item_deactivate_success,
    sum(deactivate_success_items) as autoload_item_deactivate_success_items,
    sum(reactivate_attempt_items) as autoload_item_reactivate_attempt_items,
    sum(reactivate_total_attempts) as autoload_item_reactivate_attempts,
    sum(reactivate_total_success_attempts) as autoload_item_reactivate_success,
    sum(reactivate_success_items) as autoload_item_reactivate_success_items,
    sum(update_attempt_items) as autoload_item_update_attempt_items,
    sum(update_total_attempts) as autoload_item_update_attempts,
    sum(update_total_success_attempts) as autoload_item_update_success,
    sum(update_success_items) as autoload_item_update_success_items,
    sum(reactivate_total_time_spent_for_success_sec) as autoload_reactivate_total_time_sec,
    sum(case when validation_end is not null then success_validation_items end) as autoload_success_validation_items,
    sum(update_total_time_spent_for_success_sec) as autoload_update_total_time_sec,
    sum(case when validation_end is not null then validation_alarms end) as autoload_validation_alarms,
    sum(case when validation_end is not null then validation_errors end) as autoload_validation_errors,
    sum(case when validation_end is not null then 1 end) as autoload_validation_packages_cnt,
    sum(case when validation_end is not null then validation_warnings end) as autoload_validation_warnings,
    sum(case when validation_end is not null then warning_items end) as autoload_warning_validation_items
from autoload_package_info t
;

create metrics autoload_package_info_user_id as
select
    sum(case when autoload_item_add_attempts > 0 then 1 end) as autoload_item_add_users,
    sum(case when autoload_item_deactivate_attempts > 0 then 1 end) as autoload_item_deactivate_users,
    sum(case when autoload_item_reactivate_attempts > 0 then 1 end) as autoload_item_reactivate_users,
    sum(case when autoload_item_update_attempts > 0 then 1 end) as autoload_item_update_users,
    sum(case when autoload_validation_packages_cnt > 0 then 1 end) as autoload_validation_users
from (
    select
        user_id, user_id,
        sum(add_total_attempts) as autoload_item_add_attempts,
        sum(deactivate_total_attempts) as autoload_item_deactivate_attempts,
        sum(reactivate_total_attempts) as autoload_item_reactivate_attempts,
        sum(update_total_attempts) as autoload_item_update_attempts,
        sum(case when validation_end is not null then 1 end) as autoload_validation_packages_cnt
    from autoload_package_info t
    group by user_id, user_id
) _
;

create metrics autoload_package_info_autoload_package as
select
    sum(case when autoload_validation_packages_cnt > 0 then 1 end) as autoload_validation_feeds
from (
    select
        user_id, autoload_package,
        sum(case when validation_end is not null then 1 end) as autoload_validation_packages_cnt
    from autoload_package_info t
    group by user_id, autoload_package
) _
;
