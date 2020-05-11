from dataclasses import dataclass, asdict, fields, astuple, field
from typing import List, Dict, Optional, Tuple, Union, Set, NamedTuple, Any
from cached_property import cached_property
from ruamel.yaml import safe_dump


def make_obs_index(obs_directory, obs_dict, obs_from_metrics_conf):
    res = ObservationIndex()
    for source, obs in obs_dict.items():
        for name, conf in obs.items():
            res.add(Observation.from_conf(source, name, conf))
    _ = [res.add(Observation(t.source, t.obs, obs=[t.obs]))
         for t in obs_directory.itertuples() if t.obs not in res.by_name]
    _ = [res.add(Observation('_', o, obs=[o]))
         for o in obs_from_metrics_conf if o not in res.by_name]
    return ObservationIndex(res)


def split_into_tup(s: str) -> Tuple[str]:
    return tuple(sorted(set(e for e in s.split(',') if e)))


def dump_filter(filter, append_star=True):
    tup = []
    for elem in filter:
        if isinstance(elem, dict):
            elem_tup = []
            for k, v in elem.items():
                if isinstance(v, str) and v.isnumeric():
                    v = "'{}'".format(v)
                if k == '$or':
                    or_tup = []
                    for d in v:
                        or_tup.append(dump_filter(d))
                    v = '[' + ', '.join(sorted(or_tup)) + ']'
                if isinstance(v, list):
                    v = safe_dump(v, default_flow_style=True, width=1024).strip('\n')
                elem_tup.append(f'{k}: {v}')
            elem_str = '{' + ', '.join(elem_tup) + '}'
            tup.append(elem_str)
        else:
            elem_str = '*' + elem if append_star else elem
            tup.append(elem_str)
    return '[' + ', '.join(tup) + ']'


def make_counter_yaml(name, obs, ftr, m42=True):
    d = []
    if ftr:
        d.append('filter: ' + dump_filter(ftr))
    if obs:
        d.append('obs: ' + safe_dump(obs, default_flow_style=True, width=1024).strip('\n'))
    if not m42:
        d.append('m42: False')
    s = '{' + ', '.join(d) + '}'
    name += ':'
    return f'  {name:40} {s}\n'


def make_uniq_yaml(name, counter, key, m42=True):
    d = []
    counter += ','
    key = dump_filter(key, False)
    d.append(f'counter: {counter:32} key: {key}')
    if not m42:
        d.append('m42: False')
    s = '{' + ', '.join(d) + '}'
    name += ':'
    return f'  {name:40} {s}\n'


def make_ratio_yaml(name, num, den, m42=True):
    d = []
    num = num + ','
    d.append(f'num: {num:32} den: {den}')
    if not m42:
        d.append('m42: False')
    s = '{' + ', '.join(d) + '}'
    name = name + ':'
    return f'  {name:40} {s}\n'


def filter2tup(filter):
    tup = []
    for elem in filter:
        if isinstance(elem, dict):
            elem_tup = []
            for k, v in elem.items():
                if k == '$or':
                    or_tup = []
                    for d in v:
                        or_tup.append(filter2tup(d))
                    v = tuple(or_tup)
                if isinstance(v, list):
                    v = tuple(v)
                elem_tup.append((k, v))
            tup.append(tuple(elem_tup))
        else:
            tup.append(elem)
    return tuple(sorted(tup, key=str))


def tup2filter(tup):
    filter = []
    for elem in tup:
        if isinstance(elem, Tuple):
            elem_dict = {}
            for k, v in elem:
                if k == '$or':
                    or_list = []
                    for d in v:
                        or_list.append(tup2filter(d))
                    v = or_list
                if isinstance(v, Tuple):
                    v = list(v)
                elem_dict[k] = v
            filter.append(elem_dict)
        else:
            filter.append(elem)
    return filter


class ObsTup(NamedTuple):
    filter: Tuple[Union[str, Tuple[Union[int, str, Tuple[Union[str, int]]], ...]], ...] = ()
    obs: Tuple[str, ...] = ()
    key: Tuple[str, ...] = ()


