
if &rtp =~ 'vim-test' && exists(":TestSuite")
  " If vim-test is installed, use it
  command! -nargs=* -bar Pytest call pytest#vimtestwrapper('suite', split(<q-args>))
  command! -nargs=* -bar PytestNearest call pytest#vimtestwrapper('nearest', split(<q-args>))
  command! -nargs=* -bar PytestFile call pytest#vimtestwrapper('file', split(<q-args>))
  command! -nargs=* -bar PytestLast call pytest#vimtestwrapper("last", split(<q-args>))
  command! -nargs=* -bar PytestLastFailed call pytest#vimtestwrapper("last", ['--lf'] + split(<q-args>))

  " Define the file-pattern to be used by vim-test
  let g:pytest_file_pattern = '\v(.*)\.(py)$'
else
  " Fallback to simpler command
  command! -nargs=* -bar Pytest call pytest#run('pytest', split(<q-args>))
endif

command! -bar PytestToggleErrors call pytest#toggle_errors()
command! -bar PytestOutput call pytest#OpenRawOutput()

command! -bar PytestStop call pytest#CancelJobs()
command! -bar PytestClear call pytest#Clear()

