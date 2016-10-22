highlight default link NvimApiFunc Function
highlight default link NvimApiType Type
highlight default link NvimApiVoid Identifier
highlight default link NvimApiReturnSymbol NonText

command! -bang NvimAPI call nvimapi#display(<bang>0)
