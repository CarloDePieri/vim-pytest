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
            let l:winnr = winnr()
            execute "copen"
            if l:winnr !=# winnr()
                wincmd p
            endif
        endif
    endif
    return l:data.entries
endfunction

function! neomake#makers#ft#python#pytest() abort

    if !exists('g:pytest_xml_file')
        let s:report_file = tempname()
    else
        let s:report_file = g:pytest_xml_file
    endif

    if exists(":AirlineToggle") && exists("g:pytest_airline_enabled") && g:pytest_airline_enabled
      call airline#extensions#pytest#start()
    endif

    let maker = {
                \ 'exe': 'pytest',
                \ 'args': ['--junit-xml=' . s:report_file, '--color=no'],
                \ 'process_output': function('neomake#makers#ft#python#ProcessPytestResults')
                \}
    return maker
endfunction
