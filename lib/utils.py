import re
from datetime import date

PARAM_REGEXP = r'(\:{param})\b'


def bind_sql_params(sql, **params):
    for name, value in params.items():
        if isinstance(value, (str, date)):
            value = f"'{value}'"
        pattern = PARAM_REGEXP.format(param=name)
        sql = re.sub(pattern, value, sql)
    return sql


def get_missing_sql_params(sql, required_params):
    missing = []
    for param in required_params:
        pattern = PARAM_REGEXP.format(param=param)
        match = re.findall(pattern, sql)
        if not match:
            missing.append(param)
    return missing


# заимстовавано из dwh-tools
def split_statements(query):
    previous_char = None
    next_char = None
    is_in_comment = False
    comment_char = None
    is_in_string = False
    string_char = None
    escape_char = None

    statements = []
    letters = 0
    start = 0
    for index in range(0, len(query)):

        char = query[index]
        if index > 0:
            previous_char = query[index - 1]
        if index < len(query) - 1:
            next_char = query[index + 1]

        # flush escape char if it was
        if previous_char == escape_char:
            escape_char = None

        # set escape char if not escaped
        if char == '\\' and escape_char is None:
            escape_char = char
            letters += 1
            continue

        # it's in string, go to next char
        if (
            escape_char is None
            and (char == "'" or char == '"')
            and not is_in_string
            and not is_in_comment
        ):
            is_in_string = True
            string_char = char
            letters += 1
            continue

        # it's comment, go to next char
        if (
            (
                (char == '#' and next_char == ' ')
                or (char == '-' and next_char == '-')
                or (char == '/' and next_char == '*')
            )
            and not is_in_string
            and not is_in_comment
        ):
            is_in_comment = True
            comment_char = char
            continue

        # it's end of comment, go to next
        if is_in_comment and (
            ((comment_char == '#' or comment_char == '-') and char == '\n')
            or (comment_char == '/' and (previous_char == '*' and char == '/'))
        ):
            is_in_comment = False
            comment_char = None
            continue

        # string closed, go to next char
        if escape_char is None and char == string_char and is_in_string:
            is_in_string = False
            string_char = None
            letters += 1
            continue

        # it's a query, continue until you get delimiter hit
        if char.lower() == ';' and not is_in_string and not is_in_comment and letters:
            statements.append(query[start:index].strip())
            start = index + 1
            letters = 0
        elif not char.isspace() and not is_in_comment:
            letters += 1

    if letters and query[start : len(query)].strip():
        statements.append(query[start : len(query)].strip())
    return statements
