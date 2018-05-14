import pandas as pd


def filter_df_by_df(df_to_filter, filter_df, exclude=False):
    """Отфильтровать df с помощью другого df."""
    keys = filter_df.columns.tolist()
    ind_to_ftr = df_to_filter.set_index(keys).index
    ftr_ind = filter_df.set_index(keys).index
    ftr = ind_to_ftr.isin(ftr_ind)
    if exclude:
        ftr = ~ftr
    return df_to_filter[ftr]


def filter_df_by_dict(df_to_filter, filter_dict, exclude=False):
    """Отфильтровать df с помощью дикта."""
    filter_df = pd.DataFrame(filter_dict, index=[0])
    return filter_df_by_df(df_to_filter, filter_df, exclude)
