create enrichment engine as
select
en.Name as engine
from :fact_table t
left join DDS.S_EngineRecommendation_Name en ON en.EngineRecommendation_id = t.rec_engine_id
;