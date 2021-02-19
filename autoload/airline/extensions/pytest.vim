if !(exists(":AirlineToggle") && (!exists("g:pytest_airline_enabled") || g:pytest_airline_enabled))
  finish
endif

"
" Define some custom accents
"
function! AirlineThemePatch(palette)
  let a:palette.accents.bold_blue = [ '#0087ff', '', '33', '', 'bold' ]
  let a:palette.accents.bold_red = [ '#FF0000', '', '196', '', 'bold' ]
  let a:palette.accents.bold_green = [ '#5fff00', '', '82', '', 'bold' ]
  let a:palette.accents.bold_gray = [ '#BCBCBC', '', '250', '', 'bold' ]
endfunction
let g:airline_theme_patch_func = 'AirlineThemePatch'


function! s:wrap_accent(text, accent_name)
  call airline#highlighter#add_accent(a:accent_name)
  return "%#__accent_".(a:accent_name)."#".a:text."%#__restore__#"
endfunction

" Set starting status
let s:status = "clear"
" Set a default here for tests data
let s:test_data = {'red': 0, 'green': 0, 'skip': 0}

let s:spc = g:airline_symbols.space

" let g:

" Define the target airline section
if !exists('g:pytest_airline_section')
  let s:airline_section = "b"
else
  let s:airline_section = g:pytest_airline_section
endif

" Define the separator symbol
let s:pytest_default_left_separator_icon = ""
let s:pytest_default_right_separator_icon = ""
let s:left_sections = ['a', 'b']
if !exists('g:pytest_airline_separator_icon')
  if index(s:left_sections, s:airline_section) >= 0
    let s:separator_icon = s:pytest_default_left_separator_icon
  else
    let s:separator_icon = s:pytest_default_right_separator_icon
  endif
else
    let s:separator_icon = g:pytest_airline_separator_icon
endif

" Define the icon
if !exists('g:pytest_airline_icon')
  let s:icon = ""
else
  let s:icon = g:pytest_airline_icon
endif

" Create the heading
let s:heading = ""
if s:separator_icon != ""
  let s:heading = s:separator_icon
endif
if s:icon != ""
  if len(s:heading) > 0
    let s:heading .= s:spc
  endif
  let s:heading .= s:icon
endif


function! airline#extensions#pytest#apply(...)
  let l:bar = []

  if s:status == "running"
    " This should be called by the start function, when a test run begins
    if len(s:heading) > 0
      call add(l:bar, s:wrap_accent(s:heading, "bold_blue"))
    endif
    call add(l:bar, s:wrap_accent("running", "bold_blue"))

  elseif s:status == "done"
    " This should be called by the done function, when a test run ends
    if s:test_data.skip > 0
      let l:separator_color = "bold_gray"
      call add(l:bar, s:wrap_accent(s:test_data.skip, "bold_gray"))
    endif

    if s:test_data.green > 0
      let l:separator_color = "bold_green"
      call insert(l:bar, s:wrap_accent(s:test_data.green, "bold_green"))
    endif

    if s:test_data.red > 0
      let l:separator_color = "bold_red"
      call insert(l:bar, s:wrap_accent(s:test_data.red, "bold_red"))
    endif

    if s:test_data.red + s:test_data.green + s:test_data.skip == 0
      let l:separator_color = "bold_gray"
      call add(l:bar, s:wrap_accent("no tests", "bold_gray"))
    endif

    if len(s:heading) > 0
      call insert(l:bar, s:wrap_accent(s:heading, l:separator_color))
    endif

  elseif s:status == "stopped"
    " This should be called when cancelling jobs
    if len(s:heading) > 0
      call add(l:bar, s:wrap_accent(s:heading, "bold_gray"))
    endif
    call add(l:bar, s:wrap_accent("stopped", "bold_gray"))

  endif

  " Insert spaces between components
  let l:str_bar = ""
  for l:el in l:bar
    if index(l:bar, l:el) != 0
      let l:str_bar .= s:spc . l:el
    else
      let l:str_bar .= l:el
    endif
  endfor

  " Fix spacing for left sections
  if index(s:left_sections, s:airline_section) >= 0
    let l:str_bar = s:spc . l:str_bar
  endif

  " Update the airline section
  call airline#extensions#append_to_section(s:airline_section, l:str_bar)
endfunction


function! airline#extensions#pytest#start()
  let s:status = "running"
  call airline#extensions#pytest#apply()
  AirlineRefresh
endfunction


function! airline#extensions#pytest#done(test_data)
  let s:test_data = a:test_data
  let s:status = "done"
  call airline#extensions#pytest#apply()
  AirlineRefresh
endfunction


function! airline#extensions#pytest#stop()
  let s:status = "stopped"
  call airline#extensions#pytest#apply()
  AirlineRefresh
endfunction


function! airline#extensions#pytest#pytest_clear()
  let s:status = "clear"
  call airline#extensions#pytest#apply()
  AirlineRefresh
endfunction


function! airline#extensions#pytest#init(ext)
  call a:ext.add_statusline_func('airline#extensions#pytest#apply')
endfunction

