from validate_sql import bind_sql_params


def test_bind_sql_params():
    assert (
        bind_sql_params('select :first_date from table', first_date='2022-01-01')
        == "select '2022-01-01' from table"
    )
    assert (
        bind_sql_params('select :first_date_sfx from table', first_date='2022-01-01')
        == 'select :first_date_sfx from table'
    )
