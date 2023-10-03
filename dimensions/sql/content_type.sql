select content_type as value from dma.performance_current_screens_content_types
                              where content_type is not null group by 1 having sum(events)> 900;