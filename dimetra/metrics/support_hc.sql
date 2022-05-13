create fact support_hc as
select
    t.event_date::date as __date__,
    t.article_views,
    t.cookie_id,
    t.end_on_article_sessions,
    t.event_date,
    t.helpcenter_article_dislike,
    t.helpcenter_article_like,
    t.helpcenter_phone_moder_block_requests,
    t.helpcenter_phone_moder_reject_requests,
    t.helpcenter_phone_requests,
    t.helpcenter_sessions,
    t.invoice_nw_article_sessions,
    t.nw_article_views,
    t.only_invoice_sessions,
    t.only_nw_article_sessions,
    t.target_sessions,
    t.wizard_sessions
from dma.vo_support_hc_metrics t
;

create metrics support_hc as
select
    sum(helpcenter_article_dislike) as support_article_dislike,
    sum(helpcenter_article_like) as support_article_like,
    sum(ifnull(helpcenter_article_dislike, 0) + ifnull(helpcenter_article_like, 0)) as support_article_marks,
    sum(article_views) as support_article_views,
    sum(end_on_article_sessions) as support_end_on_article_sessions,
    sum(helpcenter_phone_requests) as support_helpcenter_phone_requests,
    sum(helpcenter_phone_moder_block_requests) as support_helpcenter_phone_requests_block,
    sum(ifnull(helpcenter_phone_moder_block_requests, 0) + ifnull(helpcenter_phone_moder_reject_requests, 0)) as support_helpcenter_phone_requests_moder,
    sum(helpcenter_phone_moder_reject_requests) as support_helpcenter_phone_requests_reject,
    sum(helpcenter_sessions) as support_helpcenter_sessions,
    sum(invoice_nw_article_sessions) as support_invoice_nw_article_sessions,
    sum(nw_article_views) as support_nw_article_views,
    sum(only_invoice_sessions) as support_only_invoice_sessions,
    sum(only_nw_article_sessions) as support_only_nw_article_sessions,
    sum(target_sessions) as support_target_sessions,
    sum(wizard_sessions) as support_wizard_sessions
from support_hc t
;
