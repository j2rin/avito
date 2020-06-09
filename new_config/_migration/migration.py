from models import *
from pathlib import Path
from typing import TextIO
from ruamel.yaml import safe_load
import os


CONFIG_PATH = Path.cwd()
MIGRATED_PATH = CONFIG_PATH / 'migrated'


def write_metrics_type_batch(metrics: Set[Metric], typ: str, fil: TextIO, ratio=False):
    if ratio:
        metrics = sorted(metrics, key=lambda x: (str(x.key), x.name))
        lines = [m.yaml_repr.strip() + '\n' for m in metrics]
    else:
        fil.write(f'metric.{typ}:\n')
        metrics = sorted(metrics, key=lambda x: (str(x.key), x.name))
        lines = [m.yaml_repr for m in metrics]
    fil.writelines(lines)
    fil.write('\n')


def write_metrics_to_file(metrics: Set[Metric], source: str, extra_path):
    source_map = {
        'new_performance': 'perf_mobile',
        'web_performance': 'perf_web',
    }
    source = source_map.get(source, source)
    os.makedirs(MIGRATED_PATH / extra_path, exist_ok=True)
    filepath = MIGRATED_PATH / extra_path / f'{source}.yaml'
    index_by_type = MetricIndex(metrics).by_type
    with open(filepath, 'w') as f:
        headers_dict = {
            'buyer_stream': 'ss_header.yaml',
            'geo_loc_change': 'loc_change_header.yaml',
        }
        if source in headers_dict:
            with open(headers_dict[source], 'r') as h:
                f.write(h.read())
        types = ['counter', 'uniq', 'ratio']
        for t in types:
            m = index_by_type.get(t)
            ratio = extra_path == 'ratio'
            if m:
                write_metrics_type_batch(m, t, f, ratio)


def write_all_metrics_to_files(metrics: Set[Metric], extra_path=''):
    index = MetricIndex(metrics)
    for s, m in index.by_source.items():
        write_metrics_to_file(m, s, extra_path)


def write_sources(sources: List[str]):
    with open(MIGRATED_PATH / '_sources.yaml', 'w') as f:
        for source in sources:
            f.write(f'{source}:\n\tvertica:\n\t\ttable: dma.o_{source}\n\n')


def get_prepared_sources():
    with open(CONFIG_PATH / '../sources.yaml', 'r') as f:
        sources_conf = safe_load(f)
    return set(sources_conf.keys())
