from dataclasses import dataclass, asdict, fields, astuple, field
from typing import List, Dict, Optional, Tuple, Union, Set, NamedTuple, Any
from cached_property import cached_property
from ruamel.yaml import safe_dump


def make_obs_index(obs, obs_dict):
    res = ObservationIndex()
    for name, conf in obs_dict.items():
        res.add(Observation.from_conf(name, conf))
    _ = [res.add(Observation(o, obs=(o,))) for o in obs if o not in res.by_name]
    return ObservationIndex(res)


def split_into_tup(s: str) -> Tuple[str]:
    return tuple(sorted(set(e for e in s.split(',') if e)))


def dump_filter(filter):
    tup = []
    for elem in filter:
        if isinstance(elem, dict):
            elem_tup = []
            for k, v in elem.items():
                if k == '$or':
                    or_tup = []
                    for d in v:
                        or_tup.append(dump_filter(d))
                    v = ', '.join(or_tup)
                if isinstance(v, list):
                    v = safe_dump(v, default_flow_style=True, width=1024).strip('\n')
                elem_tup.append(f'{k}: {v}')
            elem_str = '{' + ', '.join(elem_tup) + '}'
            tup.append(elem_str)
        else:
            tup.append('*' + elem)
    return '[' + ', '.join(tup) + ']'


def make_counter_yaml(name, obs, ftr):
    # name = name + ':'
    # conf_components = []
    # if ftr != EMPTY_FILTER:
    #     ftr_componetns = []
    #     if ftr[0]:
    #         common_ftr = ', '.join(['*' + f for f in ftr[0]])
    #         if len(ftr[0]) > 1:
    #             ftr_componetns.append(f'<<: [{common_ftr}]')
    #         else:
    #             ftr_componetns.append(f'<<: {common_ftr}')
    #     if ftr[1] != EMPTY_FILTER_OR:
    #         or_ftr = []
    #         for of in ftr[1]:
    #             if len(of) > 1:
    #                 or_ftr.append('{<<: [' + ', '.join(['*' + f for f in of]) + ']}')
    #             else:
    #                 or_ftr.append('{<<: ' + ', '.join(['*' + f for f in of]) + '}')
    #         ftr_componetns.append('$or: [' + ', '.join(or_ftr) + ']')
    #     ftr_componetns_str = ', '.join(ftr_componetns)
    #     conf_components.append(f'filter: {{{ftr_componetns_str}}}')
    # if obs:
    #    conf_components.append('obs: [' + ', '.join(obs) + ']' if obs else '')
    # conf_str = ', '.join(conf_components)
    # return f'  {name:40} {{{conf_str}}}\n'
    d = []
    if ftr:
        d.append('filter: ' + dump_filter(ftr))
    if obs:
        d.append('obs: ' + safe_dump(obs, default_flow_style=True, width=1024).strip('\n'))
    s = '{' + ', '.join(d) + '}'
    name += ':'
    return f'  {name:40} {s}\n'


def make_uniq_yaml(name, counter, key):
    name = name + ':'
    counter = counter + ','
    key = ', '.join(key)
    return f'  {name:40} {{counter: {counter:32} key: [{key}]}}\n'


def make_ratio_yaml(name, num, den):
    name = name + ':'
    num = num + ','
    return f'  {name:40} {{num: {num:32} den: {den}}}\n'


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
    return ObsTup(filter2tup(filter), tuple(obs), tuple(key))


@dataclass
class Metric:
    type: str
    name: str
    sources: Tuple[str, ...]
    filter: List[Union[str, Dict[str, Union[int, str, bool, List[int], List[str]]]]] = field(default_factory=list)
    obs: List[str] = field(default_factory=list)
    counter: 'Metric' = None
    key: List[str] = field(default_factory=list)
    threshold: int = None
    num: 'Metric' = None
    den: 'Metric' = None

    def __post_init__(self):
        self.astuple = obs_astuple(self.filter, self.obs, self.key)
        self.__key = None
        if self.type == 'counter':
            self.__key = self.astuple.filter, self.astuple.obs
        elif self.type == 'uniq':
            self.__key = self.counter, self.astuple.key, self.threshold
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
            return make_counter_yaml(self.name, self.obs, self.filter)
        elif self.type == 'uniq':
            return make_uniq_yaml(self.name, self.counter.name, self.key)
        elif self.type == 'ratio':
            return make_ratio_yaml(self.name, self.num.name, self.den.name)

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
    name: str
    filter: List[Union[str, Dict[str, Union[int, str, bool, List[int], List[str]]]]] = field(default_factory=list)
    obs: List[str] = field(default_factory=list)
    key: List[str] = field(default_factory=list)

    def __post_init__(self):
        self.astuple = obs_astuple(self.filter, self.obs, self.key)

    @classmethod
    def from_conf(cls, name, conf):
        filter = conf.get('filter', [])
        obs = conf.get('obs', [])
        key = conf.get('key', [])
        return cls(name, filter, obs, key)

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
    def merged_aliases(self):
        return sorted([o.alias for o in self])

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
            res += ((('$or', tuple(or_terms)),),)

        return tup2filter(res)

    def __getitem__(self, key):
        return ObservationIndex(self.by_name[k] for k in key)

    def dump(self):
        return ''.join(sorted(o.dump() for o in self))


