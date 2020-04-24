from metadata import load_metrics_config
from migration import write_all_metrics_to_files, write_metrics_to_file, write_sources
from models import *
from collections import Counter
from pathlib import Path


def convert_metrics(old_metrics: List[MetricOld]):
    old_metrics[0].occupied_names.update({m.name for m in old_metrics})
    all_metrics = old_metrics[0].metric_index
    _ = [m.make_num_counter() for m in old_metrics if m.type == 'counter']
    _ = [m.make_num_counter() for m in old_metrics]
    _ = [m.make_den_counter() for m in old_metrics if m.type == 'ratio']
    print(len(all_metrics))
    _ = [m.make_num_uniq() for m in old_metrics if m.type == 'uniq']
    _ = [m.make_num_uniq() for m in old_metrics if m.num_type == 'uniq']
    _ = [m.make_den_uniq() for m in old_metrics if m.den_type == 'uniq']
    print(len(all_metrics))
    all_metrics.update(m.make_ratio() for m in old_metrics if m.type == 'ratio')
    print(len(all_metrics))
    return all_metrics


def migrate_config():
    from ss_observation_strings import observation_strings
    conf = load_metrics_config('2020-04-18')
    print(conf.shape)

    obs = {o for tup in conf.itertuples()
           for o in split_into_tup(tup.numerator_observations) + split_into_tup(tup.denominator_observations)}

    obs_index = make_observation_index(obs, observation_strings)
    old_metrics = [MetricOld.from_tup(tup, obs_index) for tup in conf.itertuples()]

    print(Counter([m.type for m in old_metrics]))

    new_metrics = convert_metrics(old_metrics)

    for om in old_metrics:
        if om.name not in new_metrics.by_name:
            print(om)

    ratio_metrics_from_multiple_sources = {
        m for m in new_metrics
        if m.type == 'ratio' and len(m.sources) > 1 and len(m.num.sources) <= 1 and len(m.den.sources) <= 1}

    write_metrics_to_file(ratio_metrics_from_multiple_sources, '_ratios', '')

    metrics_with_multiple_sources = {m for m in new_metrics if len(m.sources) > 1
                                     if m not in ratio_metrics_from_multiple_sources}
    metrics_with_single_source = {m for m in new_metrics if len(m.sources) <= 1}
    write_all_metrics_to_files(metrics_with_single_source)
    write_all_metrics_to_files(metrics_with_multiple_sources, 'multiple_sources')

    write_sources(sorted({m.source for m in new_metrics if len(m.sources) == 1}))


if __name__ == '__main__':
    migrate_config()
