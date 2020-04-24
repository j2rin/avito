from dataclasses import dataclass, asdict, fields, astuple, field
from typing import List, Dict, Optional, Tuple, Union, Set

EMPTY_FILTER_OR = ((),)
EMPTY_FILTER = ((), EMPTY_FILTER_OR)


def make_observation_index(obs, obs_filter_strings):
    res = ObservationIndex()
    for uk, strings in obs_filter_strings.items():
        for line in strings.split('\n'):
            f, o = line.strip(', ').split(' as ')
            f = tuple(sorted(set([ff.strip() for ff in f.split(',')])))
            res.add(Observation(o, f, uk))
    _ = [res.add(Observation(o)) for o in obs if o not in res.by_name]
    return ObservationIndex(res)


def split_into_tup(s: str) -> Tuple[str]:
    return tuple(sorted(set(e for e in s.split(',') if e)))


def make_counter_yaml(name, obs, ftr):
    name = name + ':'
    conf_components = []
    if ftr != EMPTY_FILTER:
        ftr_componetns = []
        if ftr[0]:
            common_ftr = ', '.join([f for f in ftr[0]])
            if len(ftr[0]) > 1:
                ftr_componetns.append(f'<<: [{common_ftr}]')
            else:
                ftr_componetns.append(f'<<: {common_ftr}')
        if ftr[1] != EMPTY_FILTER_OR:
            or_ftr = []
            for of in ftr[1]:
                if len(of) > 1:
                    or_ftr.append('{<<: [' + ', '.join([f for f in of]) + ']}')
                else:
                    or_ftr.append('{<<: ' + ', '.join([f for f in of]) + '}')
            ftr_componetns.append('$or: [' + ', '.join(or_ftr) + ']')
        ftr_componetns_str = ', '.join(ftr_componetns)
        conf_components.append(f'filter: {{{ftr_componetns_str}}}')
    if obs:
       conf_components.append('obs: [' + ', '.join(obs) + ']' if obs else '')
    conf_str = ', '.join(conf_components)
    return f'  {name:40} {{{conf_str}}}\n'


def make_uniq_yaml(name, counter, key):
    name = name + ':'
    counter = counter + ','
    key = ', '.join(key)
    return f'  {name:40} {{counter: {counter:32} key: [{key}]}}\n'


def make_ratio_yaml(name, num, den):
    name = name + ':'
    num = num + ','
    return f'  {name:40} {{num: {num:32} den: {den}}}\n'


@dataclass
class Metric:
    type: str
    name: str
    sources: Tuple[str, ...]
    filter: Tuple[Tuple[str, ...], Tuple[Tuple[str, ...], ...]] = None
    obs: Optional[Tuple[str, ...]] = None
    counter: 'Metric' = None
    key: Optional[Tuple[str, ...]] = None
    threshold: int = None
    num: 'Metric' = None
    den: 'Metric' = None

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
            key = [k if k != 'participant' else 'user' for k in self.key]
            return make_uniq_yaml(self.name, self.counter.name, key)
        elif self.type == 'ratio':
            return make_ratio_yaml(self.name, self.num.name, self.den.name)

    def __key(self):
        if self.type == 'counter':
            return self.filter, self.obs
        elif self.type == 'uniq':
            return self.counter, self.key, self.threshold
        elif self.type == 'ratio':
            return self.num, self.den

    def __hash__(self):
        return hash(self.__key())

    def __eq__(self, other):
        if isinstance(other, Metric):
            return self.__key() == other.__key()
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
        _ = [res.setdefault(m.filter, set()).add(m) for m in self]
        return res

    @property
    def by_obs(self):
        res = {}
        _ = [res.setdefault(m.obs, set()).add(m) for m in self]
        return res

@dataclass
class Observation:
    name: str
    filter: Tuple[str, ...] = ()
    uniq_key: Tuple[str, ...] = ()

    def __key(self):
        return self.name, self.filter, self.uniq_key

    def __hash__(self):
        return hash(self.__key())

    def __eq__(self, other):
        if isinstance(other, Observation):
            return self.__key() == other.__key()
        return NotImplemented


class ObservationIndex(Set[Observation]):
    @property
    def by_name(self):
        return {o.name: o for o in self}

    @property
    def by_filter(self):
        res = {}
        _ = [res.setdefault(o.filter, set()).add(o) for o in self]
        return res

    @property
    def merged_uniq_key(self):
        return tuple(sorted({uk for o in self for uk in o.uniq_key}))

    @property
    def names(self):
        return tuple(sorted(o.name for o in self))

    @property
    def merged_filter(self):
        common_terms = set.intersection(*[set(o.filter) for o in self if o.filter])
        filters = set()
        for o in self:
            if o.filter:
                filters.add(tuple(sorted(f for f in o.filter if f not in common_terms)))
        return tuple(sorted(common_terms)), tuple(sorted(filters))

    @property
    def is_filter_anywhere(self):
        if self:
            return max(len(o.filter) > 0 for o in self)
        return False

    def __getitem__(self, key):
        return ObservationIndex(self.by_name[k] for k in key)


