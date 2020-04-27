### Типы метрик
Метрики делятся на три типа. Каждый тип — в отдельном блоке конфига.
1. Простые каунтеры: `metric.counter`. Аргументы:
    - `filter`: условие, фильтрующее нужные строки, перед тем как их сложить
    - `obs`: колонка (или список), значения которой нужно складывать. Если не указана, то подставляется 1
2. Каунтеры уников: `metric.uniq`. Аргументы:
    - `counter`: имя каунтера из первого блока.
    - `key`: колонка (или список), уникальные значения которой мы считаем. Если не указана, то подставляется participant
    - `threshold`: порог, по которому учитываем уника при условии sum(counter) > threshold. Если не указан, то 0.
3. Ratio: `metric.ratio`. Оба аргумента — ссылки на существующие метрики из пп. 1-2.
    - `num`: числитель
    - `den`: знаменатель

### Синтаксис
|SQL|Конфиг|
|:---|:----|
|`eid in (1, 2, 3)` |`eid: [1, 2, 3]`|
|`query is null`|`query.isnull: true`|
|`query is not null`|`query.isnull: false`|
|`item_cnt between 1 and 9`|`*is_serp_small`|
|`item_vas_flags & 4 > 0`|`item_vas_flags.bit: 2`|

### Definitions
Для упрощения конфига, часто повторяющиеся конструкции можно объявить в блоке `definitions`. Объявление через &. ссылка через *

Пример:
```yaml
definitions:
  - &eid_search   [300]
  - &eid_rec      [2437, 2012, 2309]
  - &x_is_search  {x_eid: *eid_search}
  - &x_is_rec     {$or: [[x_eid: *eid_rec], [x_engine: sg-rec]]}

metric.counter:
  rec_events: {filter: *x_is_rec}
```