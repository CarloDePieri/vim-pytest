" Add the neomake pytest maker
" TODO do not force this, should be a settings or a doc
" let g:neomake_python_enabled_makers = map(neomake#GetEnabledMakers('python'), 'v:val.name') + ['pytest']

" Make available a quick command
command! -nargs=* -bar Pytest call pytest#run_suite([<f-args>])

command! -bar PytestToggleErrors call pytest#toggle_errors()

command! -bar PytestStop call pytest#CancelJobs()

command! -bar PytestClear call pytest#Clear()

command! -bar PytestOutput call pytest#OpenRawOutput()
