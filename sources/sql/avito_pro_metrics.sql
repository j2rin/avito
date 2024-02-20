{\rtf1\ansi\ansicpg1251\cocoartf2757
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 select\
    pmd.user_id,\
    pmd.event_date,\
    pmd.vertical,\
    pmd.is_pro,\
    pmd.transaction_amount,\
    target_contacts,\
    case \
        when target_contacts > 0 \
        then 1\
        else 0 \
    end as seller_with_at_least_one_contact\
from DMA.avito_pro_metrics_daily pmd\
where cast(event_date as date) between :first_date and :last_date\
    --and cast(event_date as date) between :first_date and :last_date --@trino}