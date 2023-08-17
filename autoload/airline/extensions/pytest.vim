if !(exists(":AirlineToggle") && (!exists("g:pytest_airline_enabled") || g:pytest_airline_enabled))
  finish
endif

" Set starting status
let s:status = "clear"
" Set a default here for tests data
let s:test_data = {'red': 0, 'green': 0, 'skip': 0}

" Define the heading icon
if !exists('g:pytest_airline_icon')
  let s:airline_icon = ""
else
  let s:airline_icon = g:pytest_airline_icon
endif

" Define the target airline section
if !exists('g:pytest_airline_section')
  let s:airline_section = "b"
else
  let s:airline_section = g:pytest_airline_section
endif

" Define the separators
if !exists("g:pytest_airline_separator_icons")
  let s:airline_separators = [g:airline_left_alt_sep, g:airline_right_alt_sep]
else
  let s:airline_separators = g:pytest_airline_separator_icons
endif
if index(["a", "b", "c"], s:airline_section) >= 0
  let s:airline_separator = s:airline_separators[0]
else
  let s:airline_separator = s:airline_separators[1]
endif

let s:spc = g:airline_symbols.space

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

"
" Wrap the given `text` in a `accent_name` color.
"
function! s:wrap_accent(text, accent_name)
  call airline#highlighter#add_accent(a:accent_name)
  return "%#__accent_".(a:accent_name)."#".a:text."%#__restore__#"
endfunction

"
" Update this plugin target airline section, appending a separator (with
" `separator_accent` color), the icon and the given `raw_text`.
"
function! s:update_airline_section(raw_text, separator_accent)

  " Get the current window override for the target section, if present, otherwise create it
  exec "let w:airline_section_".s:airline_section." = get(w:, 'airline_section_".s:airline_section."', g:airline_section_".s:airline_section.")"

  if a:raw_text != ""

    " Prepare the heading
    let l:heading = s:spc.s:wrap_accent(s:airline_separator.s:spc.s:airline_icon, a:separator_accent).s:spc

    " Update the target section with the correct separator and given raw text
    exec "let w:airline_section_".s:airline_section." .= '".l:heading."'.'".a:raw_text."'"

  else

    " Clear the pytest part
    exec "let w:airline_section_".s:airline_section." .= ''"

  endif

endfunction

"
" Quick wrapper to set the airline section to the current status, colored with
" `accent`.
"
function! s:update_airline_section_with_colored_status(accent)
    call s:update_airline_section(s:wrap_accent('%{"'.s:status.'"}', a:accent), a:accent)
endfunction

"
" This function will be called by the general plugin to register the airline
" statusline function.
"
function! airline#extensions#pytest#init(ext)
  call a:ext.add_statusline_func('airline#extensions#pytest#apply')
endfunction

"
" This is the function that actually updates the status line. It gets called
" every time `AirlineRefresh` is called.
"
function! airline#extensions#pytest#apply(...)
  if s:status == "clear"

    call s:update_airline_section("", "")

  elseif s:status == "running"

    call s:update_airline_section_with_colored_status("bold_blue")

  elseif s:status == "stopped"

    call s:update_airline_section_with_colored_status("bold_gray")

  else
    " s:status == 'done'
    
    if s:test_data.red + s:test_data.green + s:test_data.skip == 0

      call s:update_airline_section(s:wrap_accent('%{"no tests"}', "bold_gray"), "bold_gray")

    else

      let l:results = ""

      if s:test_data.skip > 0
        let l:separator_accent = "bold_gray"
        let l:results = s:wrap_accent('%{"'.s:test_data.skip.'"}', l:separator_accent).s:spc.l:results
      endif

      if s:test_data.green > 0
        let l:separator_accent = "bold_green"
        let l:results = s:wrap_accent('%{"'.s:test_data.green.'"}', l:separator_accent).s:spc.l:results
      endif

      if s:test_data.red > 0
        let l:separator_accent = "bold_red"
        let l:results = s:wrap_accent('%{"'.s:test_data.red.'"}', l:separator_accent).s:spc.l:results
      endif

      call s:update_airline_section(l:results, l:separator_accent)
    endif
    
  endif
endfunction

"
" Called by the plugin when a pytest run is started.
"
function! airline#extensions#pytest#start()
  let s:status = "running"
  AirlineRefresh
  AirlineRefresh  " The second refresh is needed to force the correct color
endfunction

"
" Called by the plugin when a pytest run is completed. `test_data` is the
" suite results.
"
function! airline#extensions#pytest#done(test_data)
  let s:test_data = a:test_data
  let s:status = "done"
  AirlineRefresh
  AirlineRefresh  " The second refresh is needed to force the correct color
endfunction

"
" Called by the plugin when a pytest run is manually interrupted.
"
function! airline#extensions#pytest#stop()
  let s:status = "stopped"
  AirlineRefresh
  AirlineRefresh  " The second refresh is needed to force the correct color
endfunction

"
" Function used to clear the pytest airline plugin.
"
function! airline#extensions#pytest#clear()
  let s:status = "clear"
  AirlineRefresh
endfunction

