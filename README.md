TODO

### Available settings

- `g:pytest_single_job_mode`: if `1` only run one pytest job at a time and
cancel the first, still running job when launching a second. Default to `1`.

- `g:pytest_open_quickfix_on_error`: if `1` open the quickfix window
in the background when a job ends with errors. Default to `1`.

- `g:pytest_close_quickfix_on_run`: if `1` close the quickfix window if open
when starting a new job.

- `g:pytest_xml_file`: the path of the xml file passed to pytest's `--junit-xml=`.
Default to a random temporary file.

- `g:pytest_airline_enabled`: if `1` shows the airline status bar. It's
undefined by default.

- `g:pytest_airline_section`: in which airline section the pytest status bar
will be appended. Good candidates are `b` or `y`. Default to `b`.

- `g:pytest_airline_separator_symbol`: the symbol used as separator in the
airline bar.

- `g:pytest_airline_icon`: the symbol used as icon, right after the separator
in the airline bar.