def obs_astuple(filter, obs, key):
    return ObsTup(filter2tup(filter), tuple(obs), filter2tup(key))


@dataclass
class Metric:
    type: str
    name: str
    sources: List[str]
    filter: List[Union[str, Dict[str, Union[int, str, bool, List[int], List[str]]]]] = field(default_factory=list)
    obs: List[str] = field(default_factory=list)
    counter: 'Metric' = None
    key: List[Dict[str, int]] = field(default_factory=list)
    num: 'Metric' = None
    den: 'Metric' = None

    @property
    def m42(self):
        return self.name in MetricOld.occupied_metric_names

    def __post_init__(self):
        self.astuple = obs_astuple(self.filter, self.obs, self.key)
        self.__key = None
        if self.type == 'counter':
            self.__key = self.astuple.filter, self.astuple.obs
        elif self.type == 'uniq':
            self.__key = self.counter, self.astuple.key
        elif self.type == 'ratio':
            self.__key = self.num, self.den

    @property
    def source(self):
        res = '__'.join(self.sources)
        res = res.replace('_metric_observation', '')
        res = res.replace('_metric_observartion', '')
        res = res.replace('_observations', '')
        res = res.replace('_observation', '')
        return res

    @property
    def yaml_repr(self):
        if self.type == 'counter':
            if self.name == 'radius_short_searches':
                _ = 0
            return make_counter_yaml(self.name, self.obs, self.filter, self.m42)
        elif self.type == 'uniq':
            return make_uniq_yaml(self.name, self.counter.name, self.key, self.m42)
        elif self.type == 'ratio':
            return make_ratio_yaml(self.name, self.num.name, self.den.name, self.m42)

    def __hash__(self):
        return hash(self.__key)

    def __eq__(self, other):
        if isinstance(other, Metric):
            return self.__key == other.__key
        return NotImplemented


class MetricIndex(Set):

    @property
    def by_name(self):
        return {m.name: m for m in self}

    @property
    def by_self(self):
        return {m: m for m in self}

    @property
    def by_source(self):
        res = {}
        _ = [res.setdefault(m.source, set()).add(m) for m in self]
        return res

    @property
    def by_type(self):
        res = {}
        _ = [res.setdefault(m.type, set()).add(m) for m in self]
        return res

    @property
    def by_filter(self):
        res = {}
        _ = [res.setdefault(m.astuple.filter, set()).add(m) for m in self]
        return res

    @property
    def by_obs(self):
        res = {}
        _ = [res.setdefault(m.astuple.obs, set()).add(m) for m in self]
        return res


@dataclass
class Observation:
    source: str
    name: str
    filter: List[Union[str, Dict[str, Union[int, str, bool, List[int], List[str]]]]] = field(default_factory=list)
    obs: List[str] = field(default_factory=list)
    key: List[str] = field(default_factory=list)

    def __post_init__(self):
        self.astuple = obs_astuple(self.filter, self.obs, self.key)

    @classmethod
    def from_conf(cls, source, name, conf):
        filter = conf.get('filter', [])
        obs = conf.get('obs', [])
        key = conf.get('key', [])
        return cls(source, name, filter, obs, key)

    def __key(self):
        return self.name, self.astuple

    def __hash__(self):
        return hash(self.__key())

    def __eq__(self, other):
        if isinstance(other, Observation):
            return self.__key() == other.__key()
        return NotImplemented

    def asdict(self):
        d = {}
        if self.filter:
            d['filter'] = self.filter
        if self.obs:
            d['obs'] = self.obs
        if self.key:
            d['key'] = self.key
        return d

    def dump(self):
        s = safe_dump(self.asdict(), default_flow_style=True, width=1024)
        return f'{self.name}: {s}'

    @cached_property
    def alias(self):
        m = {
            'phone_views': 'ph',
            'phone_views_total': 'ph',
            'item_views': 'iv',
            'delivery_orders_created': 'dlv',
            'delivery_order_created': 'dlv',
            'buyer_target_clicks': 'btc',
            'booking_created_short_rent': 'book',
            'first_messages': 'fmsg',
            'searches': 's',
            'search': 's',
            'delivery': 'dlv',
            'item_view': 'iv',
            'phone_view': 'ph',
            'fav_added': 'fav',
            'witcher': 'wtc',
            'contact': 'c',
            'regions': 'reg',
            'serp': 's',
            'district': 'distr',
        }
        a = m.get(self.name, self.name)
        for n in m:
            if n in a:
                a = a.replace(n, m[n])
        return a


