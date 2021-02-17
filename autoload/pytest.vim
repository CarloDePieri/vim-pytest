scriptencoding utf-8

let s:airline_installed = &rtp =~ 'vim-airline' && exists(":AirlineToggle")
let s:vim_test_installed = &rtp =~ 'vim-test' && exists(":TestSuite")

" Recover user preferences
let s:airline_enabled = s:airline_installed && exists("g:pytest_airline_enabled") && g:pytest_airline_enabled
let s:single_job_mode = !exists("g:pytest_single_job_mode") || g:pytest_single_job_mode
let s:open_quickfix_on_error = !exists("g:pytest_open_quickfix_on_error") || g:pytest_open_quickfix_on_error
let s:close_quickfix_on_run = !exists("g:pytest_close_quickfix_on_run") || g:pytest_close_quickfix_on_run

" Init the jobid list
let s:pytest_jobs = []
let s:last_pytest_job = 0

" Make sure the maker file is loaded by vim
let s:plugin_path = expand('<sfile>:p:h')
let s:maker_file = s:plugin_path.'/neomake/makers/pytest.vim'
execute "source ". s:maker_file

" If vim-test is installed, use it
if s:vim_test_installed

  function! pytest#vimtest_custom_strategy(cmd)
    let l:exe = split(a:cmd)[0]
    let l:args = split(a:cmd)[1:]
    call pytest#run(l:exe, l:args)
  endfunction

  " Add to vim-test our custom strategy
  let g:test#custom_strategies = {'pytest_custom': function('pytest#vimtest_custom_strategy')}

  function! pytest#vimtestwrapper(target, args) abort

    let l:already_defined = {}
    let l:to_be_saved = [
      \ 'g:test#python#pytest#file_pattern',
      \ 'g:test#strategy',
      \ 'g:test#python#runner',
      \ ]

    " Save already defined variables
    for name in l:to_be_saved
      if exists(name)
        execute "let l:already_defined['" . name . "'] = " . name
      endif
    endfor

    let g:test#strategy = 'pytest_custom'
    let g:test#python#runner = 'pytest'

    if exists("g:pytest_file_pattern")
      let g:test#python#pytest#file_pattern = g:pytest_file_pattern
    endif

    if index(['suite', 'file', 'nearest'], a:target) >= 0
      call test#run(a:target, a:args)
    elseif a:target == "last"
      let l:last = split(get(g:, 'test#last_command', ""))
      let l:args = a:args

      " Avoid the repeating of --lf tag with subsequent calls
      if index(a:args, '--lf') >= 0 && index(l:last, '--lf') >= 0
        let l:args = filter(a:args, 'v:val != "--lf"')
      endif

      call test#run_last(l:args)
    else
      echom a:target . ' is not a valid target. Use one of ["suite", "file", "nearest", "last"]'
    endif

    " Restore all values we modified to their previous values
    for name in l:to_be_saved
      if has_key(l:already_defined, name)
        let l:value = get(l:already_defined, name)
        execute "let " . l:name . " = " . string(l:value)
      else
        execute "unlet " . l:name
      endif
    endfor

  endfunction

endif

function! pytest#run(exe, args) abort

  " Disable neomake quickfix open list behavior
  if len(s:pytest_jobs) == 0
    let s:neomake_defined_quickfix_behavior = get(b:, 'neomake_open_list', get(g:, 'neomake_open_list', 0))
  endif
  let g:neomake_open_list = 0

  if s:close_quickfix_on_run
    cclose
  endif

  " Start the airline extension
  if s:airline_enabled
    call airline#extensions#pytest#start()
  endif

  call neomake#makers#pytest#set_exe(a:exe)
  call neomake#makers#pytest#add_args(a:args)

  " Trigger the hook on NeomakeJobFinished
  augroup pytest_job_hook
      au!
      autocmd User NeomakeJobFinished call s:JobFinished()
  augroup END

  if s:single_job_mode
    " Stop previous jobs
    call s:CancelPytestJobs()
  endif
  let s:pytest_jobs += neomake#Make(0, ['pytest'])

  call neomake#makers#pytest#reset_to_defaults()

endfunction

" This function will get called when the maker job ends
function! s:JobFinished() abort

  let l:context = g:neomake_hook_context
  let l:jobid = l:context.jobinfo.id

  " Get the last test data
  let l:data =  neomake#makers#pytest#get_last_test_data()

  " Update the airline extension
  if s:airline_enabled
      call airline#extensions#pytest#done(l:data)
  endif

  " Manage the quickfix window
  if s:open_quickfix_on_error
    if l:data.red > 0
      " Open the quickfix window if there are errors
      let l:winnr = winnr()
      execute "copen"
      if l:winnr !=# winnr()
        execute "wincmd p"
      endif
    endif
  endif

  if l:data.red == 0
    " Close the quickfix window if there are no errors
    execute "cclose"
  endif

  " Remove the pytest job id from the list
  call s:RemoveJobById(l:jobid)

  let s:last_pytest_job = l:jobid

  call s:Cleanup()
endfunction

function! pytest#OpenRawOutput()
  " Close the quickfix window if open
  cclose

  " wait for the quickfix window to close
  sleep 100m
  redraw

  let l:data = neomake#makers#pytest#get_last_test_data()
  if len(l:data.raw) > 0
    " Open a new window below
    bel new

    " Write the raw pytest output to a file
    let l:t = tempname()
    call writefile(l:data.raw, l:t)

    " Then make it read it to the term: this way we get colors!
    " A shell session must be started after cat, or the output will be
    " truncated for some reason
    call termopen('cat '.l:t." && bash")

    " wait a bit for the terminal to open
    sleep 100m
    redraw

    " Remove the shell prompt
    setlocal modifiable
    call execute("normal! Gddgg")
    setlocal nomodifiable

    " Make the split window a little more permanent
    setlocal nomod
    setlocal nohidden
    setlocal bufhidden=
    setlocal buflisted
    execute("file pytest_" . s:last_pytest_job)

    " Map a quick way out
    nmap <buffer> q :q<cr>

    " Update the airline bar
    if exists(":AirlineToggle") 
      AirlineRefresh
    endif
  else
    echo "> No raw test output found. Run a test first!"
  endif
 endfunction

function! pytest#Clear()
  " Cancel all running jobs
  call s:CancelPytestJobs()
  " Clear the quickfix window and close it
  cexpr []
  cclose
  " Clear the airline extension
  if s:airline_enabled
    call airline#extensions#pytest#clear()
  endif
  call s:Cleanup()
endfunction

function! pytest#CancelJobs()
  if s:airline_enabled
    call airline#extensions#pytest#stop()
  endif
  call s:CancelPytestJobs()
  call s:Cleanup()
endfunction

function! s:CancelPytestJobs()
  for jobid in s:pytest_jobs
    call neomake#CancelJob(jobid)
    call s:RemoveJobById(jobid)
  endfor
endfunction

function! s:RemoveJobById(jobid)
  let l:i = index(s:pytest_jobs, a:jobid)
  call remove(s:pytest_jobs, l:i)
endfunction

function! s:Cleanup()
  " Remove the autogroup to disable possibly pending hooks
  autocmd! pytest_job_hook
  " Reset neomake quickfix opening behavior
  if len(s:pytest_jobs) == 0
    let g:neomake_open_list = s:neomake_defined_quickfix_behavior
  endif
endfunction

function! pytest#get_jobs()
  echom s:pytest_jobs
endfunction

function! pytest#toggle_errors()
    let nr = winnr("$")
    cwindow
    let nr2 = winnr("$")
    if nr == nr2
        cclose
    endif
endfunction
