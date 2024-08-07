vim9script 

var defaults = has('multi_byte')
    ? { placeholder: '⋯', line: '▤', multiplication: '×' }
    : { placeholder: '...', line: 'L', multiplication: '*' }

g:FoldText_placeholder    = get(g:, 'FoldText_placeholder',    defaults['placeholder'])
g:FoldText_line           = get(g:, 'FoldText_line',           defaults['line'])
g:FoldText_multiplication = get(g:, 'FoldText_multiplication', defaults['multiplication'])
g:FoldText_info           = get(g:, 'FoldText_info',           1)
g:FoldText_width          = get(g:, 'FoldText_width',          0)
g:FoldText_expansion      = get(g:, 'FoldText_expansion',      "<=>")

var endBlockChars   = ['end', '}', ']', ')', '})', '},', '}}}']
var endBlockRegex = printf('^\(\s*\|\s*\"\s*\)\(%s\);\?$', join(endBlockChars, '\|'))
var endCommentRegex = '\s*\*/\s*$'
var startCommentBlankRegex = '\v^\s*/\*!?\s*$'

def GetFoldStartLineNr(): number
    var foldStartLine = v:foldstart
    while getline(foldStartLine) =~ '^\s*$'
        foldStartLine = nextnonblank(foldStartLine + 1)
    endwhile
    return foldStartLine
enddef

def FoldText(): string
    if (v:foldend == 0)
        return ''
    endif

    var foldStartLine = GetFoldStartLineNr()
    var line = getline(v:foldstart)
    if (foldStartLine <= v:foldend)
        var spaces = repeat(' ', &tabstop)
        line = substitute(getline(foldStartLine), '\t', spaces, 'g')
    endif

    var foldEnding = strpart(getline(v:foldend), indent(v:foldend), 3)

    if (foldEnding =~ endBlockRegex)
        if (foldEnding =~ '^\s*\"')
            foldEnding = strpart(getline(v:foldend), indent(v:foldend) + 2, 3)
        endif
        foldEnding = ' ' .. g:FoldText_placeholder .. ' ' .. foldEnding
    elseif (foldEnding =~ endCommentRegex)
        if (getline(v:foldstart) =~ startCommentBlankRegex)
            var nextLine = substitute(getline(v:foldstart + 1), '\v\s*\*', '', '')
            line = line .. nextLine
        endif
        foldEnding = ' ' .. g:FoldText_placeholder .. ' ' .. foldEnding
    else
        foldEnding = ' ' .. g:FoldText_placeholder
    endif
    foldEnding = substitute(foldEnding, '\s\+$', '', '')

    var signs = ''
    redir > signs | exe "silent sign place buffer=" .. bufnr('') | redir end

    var signlist = split(signs, '\n')
    var foldColumnWidth = (&foldcolumn ? &foldcolumn : 0)
    var numberColumnWidth = &number ? strwidth(string(line('$'))) : 0
    var signColumnWidth = len(signlist) >= 2 ? 2 : 0
    var width = winwidth(0) - foldColumnWidth - numberColumnWidth - signColumnWidth

    var beginning = ''
    if (g:FoldText_info)
        var foldSize = 1 + v:foldend - v:foldstart
        beginning = printf("%s", foldSize)
    endif

    var expansionWidth = width - strwidth(beginning .. line .. foldEnding)
    var expansionStr = repeat(' ', expansionWidth)
    if (expansionWidth > 2)
        var extensionCenterWidth = strwidth(g:FoldText_expansion[1 : -2])
        var remainder = (expansionWidth - 2) % extensionCenterWidth
        expansionStr = g:FoldText_expansion[0] .. repeat(g:FoldText_expansion[1 : -2], (expansionWidth - 2) / extensionCenterWidth) .. repeat(g:FoldText_expansion[-2 : -2], remainder) .. g:FoldText_expansion[-1 :]
    endif
    return beginning .. line[beginning->strcharlen() : ] .. foldEnding .. expansionStr
enddef

set foldtext=s:FoldText()
