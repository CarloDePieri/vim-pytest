[![Maintenance](https://img.shields.io/maintenance/yes/2023)](https://github.com/CarloDePieri/pymailtm/)

My current setup for python TDD with [pytest](https://docs.pytest.org/en/latest/)
from vim.

Its features:

- a custom [neomake](https://github.com/neomake/neomake) runner that will run
pytest **asynchronously**, parse the results and fill the quickfix window with
**jumpable** failed tests `A`. Failing lines will be highlighted in the gutter `B`
and the exception will be printed `C`
- a dedicated [airline](https://github.com/vim-airline/vim-airline) extension `D`,
that will reflect tests status and results
- smart test selection and venv recognition, powered by [vim-test](https://github.com/vim-test/vim-test/)
- since it does not depends on pytest stdout, it's compatible with plugins that modify
it. Plugins that modify the junit output could still pose a problem.

[pytest-spec](https://pypi.org/project/pytest-spec/)

<img src="https://user-images.githubusercontent.com/5459291/108346515-c0ba1b80-71df-11eb-9757-02dc9811a045.png" width="400">

## Dependencies and Installation

The only real dependency here is [neomake](https://github.com/neomake/neomake),
which is needed to actually launch tests.

For the pretty status bar, [airline](https://github.com/vim-airline/vim-airline)
must also be installed.

Having [vim-test](https://github.com/vim-test/vim-test/) installed will enable
the smart test selection and the venv awareness.

This is an example using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
" Needed 
Plug 'neomake/neomake'
" Optionals
Plug 'vim-airline/vim-airline'
Plug 'vim-test/vim-test'
" The actual plugin
Plug 'CarloDePieri/vim-pytest'
```

The neomake runner relies on a modern junit output file; this means that either
a recent version of pytest must be used (`>=6`) or, if using previous versions, the
`junit_family` must be set to `xunit2`, like this:

```ini
# pytest.ini
[pytest]
junit_family=xunit2
```

## Usage

Installing vim-test will change the available commands. Each command that
launch tests accepts pytest arguments (for example `-m mymark`).

#### Without vim-test

| Command | Description |
|---------|-------------|
| `:Pytest` | Run the whole test suite, using `pytest` as executable.<br/>You don't need to be in a test file for this to work. |

#### With vim-test

| Command | Description |
|---------|-------------|
| `:Pytest` | Run the whole test suite.<br/>Will also be venv aware, and will try to detect Poetry or Pipenv, using `poetry run pytest` or `pipenv run pytest` if found, respectively. |
| `:PytestFile` | Run tests from the currently open python test file.<br/>If you also have [vim-projectionist](https://github.com/tpope/vim-projectionist) installed and configured and are in a source file, this command will try to run the alternate file tests. |
| `:PytestNearest` | Run the test(/s) nearest to the cursor in the test file. So:<br/> - if the cursor is inside a test, it will run that test<br/>- if it's on a test class, it will run all tests of that class<br/>- if the cursor is somewhere in the file, it will run the whole file |
| `:PytestLast` | Re-run the last launched tests. |
| `:PytestLastFailed` | Re-run only the failed tests from the last test run. |

#### Misc

These commands are always available.

| Command | Description |
|---------|-------------|
| `:PytestOutput` | Open a terminal split buffer with the colored raw output from the last test run. Usefull to inspect a whole error stacktrace. |
| `:PytestToggleError` | Toggle the quickfix window with the failed tests entries. |
| `:PytestStop` | Halt the currently running test run. |
| `:PytestClean` | Halt all currently running test runs, clear the quickfix window and the airline statusbar. | 

## Configuration

### Mappings

This plugin does not come with custom mappings, but here are my personal ones with
the relative mnemonics.

```vim
" launch <T>est <S>uite
nnoremap <leader>ts     :w\|Pytest<CR>
" launch <T>est <F>ile
nnoremap <leader>tf     :w\|PytestFile<CR>
" launch <T>est <N>earest
nnoremap <leader>tn     :w\|PytestNearest<CR>
" launch <T>est <R>epeat
nnoremap <leader>tr     :w\|PytestLast<CR>
" relaunch <T>est last failed (<X>)
nnoremap <leader>tx     :w\|PytestLastFailed<CR>
" <T>oggle <T>est results
nnoremap <leader>tt     :w\|PytestToggleError<CR>
" open <T>est <O>utput
nnoremap <leader>to     :w\|PytestOutput<CR>

" Mappings useful for navigating the quickfix window (even with only one
" entry)
nnoremap ]q :<C-R>=len(getqflist())==1?"cc":"cn"<CR><CR>
nnoremap [q :<C-R>=len(getqflist())==1?"cc":"cp"<CR><CR>
```

### Available settings

| Name | Default | Description |
|------|---------|-------------|
| `g:pytest_single_job_mode`| `1` | Only run one pytest job at a time.<br/>Cancel the first, still running job when launching a second one. |
| `g:pytest_open_quickfix_on_error` | `1` | Open the quickfix window in the background when a job ends with errors. |
| `g:pytest_close_quickfix_on_run` | `1` | Close the quickfix window if open when starting a new job. |
| `g:pytest_xml_file` | random temporary file | The path of the xml file passed to pytest's `--junit-xml=`. |
| `g:pytest_airline_enabled` | `1` | Show the airline status bar. |
| `g:pytest_airline_section` | `b` | The airline section the pytest status bar will be appended to.<br/>Good candidates are `b` or `y`. |
| `g:pytest_airline_separator_icons` | [``, ``] | The symbols used as separator in the airline bar. |
| `g:pytest_airline_icon` | `` | The symbol(s) used as icon, right after the separator in the airline bar. |
