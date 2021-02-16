" vim: ts=4 sw=4 et

"
" Import python library
"
let s:plugin_path = expand('<sfile>:p:h') . '/python'
python3 << EOF
import sys
import vim
sys.path.append(vim.eval('s:plugin_path'))
from lib import parse_pytest_junit_report
EOF


if !exists('s:exe')
    let s:exe = "pytest"
endif
if !exists('s:additional_args')
    let s:additional_args = []
endif
if !exists('s:last_test_data')
    let s:last_test_data = {'red': 0, 'green': 0, 'skip': 0, 'raw': ''}
endif

function! neomake#makers#ft#python#ProcessPytestResults(context) abort
    let s:last_test_data = py3eval("parse_pytest_junit_report(vim.eval('s:report_file'))")
    let s:last_test_data.raw = a:context.output
    return s:last_test_data.entries
endfunction


function! neomake#makers#ft#python#pytest() abort

    let maker = {'process_output': function('neomake#makers#ft#python#ProcessPytestResults')}

    function! maker.InitForJob(jobinfo) abort
        " No need to deepcopy here, since it's relying on external state that
        " will persist anyway: to reset, call neomake#makers#ft#python#reset_to_defaults()
        let maker = self
        " Set dinamically exe and args
        let maker.exe = s:exe
        let maker.args = neomake#makers#ft#python#pytest_get_args()
        return maker
    endfunction

    return maker
endfunction


function! neomake#makers#ft#python#pytest_set_exe(exe)
    let s:exe = a:exe
endfunction


function! neomake#makers#ft#python#pytest_get_args()

    if !exists('g:pytest_xml_file')
        let s:report_file = tempname()
    else
        let s:report_file = g:pytest_xml_file
    endif

    let l:default = ['--junit-xml=' . s:report_file]
     
    return s:additional_args + l:default

endfunction


function! neomake#makers#ft#python#pytest_add_args(args)
    let s:additional_args += a:args
endfunction


function! neomake#makers#ft#python#pytest_reset_to_defaults()
    let s:additional_args = []
    let s:exe = "pytest"
endfunction


function! neomake#makers#ft#python#pytest_get_last_test_data()
    return s:last_test_data
endfunction
