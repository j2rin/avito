select screen_name as value
from dma.performance_current_screens_content_types
where screen_name is not null group by 1 having sum(events)> 500;