class ObservationIndex(Set[Observation]):

    @property
    def by_name(self):
        return {o.name: o for o in self}

    @property
    def by_filter(self):
        res = {}
        _ = [res.setdefault(o.astuple.filter, set()).add(o) for o in self]
        return res

    @property
    def merged_sources(self):
        return sorted({o.source for o in self})

    @property
    def merged_aliases(self):
        return sorted({o.alias for o in self})

    @property
    def merged_key(self):
        return sorted({uk for o in self for uk in o.key})

    @property
    def merged_obs(self):
        return sorted({oname for o in self for oname in o.obs})

    @property
    def merged_filter(self):
        res = tuple()
        if not self or min(o.filter == [] for o in self):
            return []
        common_terms = set.intersection(*[set(o.astuple.filter) for o in self if o.filter])
        res += tuple(sorted(common_terms, key=str))

        or_terms = set()
        for o in self:
            t = tuple(f for f in o.astuple.filter if f not in common_terms)
            if t:
                or_terms.add(t)
        if or_terms:
            res += ((('$or', tuple(sorted(or_terms, key=str))),),)

        return tup2filter(res)

    def __getitem__(self, key):
        return ObservationIndex(self.by_name[k] for k in key)

    def dump(self):
        return ''.join(sorted(o.dump() for o in self))


def combine_uniq_key(uniq_key, old_uniq_key, threshold: int):
    if len(old_uniq_key) > 1:
        key = [k for k in old_uniq_key if k != 'participant']
    elif len(old_uniq_key) == 1:
        key = old_uniq_key
    else:
        key = uniq_key
    if len(key) > 0:
        key_name = '_'.join(key)
        return [{key_name: threshold}] if threshold > 0 else [key_name]
    else:
        return []


