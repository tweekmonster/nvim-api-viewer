let s:deprecated = 0

function! s:show_buffer() abort
  let new = 0
  let win = bufwinnr('nvim://api')
  if win == -1
    silent split nvim://api
    let new = 1
  else
    execute win 'wincmd w'
  endif
  silent setlocal bufhidden buftype=nofile filetype=help
  return new
endfunction

function! s:uadd(list, item) abort
  if index(a:list, a:item) == -1
    call add(a:list, a:item)
  endif
endfunction

function! s:format(info) abort
  for p in a:info.parameters
    if p[0] !~# 'ArrayOf'
      call s:uadd(s:var_types, p[0])
    endif
  endfor
  let out = a:info.name.'('
        \.join(map(copy(a:info.parameters), 'join(v:val, " ")'), ', ').')'
        \.' -> '.a:info.return_type

  if has_key(a:info, 'deprecated_since')
    let out .= ' [deprecated]'
  endif
  return out
endfunction

function! s:sort_key(name) abort
  let parts = split(a:name, '_')
  let prefix = []
  if parts[0] =~# 'n\?vim'
    let prefix = [parts[0]]
    let parts = parts[1:]
  endif
  return join(prefix + reverse(parts), '_')
endfunction

function! s:func_sort(a, b) abort
  let a = s:sort_key(a:a)
  let b = s:sort_key(a:b)

  if a < b
    return -1
  elseif a > b
    return 1
  endif
  return 0
endfunction

function! s:syntax() abort
  silent! syntax clear NvimApiFunc NvimApiType
  execute 'syntax keyword NvimApiFunc' join(s:seen, ' ')
  execute 'syntax match NvimApiType #\<\%('.join(s:var_types, '\|').'\)\># containedin=ALL'
  execute 'syntax keyword NvimApiVoid void ArrayOf'
  execute 'syntax match NvimApiReturnSymbol #->#'
endfunction

function! nvimapi#display(bang) abort
  if !s:show_buffer() && a:bang == s:deprecated
    call s:syntax()
    return
  endif

  %delete

  let s:deprecated = a:bang
  let s:var_types = []
  let s:seen = []
  let api = api_info()
  let functions = {}
  for item in api.functions
    let functions[item.name] = item
  endfor

  for [type_name, type_info] in items(api.types)
    $put =[type_name.'~', '']
    let funcs = []
    for [func_name, func_info] in items(functions)
      if has_key(func_info, 'deprecated_since') && !s:deprecated
        continue
      endif
      if func_name =~# '^'.type_info.prefix
        call s:uadd(s:seen, func_name)
        call s:uadd(funcs, func_name)
      endif
    endfor

    for func_name in sort(funcs, 's:func_sort')
      $put ='  '.s:format(functions[func_name])
    endfor
    $put =['']
  endfor

  $put =['Misc~', '']
  let funcs = []
  for [func_name, func_info] in items(functions)
    if has_key(func_info, 'deprecated_since') && !s:deprecated
      continue
    endif
    if index(s:seen, func_name) == -1
      call s:uadd(s:seen, func_name)
      call s:uadd(funcs, func_name)
    endif
  endfor

  for func_name in sort(funcs, 's:func_sort')
    $put ='  '.s:format(functions[func_name])
  endfor
  $put =['']

  call s:syntax()
  call cursor(1, 1)
  delete
endfunction
