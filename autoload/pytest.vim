scriptencoding utf-8

" Recover user preferences
let s:close_quickfix_on_run = !exists("g:pytest_close_quickfix_on_run") || g:pytest_close_quickfix_on_run
let s:airline_enabled = exists(":AirlineToggle") && exists("g:pytest_airline_enabled") && g:pytest_airline_enabled
let s:single_job_mode = !exists("g:pytest_single_job_mode") || g:pytest_single_job_mode
let s:open_quickfix_on_error = !exists("g:pytest_open_quickfix_on_error") || g:pytest_open_quickfix_on_error

" Init the job id to 0
let s:pytest_jobs = []

" Make sure the maker file is loaded by vim
let s:plugin_path = expand('<sfile>:p:h')
let s:maker_file = s:plugin_path.'/neomake/makers/ft/python.vim'
execute "source ". s:maker_file

function! pytest#run_suite(args) abort

  if s:close_quickfix_on_run
    cclose
  endif

  " Start the airline extension
  if s:airline_enabled
    call airline#extensions#pytest#start()
  endif

  call neomake#makers#ft#python#pytest_set_exe('poetry')
  call neomake#makers#ft#python#pytest_add_args(['run', 'pytest'])
  call neomake#makers#ft#python#pytest_add_args(a:args)

  " EXECUTE WITH THE CURRENT FILE AS TARGET FILE
  " execute 'Neomake pytest'
  " call neomake#Make(1, ['pytest'])

  " Trigger the hook on NeomakeJobFinished
  augroup pytest_job_hook
      au!
      autocmd User NeomakeJobFinished call s:JobFinished()
  augroup END

  " EXECUTE WITHOUT TARGET FILE
  " execute 'Neomake! pytest'
  if s:single_job_mode
    call s:CancelPytestJobs()
  endif
  let s:pytest_jobs += neomake#Make(0, ['pytest'])

  " REMEMBER TO RESET EVERYTHING HERE
  call neomake#makers#ft#python#pytest_reset_to_defaults()
  " TODO reset neomake opening quickfix 

endfunction

" This function will get called when the maker job ends
function! s:JobFinished() abort

  let l:context = g:neomake_hook_context
  let l:jobid = l:context.jobinfo.id

  " Get the last test data
  let l:data =  neomake#makers#ft#python#pytest_get_last_test_data()

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
              wincmd p
          endif
      endif
  endif
  if l:data.red == 0
    " Close the quickfix window if there are no errors
    execute "cclose"
  endif

  " Remove the pytest job id from the list
  call s:RemoveJobById(l:jobid)

  " Remove the autogroup to disable the hook
  autocmd! pytest_job_hook
endfunction

function! pytest#CancelJobs()
  if s:airline_enabled
      call airline#extensions#pytest#stop()
  endif
  call s:CancelPytestJobs()
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
