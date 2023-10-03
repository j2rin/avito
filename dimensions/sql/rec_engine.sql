select value, value_id,   null::int as value_ext_id
from dict.current_enginerecommendation
where dimension = 'rec_engine'
