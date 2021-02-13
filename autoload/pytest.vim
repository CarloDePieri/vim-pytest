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

" Make sure the maker file is loaded
let s:plugin_path = expand('<sfile>:p:h')
let s:maker_file = s:plugin_path.'/neomake/makers/ft/python.vim'
execute "source ". s:maker_file

function! pytest#run_suite(args) abort

  " Start the airline extension
  if exists(":AirlineToggle") && exists("g:pytest_airline_enabled") && g:pytest_airline_enabled
    call airline#extensions#pytest#start()
  endif

  call neomake#makers#ft#python#pytest_set_exe('poetry')
  call neomake#makers#ft#python#pytest_add_args(['run', 'pytest'])
  call neomake#makers#ft#python#pytest_add_args(a:args)

  " EXECUTE WITH THE CURRENT FILE AS TARGET FILE
  " execute 'Neomake pytest'
  " call neomake#Make(1, ['pytest'])

  " EXECUTE WITHOUT TARGET FILE
  " execute 'Neomake! pytest'
  call neomake#Make(0, ['pytest'])

  " This function will get called when the maker job ends
  function! s:JobFinished() abort

    " Get the last test data
    let l:data =  neomake#makers#ft#python#pytest_get_last_test_data()

    " Update the airline extension
    if exists(":AirlineToggle") && exists("g:pytest_airline_enabled") && g:pytest_airline_enabled
        call airline#extensions#pytest#done(l:data)
    endif

    " Manage the quickfix window
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

    " Remove the autogroup to disable the hook
    autocmd! pytest_job_hook
  endfunction

  " Trigger the hook on NeomakeJobFinished
  augroup pytest_job_hook
      au!
      autocmd User NeomakeJobFinished call s:JobFinished()
  augroup END

  " REMEMBER TO RESET EVERYTHING HERE
  call neomake#makers#ft#python#pytest_reset_to_defaults()
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
