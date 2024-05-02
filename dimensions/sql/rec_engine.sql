select value, value_id, cast(null as int) as value_ext_id
from dict.current_enginerecommendation
where dimension = 'rec_engine'
