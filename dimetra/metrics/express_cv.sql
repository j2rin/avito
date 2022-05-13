create fact express_cv as
select
    t.event_date as __date__,
    t.contacts_paid_amount_express_cv,
    t.contacts_paid_express_cv,
    t.event_date,
    t.express_cv_form_open,
    t.express_cv_published,
    t.express_cv_started,
    t.express_cv_started_net,
    t.express_cv_views,
    t.user_id
from dma.vo_express_cv t
;

create metrics express_cv as
select
    sum(express_cv_form_open) as cnt_express_cv_form_open,
    sum(contacts_paid_amount_express_cv) as contacts_paid_amount_express_cv,
    sum(contacts_paid_express_cv) as contacts_paid_express_cv,
    sum(express_cv_published) as express_cv_published,
    sum(express_cv_started) as express_cv_started,
    sum(express_cv_started_net) as express_cv_started_net,
    sum(express_cv_views) as express_cv_views
from express_cv t
;
