""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:not_prefixable_keywords = [ "import", "data", "instance", "class", "{-#", "type", "case", "do", "let", "default", "foreign", "--"]

" guess correct number of spaces to indent
" (tabs are not allowed)
function! Get_indent_string()
    return repeat(" ", 4)
endfunction

" replace tabs by spaces
function! Tab_to_spaces(text)
    return substitute(a:text, "	", Get_indent_string(), "g")
endfunction

" Wrap in :{ :} if there's more than one line
function! Wrap_if_multi(lines)
    if len(a:lines) > 1
        return [":{"] + a:lines + [":}"]
    else
        return a:lines
    endif
endfunction

" change string into array of lines
function! Lines(text)
    return split(a:text, "\n")
endfunction

" change lines back into text
function! Unlines(lines)
    if g:tidal_target == "tmux"
        " Without this, the user has to manually submit a newline each time
        " they evaluate an expression with `ctrl e`.
        return join(a:lines, "\n") . "\n"
    else
        return join(a:lines, "\n")
    endif
endfunction

" vim slime handler
function! _EscapeText_tidal(text)
    let l:lines = Lines(Tab_to_spaces(a:text))
    let l:lines = Wrap_if_multi(l:lines)
    return Unlines(l:lines)
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Mappings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if !exists("g:tidal_no_mappings") || !g:tidal_no_mappings
  if !hasmapto('<Plug>TidalConfig', 'n')
    nmap <buffer> <localleader>c <Plug>TidalConfig
  endif

  if !hasmapto('<Plug>TidalRegionSend', 'x')
    xmap <buffer> <localleader>s  <Plug>TidalRegionSend
    xmap <buffer> <c-e> <Plug>TidalRegionSend
  endif

  if !hasmapto('<Plug>TidalLineSend', 'n')
    nmap <buffer> <localleader>s  <Plug>TidalLineSend
  endif

  if !hasmapto('<Plug>TidalParagraphSend', 'n')
    nmap <buffer> <localleader>ss <Plug>TidalParagraphSend
    nmap <buffer> <c-e> <Plug>TidalParagraphSend
  endif

  imap <buffer> <c-e> <Esc><Plug>TidalParagraphSend<Esc>i<Right>

  nnoremap <buffer> <localleader>h :TidalSend1 hush'<cr>
  nnoremap <buffer> <c-h> :TidalSend1 hush'<cr>
  nnoremap <buffer> <localleader>b :TidalSend1 showBpm<cr>
  let i = 1
  while i <= 9
    execute 'nnoremap <buffer> <localleader>'.i.' :TidalSend1 silence'' '.i.'<CR>'
    execute 'nnoremap <buffer> <c-'.i.'> :TidalSend1 silence'' '.i.'<CR>'
    execute 'nnoremap <buffer> <localleader>s'.i.' :TidalPlay '.i.'<cr>'
    let i += 1
  endwhile
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Tidal mute toggle (custom)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" ステータス表示（ENTER不要・上書き）
function! TidalEchoStatus(msg) abort
  echon a:msg
endfunction

function! TidalToggle(orbit) abort
  if !exists("b:tidal_muted")
    let b:tidal_muted = {}
  endif

  if get(b:tidal_muted, a:orbit, 0)
    execute "TidalSend1 unmute " . a:orbit
    let b:tidal_muted[a:orbit] = 0
  else
    execute "TidalSend1 mute " . a:orbit
    let b:tidal_muted[a:orbit] = 1
  endif

  call TidalEchoStatus("Tidal: " . TidalMuteStatus())
endfunction

function! TidalUnmuteAll() abort
  if !exists("b:tidal_muted")
    let b:tidal_muted = {}
  endif

  execute "TidalSend1 unmuteAll"

  let i = 1
  while i <= 9
    let b:tidal_muted[i] = 0
    let i += 1
  endwhile

  call TidalEchoStatus("Tidal: " . TidalMuteStatus())
endfunction

" キーマップ（テーブル的に管理）
let s:tidal_mute_keys = {
      \ 'l': 1,
      \ 'u': 2,
      \ 'f': 3,
      \ 'i': 4,
      \ 'a': 5,
      \ 'o': 6,
      \ 'x': 7,
      \ 'c': 8,
      \ 'v': 9,
      \ }

for [key, orbit] in items(s:tidal_mute_keys)
  execute 'nnoremap <buffer> m' . key . ' :call TidalToggle(' . orbit . ')<CR>'
  execute 'nnoremap <buffer> m' . orbit . ' :call TidalToggle(' . orbit . ')<CR>'
endfor

" unmuteAll
nnoremap <buffer> me :call TidalUnmuteAll()<CR>

" 状態文字列生成
function! TidalMuteStatus() abort
  if !exists("b:tidal_muted")
    return ""
  endif

  let s = ""

  let i = 1
  while i <= 9
    if get(b:tidal_muted, i, 0)
      let s .= "●" . i . " "
    else
      let s .= "○" . i . " "
    endif
    let i += 1
  endwhile

  return s
endfunction

function! TidalShowStatus() abort
  if !exists("b:tidal_muted")
    let b:tidal_muted = {}
    let i = 1
    while i <= 9
      let b:tidal_muted[i] = 0
      let i += 1
    endwhile
  endif

  call TidalEchoStatus("Tidal: " . TidalMuteStatus())
endfunction

nnoremap <buffer> mq :call TidalShowStatus()<CR>