def combine_uniq_key(uniq_key, old_uniq_key):
    if len(old_uniq_key) > 0:
        return list(old_uniq_key)
    else:
        return list(uniq_key)


@dataclass
class MetricOld:
    name: str
    sources: Tuple[str, ...]
    source_num_obs: ObservationIndex
    source_den_obs: ObservationIndex
    num_obs: List[str] = field(default_factory=list)
    num_filter: List[Union[str, Dict[str, Union[int, str, bool, List[int], List[str]]]]] = field(default_factory=list)
    num_sources: Tuple[str, ...] = ()
    den_obs: List[str] = field(default_factory=list)
    den_filter: List[Union[str, Dict[str, Union[int, str, bool, List[int], List[str]]]]] = field(default_factory=list)
    den_sources: Tuple[str, ...] = ()
    num_uniq: List[str] = field(default_factory=list)
    den_uniq: List[str] = field(default_factory=list)
    num_threshold: int = 0
    den_threshold: int = 0

    occupied_names = set()
    metric_index = MetricIndex()
    observation_index = ObservationIndex()

    @property
    def type(self):
        if len(self.den_obs) > 0 or len(self.den_filter) > 0:
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

    @property
    def is_one_source(self):
        return len(self.sources) == 1

    @property
    def num_counter_key(self):
        return self.num_obs, self.num_filter, (), 0

    @property
    def den_counter_key(self):
        return self.den_obs, self.den_filter, (), 0

    @property
    def num_uniq_key(self):
        return self.num_obs, self.num_filter, self.num_uniq, self.num_threshold

    @property
    def den_uniq_key(self):
        return self.den_obs, self.den_filter, self.den_uniq, self.den_threshold

    @classmethod
    def from_tup(cls, tup):
        if tup.metric_name == 'searches_from_witcher_any':
            _ = 1
        no = cls.observation_index[split_into_tup(tup.numerator_observations)]
        num_obs = no.merged_obs
        num_uniq = combine_uniq_key(no.merged_key, split_into_tup(tup.numerator_uniq))
        num_filter = no.merged_filter

        do = cls.observation_index[split_into_tup(tup.denominator_observations)]
        den_obs = do.merged_obs
        den_uniq = combine_uniq_key(do.merged_key, split_into_tup(tup.denominator_uniq))
        den_filter = do.merged_filter

        if tup.date_filter:
            num_filter.append({'start_date.>=': 'ab_start_date'})
            if do:
                den_filter.append({'start_date.>=': 'ab_start_date'})

        return cls(
            name=tup.metric_name,
            num_obs=num_obs,
            num_filter=num_filter,
            den_obs=den_obs,
            den_filter=den_filter,
            num_uniq=num_uniq,
            den_uniq=den_uniq,
            num_threshold=tup.numerator_threshold,
            den_threshold=tup.denominator_threshold,
            sources=split_into_tup(tup.sources),
            num_sources=split_into_tup(tup.num_sources),
            den_sources=split_into_tup(tup.den_sources),
            source_num_obs=no,
            source_den_obs=do,
        )

    def make_name(self, type, obs, ftr, uniq):
        name = None
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
                if uniq in (['participant'], []):
                    name = 'unq_' + name
                else:
                    uniq = [u for u in uniq if u != 'participant']
                    name = 'unq_' + '_'.join([u for u in uniq]) + '_' + name

            nn = 0
            _name = name
            while name in self.occupied_names.union(self.metric_index.by_name):
                name = _name + '_' + str(nn)
                nn += 1
        return name

    def make_num_counter(self):
        if self.name == 'base_serp_without_query_empty':
            _ = 0
        m = Metric(type='counter',
                      name=self.make_name('counter', self.source_num_obs, self.num_filter, self.num_uniq),
                      sources=self.num_sources, obs=self.num_obs, filter=self.num_filter)
        self.metric_index.add(m)
        return m

    def make_den_counter(self):
        m = Metric(type='counter', name=self.make_name('counter', self.source_den_obs, self.den_filter, self.den_uniq),
                      sources=self.den_sources, obs=self.den_obs, filter=self.den_filter)
        self.metric_index.add(m)
        return m

    def make_num_uniq(self):
        m = Metric(
            type='uniq',
            name=self.make_name('uniq', self.source_num_obs, self.num_filter, self.num_uniq),
            sources=self.num_sources,
            counter=self.metric_index.by_self[self.make_num_counter()],
            key=self.num_uniq,
            threshold=self.num_threshold
        )
        self.metric_index.add(m)
        return m

    def make_den_uniq(self):
        m = Metric(
            type='uniq',
            name=self.make_name('uniq', self.source_den_obs, self.den_filter, self.den_uniq),
            sources=self.den_sources,
            counter=self.metric_index.by_self[self.make_den_counter()],
            key=self.den_uniq,
            threshold=self.den_threshold
        )
        self.metric_index.add(m)
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
            num=self.metric_index.by_self[num_ind],
            den=self.metric_index.by_self[den_ind],
        )
        self.metric_index.add(m)
        return m
