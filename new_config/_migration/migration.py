from models import Metric
from pathlib import Path
from typing import TextIO, List
from ruamel.yaml import safe_load
import os
from itertools import groupby
import operator


CONFIG_PATH = Path.cwd()
MIGRATED_PATH = CONFIG_PATH / '../metrics'


def write_metrics_type_batch(metrics: List[Metric], typ: str, fil: TextIO, ratio=False):
    metrics = sorted(metrics, key=lambda x: (str(x.key), x.name))
    if ratio:
        lines = [m.yaml_repr.strip() + '\n' for m in metrics]
    else:
        fil.write(f'metric.{typ}:\n')
        lines = [m.yaml_repr for m in metrics]
    fil.writelines(lines)
    fil.write('\n')


def write_metrics_to_file(metrics: List[Metric], source: str, extra_path):
    source_map = {
        'new_performance': 'perf_mobile',
        'web_performance': 'perf_web',
    }
    source = source_map.get(source, source)
    os.makedirs(MIGRATED_PATH / extra_path, exist_ok=True)
    filepath = MIGRATED_PATH / extra_path / f'{source}.yaml'
    types_sorted = ['counter', 'uniq', 'ratio']
    by_type = groupby(sorted(metrics, key=lambda x: types_sorted.index(x.type)), key=operator.attrgetter('type'))
    with open(filepath, 'w') as f:
        headers_dict = {
            'buyer_stream': 'ss_header.yaml',
            'geo_loc_change': 'loc_change_header.yaml',
        }
        if source in headers_dict:
            with open(headers_dict[source], 'r') as h:
                f.write(h.read())
        for t, m in by_type:
            ratio = extra_path == 'ratio'
            if m:
                write_metrics_type_batch(list(m), t, f, ratio)


def write_all_metrics_to_files(metrics: List[Metric], extra_path=''):
    by_source = groupby(sorted(metrics, key=operator.attrgetter('source')), key=operator.attrgetter('source'))
    for s, m in by_source:
        write_metrics_to_file(list(m), s, extra_path)


def write_sources(sources: List[str]):
    with open(MIGRATED_PATH / '_sources.yaml', 'w') as f:
        for source in sources:
            f.write(f'{source}:\n\tvertica:\n\t\ttable: dma.o_{source}\n\n')


def get_prepared_sources():
    with open(CONFIG_PATH / '../sources.yaml', 'r') as f:
        sources_conf = safe_load(f)
    return set(sources_conf.keys())