def combine_uniq_key(uniq_key, old_uniq_key):
    if old_uniq_key == () and uniq_key in (('item', 'x'), ('x',)):
        return uniq_key
    else:
        return tuple(sorted(old_uniq_key))


@dataclass
class MetricOld:
    name: str
    sources: Tuple[str, ...]
    num_obs: Tuple[str, ...] = ()
    num_filter: Tuple[Tuple[str, ...], Tuple[Tuple[str, ...], ...]] = EMPTY_FILTER
    num_sources: Tuple[str, ...] = ()
    den_obs: Tuple[str, ...] = ()
    den_filter: Tuple[Tuple[str, ...], Tuple[Tuple[str, ...], ...]] = EMPTY_FILTER
    den_sources: Tuple[str, ...] = ()
    num_uniq: Tuple[str, ...] = ()
    den_uniq: Tuple[str, ...] = ()
    num_threshold: int = 0
    den_threshold: int = 0

    occupied_names = set()
    metric_index = MetricIndex()

    @property
    def type(self):
        if len(self.den_obs) > 0 or self.den_filter != EMPTY_FILTER:
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
    def from_tup(cls, tup, observation_index: ObservationIndex):
        no = observation_index[split_into_tup(tup.numerator_observations)]
        num_uniq = combine_uniq_key(no.merged_uniq_key, split_into_tup(tup.numerator_uniq))
        if no.is_filter_anywhere:
            num_obs = ()
            num_filter = no.merged_filter
        else:
            num_obs, num_filter = no.names, EMPTY_FILTER

        do = observation_index[split_into_tup(tup.denominator_observations)]
        den_uniq = combine_uniq_key(do.merged_uniq_key, split_into_tup(tup.denominator_uniq))
        if do.is_filter_anywhere:
            den_obs = ()
            den_filter = do.merged_filter
        else:
            den_obs, den_filter = do.names, EMPTY_FILTER

        if tup.date_filter:
            num_filter = (num_filter[0] + split_into_tup(tup.date_filter), num_filter[1])
            if len(den_obs) > 0 or den_filter != EMPTY_FILTER:
                den_filter = (den_filter[0] + split_into_tup(tup.date_filter), den_filter[1])

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
        )

    def make_name(self, type, obs, ftr, uniq):
        name = None
        if type == self.type:
            name = self.name
        else:
            if self.type == 'ratio':
                if '_per_' in self.name:
                    nn, dn = self.name.split('_per_')
                    if (obs, ftr, uniq) == (self.num_obs, self.num_filter, self.num_uniq):
                        name = nn
                    elif (obs, ftr, uniq) == (self.den_obs, self.den_filter, self.den_uniq):
                        name = dn
            if not name:
                if len(obs) == 1:
                    name = obs[0]
                elif not len(obs):
                    name = '_'.join([e.strip('*') for e in ftr[0] + tuple(sorted(set(ff for f in ftr[1] for ff in f)))])
                else:
                    name = '_'.join(obs)

            if len(name) > 58 and len(self.name) <= 58:
                name = self.name
            else:
                name = name[:58]

            if type == 'counter':
                name = 'cnt_' + name

            if type == 'uniq':
                if uniq in (('participant',), ()):
                    uniq = ('user',)
                else:
                    uniq = [u for u in uniq if u != 'participant']
                name = 'unq_' + '_'.join([u if u != 'participant' else 'user' for u in uniq]) + '_' + name

            nn = 0
            _name = name
            while name in self.occupied_names.union(self.metric_index.by_name):
                name = _name + '_' + str(nn)
                nn += 1
            if name == 'unq_session_buyer_target_clicks_serp_geo_sess_per_search_geo_sess_0':
                _ = 0
        return name

    def make_num_counter(self):
        m = Metric(type='counter',
                      name=self.make_name('counter', self.num_obs, self.num_filter, self.num_uniq),
                      sources=self.num_sources, obs=self.num_obs, filter=self.num_filter)
        self.metric_index.add(m)
        return m

    def make_den_counter(self):
        m = Metric(type='counter', name=self.make_name('counter', self.den_obs, self.den_filter, self.den_uniq),
                      sources=self.den_sources, obs=self.den_obs, filter=self.den_filter)
        self.metric_index.add(m)
        return m

    def make_num_uniq(self):
        m = Metric(
            type='uniq',
            name=self.make_name('uniq', self.num_obs, self.num_filter, self.num_uniq),
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
            name=self.make_name('uniq', self.den_obs, self.den_filter, self.den_uniq),
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