@dataclass
class MetricOld:
    name: str
    num_obs_index: ObservationIndex
    den_obs_index: ObservationIndex
    obs_index: ObservationIndex
    num_uniq: List[Dict[str, int]] = field(default_factory=list)
    den_uniq: List[Dict[str, int]] = field(default_factory=list)
    date_filter: str = None

    occupied_metric_names = set()
    all_metric_index = MetricIndex()
    all_observation_index = ObservationIndex()

    @property
    def sources(self):
        return self.obs_index.merged_sources

    @property
    def num_obs(self):
        return self.num_obs_index.merged_obs

    @property
    def den_obs(self):
        return self.den_obs_index.merged_obs

    @cached_property
    def num_filter(self):
        f = self.num_obs_index.merged_filter
        if self.date_filter:
            f.append({'start_date.>=': '$ab_start_date'})
        return f

    @cached_property
    def den_filter(self):
        f = self.den_obs_index.merged_filter
        if self.date_filter and f:
            f.append({'start_date.>=': '$ab_start_date'})
        return f

    @property
    def num_sources(self):
        return self.num_obs_index.merged_sources

    @property
    def den_sources(self):
        return self.den_obs_index.merged_sources

    @property
    def type(self):
        if len(self.den_obs_index) > 0:
            return 'ratio'
        elif len(self.num_uniq) > 0:
            return 'uniq'
        else:
            return 'counter'

    @property
    def num_type(self):
        if len(self.num_uniq) > 0:
            return 'uniq'
        else:
            return 'counter'

    @property
    def den_type(self):
        if len(self.den_uniq) > 0:
            return 'uniq'
        else:
            return 'counter'

    @classmethod
    def from_tup(cls, tup):
        no = cls.all_observation_index[split_into_tup(tup.numerator_observations)]
        num_uniq = combine_uniq_key(no.merged_key, split_into_tup(tup.numerator_uniq), tup.numerator_threshold)
        do = cls.all_observation_index[split_into_tup(tup.denominator_observations)]
        den_uniq = combine_uniq_key(do.merged_key, split_into_tup(tup.denominator_uniq), tup.denominator_threshold)
        return cls(
            name=tup.metric_name,
            num_uniq=num_uniq,
            den_uniq=den_uniq,
            num_obs_index=no,
            den_obs_index=do,
            obs_index=ObservationIndex(no.union(do)),
            date_filter=tup.date_filter,
        )

    def make_name(self, type, obs, ftr, uniq):
        if type == self.type:
            name = self.name
        else:
            tokens = [t for n in obs.merged_aliases for t in n.split('_')]
            tokens_nodups = []
            _ = [tokens_nodups.append(t) for t in tokens if t not in tokens_nodups]
            name = '_'.join(tokens_nodups)

            if len(name) > 58 and len(self.name) <= 58:
                if self.type == 'ratio':
                    if '_per_' in self.name:
                        nn, dn = self.name.split('_per_')
                        if (obs.merged_obs, ftr, uniq) == (self.num_obs, self.num_filter, self.num_uniq):
                            name = nn
                        elif (obs.merged_obs, ftr, uniq) == (self.den_obs, self.den_filter, self.den_uniq):
                            name = dn
                else:
                    name = self.name
                if len(name) > 58:
                    name = name[:58]

            if type == 'counter':
                name = 'cnt_' + name

            if type == 'uniq':
                uniq_key_name = list(uniq[0])[0] if isinstance(uniq[0], dict) else uniq[0]
                if uniq_key_name == 'participant':
                    name = 'unq_' + name
                else:
                    name = 'unq_' + uniq_key_name + '_' + name

            nn = 0
            _name = name
            while name in self.occupied_metric_names.union(self.all_metric_index.by_name):
                name = _name + '_' + str(nn)
                nn += 1
        return name

    def make_num_counter(self):
        type = 'counter'
        name = self.make_name(type, self.num_obs_index, self.num_filter, self.num_uniq)
        m = Metric(type=type,
                   name=name,
                   sources=self.num_sources, obs=self.num_obs, filter=self.num_filter)
        # if name == 'radius_short_searches':
        #     print(m.filter)
        self.all_metric_index.add(m)
        return m

    def make_den_counter(self):
        type = 'counter'
        name = self.make_name(type, self.den_obs_index, self.den_filter, self.den_uniq)
        m = Metric(type=type, name=name,
                   sources=self.den_sources, obs=self.den_obs, filter=self.den_filter)
        self.all_metric_index.add(m)
        return m

    def make_num_uniq(self):
        type = 'uniq'
        name = self.make_name(type, self.num_obs_index, self.num_filter, self.num_uniq)
        m = Metric(
            type=type,
            name=name,
            sources=self.num_sources,
            counter=self.all_metric_index.by_self[self.make_num_counter()],
            key=self.num_uniq,
        )
        self.all_metric_index.add(m)
        return m

    def make_den_uniq(self):
        type = 'uniq'
        name = self.make_name(type, self.den_obs_index, self.den_filter, self.den_uniq)
        m = Metric(
            type=type,
            name=name,
            sources=self.den_sources,
            counter=self.all_metric_index.by_self[self.make_den_counter()],
            key=self.den_uniq,
        )
        self.all_metric_index.add(m)
        return m

    def make_ratio(self):
        num_ind = self.make_num_counter() if self.num_type == 'counter'\
            else self.make_num_uniq()
        den_ind = self.make_den_counter() if self.den_type == 'counter'\
            else self.make_den_uniq()
        m = Metric(
            type='ratio',
            name=self.name,
            sources=self.sources,
            num=self.all_metric_index.by_self[num_ind],
            den=self.all_metric_index.by_self[den_ind],
        )
        self.all_metric_index.add(m)
        return m
