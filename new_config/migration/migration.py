from models import *
from pathlib import Path
from typing import TextIO


CONFIG_PATH = Path.cwd().parent / 'migrated'


def write_metrics_type_batch(metrics: Set[Metric], typ: str, fil: TextIO):
    fil.write(f'metric.{typ}:\n')
    metrics = sorted(metrics, key=lambda x: (x.key, x.name))
    lines = [m.yaml_repr for m in metrics]
    fil.writelines(lines)
    fil.write('\n')


def write_metrics_to_file(metrics: Set[Metric], source: str, extra_path):
    filepath = CONFIG_PATH / extra_path / f'{source}.yaml'
    index_by_type = MetricIndex(metrics).by_type
    with open(filepath, 'w') as f:
        if source == 'search_stream':
            with open('ss_header.yaml', 'r') as h:
                f.write(h.read())
        types = ['counter', 'uniq', 'ratio']
        for t in types:
            m = index_by_type.get(t)
            if m:
                write_metrics_type_batch(m, t, f)


def write_all_metrics_to_files(metrics: Set[Metric], extra_path=''):
    index = MetricIndex(metrics)
    for s, m in index.by_source.items():
        write_metrics_to_file(m, s, extra_path)


def write_sources(sources: List[str]):
    with open(CONFIG_PATH / '_sources.yaml', 'w') as f:
        for source in sources:
            f.write(f'{source}:\n\tvertica:\n\t\ttable: dma.o_{source}\n\n')
