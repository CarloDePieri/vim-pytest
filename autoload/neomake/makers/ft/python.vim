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

function! neomake#makers#ft#python#ProcessPytestResults(context) abort
    let l:data = py3eval("parse_pytest_junit_report(vim.eval('s:report_file'))")
    if exists(":AirlineToggle") && exists("g:pytest_airline_enabled") && g:pytest_airline_enabled
        call airline#extensions#pytest#done(l:data)
    endif
    if !exists("g:pytest_open_quickfix_on_error") || g:pytest_open_quickfix_on_error
        if l:data.red > 0
            " Open the quickfix window if there are errors
            let l:winnr = winnr()
            execute "copen"
            if l:winnr !=# winnr()
                wincmd p
            endif
        else
            " Close the quickfix window if there are no errors
            execute "cclose"
        endif
    endif
    return l:data.entries
endfunction


function! neomake#makers#ft#python#pytest() abort

    if exists(":AirlineToggle") && exists("g:pytest_airline_enabled") && g:pytest_airline_enabled
      call airline#extensions#pytest#start()
    endif

    let maker = {'process_output': function('neomake#makers#ft#python#ProcessPytestResults')}

    function! maker.InitForJob(jobinfo) abort
        let maker = deepcopy(self)
        " Set dinamically the args and exe
        let maker.exe = s:exe
        let maker.args = neomake#makers#ft#python#get_args()
        return maker
    endfunction

    return maker
endfunction

if !exists('s:additional_args')
    let s:additional_args = []
endif
if !exists('s:custom_exe')
    let s:exe = "pytest"
endif

function! neomake#makers#ft#python#get_args()

    if !exists('g:pytest_xml_file')
        let s:report_file = tempname()
    else
        let s:report_file = g:pytest_xml_file
    endif

    let l:default = ['--junit-xml=' . s:report_file, '--color=no']
     
    return l:default + s:additional_args

endfunction


function! neomake#makers#ft#python#add_args(args)
    let s:additional_args += a:args
endfunction


function! neomake#makers#ft#python#reset_to_defaults()
    let s:additional_args = []
    let s:exe = "pytest"
endfunction
