from metadata import load_metrics_config, load_observations_directory
from migration import write_all_metrics_to_files, write_metrics_to_file, write_sources, get_prepared_sources
from models import *
from collections import Counter
from pathlib import Path
from ruamel.yaml import safe_load
from datetime import date, timedelta


def convert_metrics(old_metrics: List[MetricOld]):
    old_metrics[0].occupied_metric_names.update({m.name for m in old_metrics})
    all_metrics = old_metrics[0].all_metric_index
    _ = [m.make_num_counter() for m in old_metrics if m.type == 'counter']
    _ = [m.make_num_counter() for m in old_metrics]
    _ = [m.make_den_counter() for m in old_metrics if m.type == 'ratio']
    # print(len(all_metrics))
    _ = [m.make_num_uniq() for m in old_metrics if m.type == 'uniq']
    _ = [m.make_num_uniq() for m in old_metrics if m.num_type == 'uniq']
    _ = [m.make_den_uniq() for m in old_metrics if m.den_type == 'uniq']
    # print(len(all_metrics))
    all_metrics.update(m.make_ratio() for m in old_metrics if m.type == 'ratio')
    # print(len(all_metrics))
    return all_metrics


def migrate_config():
    current_date = date.today() - timedelta(days=1)
    conf = load_metrics_config(current_date)

    with open('observations.yaml', 'r') as f:
        obs_dict = safe_load(f)
    obs_dir = load_observations_directory(current_date)
    obs_from_metrics = {o for tup in conf.itertuples()
           for o in split_into_tup(tup.numerator_observations) + split_into_tup(tup.denominator_observations)}

    obs_index = make_obs_index(obs_dir, obs_dict, obs_from_metrics)
    # print('\n'.join(sorted(['{0}: {{filter: [observation_name: {0}], obs: [observation_value]}}'.format(o.name) for o in obs_index if o.source == '_'])))
    MetricOld.all_observation_index.update(obs_index)
    old_metrics = [MetricOld.from_tup(tup) for tup in conf.sort_values('metric_name').itertuples()]

    new_metrics = convert_metrics(old_metrics)

    print(Counter([m.type for m in new_metrics]))

    for om in old_metrics:
        if om.name not in new_metrics.by_name:
            print(om)

    prepared_sources = get_prepared_sources()

    ratio_metrics_from_multiple_sources = {
        m for m in new_metrics
        if m.type == 'ratio' and len(m.sources) > 1 and len(m.num.sources) == 1 and len(m.den.sources) == 1
        and m.num.source in prepared_sources and m.den.source in prepared_sources
    }

    write_metrics_to_file(ratio_metrics_from_multiple_sources, 'ratio', 'ratio')

    metrics_with_multiple_sources = {m for m in new_metrics if len(m.sources) > 1
                                     if m not in ratio_metrics_from_multiple_sources}

    metrics_with_prepared_source = {m for m in new_metrics if len(m.sources) <= 1 and m.source in prepared_sources}
    write_all_metrics_to_files(metrics_with_prepared_source)
    metrics_with_single_source = {m for m in new_metrics if len(m.sources) <= 1 and m.source not in prepared_sources}
    write_all_metrics_to_files(metrics_with_single_source, 'unprepared')
    write_all_metrics_to_files(metrics_with_multiple_sources, 'multiple_sources')

    write_sources(sorted({m.source for m in new_metrics if len(m.sources) == 1}))


if __name__ == '__main__':
    migrate_config()

    # conf = load_metrics_config('2020-04-24')
    # obs = {o for tup in conf.itertuples()
    #        for o in split_into_tup(tup.numerator_observations) + split_into_tup(tup.denominator_observations)}

    # with open('observations.yaml', 'r') as f:
    #     obs_dict = safe_load(f)
    # obs_index = make_obs_index([], obs_dict)
    # print(obs_index.dump())

