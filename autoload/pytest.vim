scriptencoding utf-8

let s:status_file = "/tmp/status"
let g:_pytest_status_file = tempname()

function! pytest#get_status() abort
  if filereadable(g:_pytest_status_file)
    let content = readfile(s:status_file, '', 1)
    return printf("%s", content)
  else
    return printf("nothing")
  endif
endfunction


function! pytest#run_suite(args) abort

  " THIS WORKS
  " let g:pytest_xml_file = tempname()
  " let g:neomake_python_pytest_args = ['--junit-xml='.g:pytest_xml_file, 'tests/test_mai:n.py::test_should_work']
  " let g:neomake_python_pytest_args = neomake#makers#ft#python#pytest().args + ['tests/test_main.py::test_should_work']
  " echom a:args

  " EXECUTE WITH THE CURRENT FILE AS TARGET FILE
  " execute 'Neomake pytest'
  " call neomake#Make(1, ['pytest'])

  " EXECUTE WITHOUT TARGET FILE
  " execute 'Neomake! pytest'
  call neomake#Make(0, ['pytest'])

  " REMEMBER TO RESET THIS IF NEEDED
  " unlet g:neomake_python_pytest_args
  " TODO reset neomake opening quickfix 

endfunction


function! pytest#toggle_errors()
    let nr = winnr("$")
    cwindow
    let nr2 = winnr("$")
    if nr == nr2
        cclose
    endif
endfunction
