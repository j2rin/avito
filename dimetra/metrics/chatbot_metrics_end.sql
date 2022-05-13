create fact chatbot_metrics_end as
select
    t.end_flow_time::date as __date__,
    t.end_flow_time,
    t.group_name,
    t.is_support_chat,
    t.minute_end,
    t.reason_end_flow,
    t.user_id
from dma.vo_chatbot_metrics t
;

create metrics chatbot_metrics_end as
select
    sum(case when reason_end_flow = 'done' and group_name != 'auto_reply' and minute_end <= 5 and minute_end >= 1 then 1 end) as flows_end_less_1_5_minute,
    sum(case when reason_end_flow = 'done' and group_name != 'auto_reply' and minute_end <= 60 then 1 end) as flows_end_less_1_hour,
    sum(case when reason_end_flow = 'done' and group_name != 'auto_reply' and minute_end <= 1 then 1 end) as flows_end_less_1_minute,
    sum(case when reason_end_flow = 'done' and group_name != 'auto_reply' then 1 end) as flows_end_success,
    sum(case when reason_end_flow = 'interrupted' then 1 end) as flows_interrupted,
    sum(case when reason_end_flow = 'done' and group_name != 'auto_reply' and is_support_chat = True then 1 end) as support_flows_end_success
from chatbot_metrics_end t
;
