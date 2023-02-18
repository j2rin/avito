select /*+syntactic_join*/
	   event_date,
	   cookie_id,
	   user_id,
	   session_no,
	   platform_id,
	   search_suggest_clicks,
	   session_searches_with_uniq_query,
	   session_searches_with_empty_or_uniq_query,
	   sessions_with_query_suggest_click_contact,
	   sessions_with_suggest_click_and_contact,
	   suggest_user_query_len
from DMA.o_buyer_suggest ss
where event_date::date between :first_date and :last_date
