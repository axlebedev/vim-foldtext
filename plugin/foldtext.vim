vim9script 

var defaults = has('multi_byte')
    ? { placeholder: '⋯', countFormat: '•%s•' }
    : { placeholder: '...', countFormat: '[%s]' }

g:FoldText_placeholder    = get(g:, 'FoldText_placeholder', defaults['placeholder'])
g:FoldText_showCount      = get(g:, 'FoldText_showCount',   true)
g:FoldText_countFormat = get(g:, 'FoldText_countFormat', defaults['countFormat'])

var END_BLOCK_CHARS   = ['end', '}', ']', ')', '})', '},', '}}}']
var END_BLOCK_REGEX = printf('^\(\s*\|\s*\"\s*\)\(%s\);\?$', join(END_BLOCK_CHARS, '\|'))
var END_COMMENT_REGEX = '\s*\*/\s*$'
var START_COMMENT_BLANK_REGEX = '\v^\s*/\*!?\s*$'

# Get linenumber of first non-blank line in fold
def GetFoldStartLineNr(): number
    var foldStartLine = v:foldstart
    while getline(foldStartLine) =~ '^\s*$'
        foldStartLine = nextnonblank(foldStartLine + 1)
    endwhile
    return foldStartLine
enddef

# Return inner width of current window, without numberColumn, sign, etc.
def GetWidth(): number
    var signs = ''
    redir =>> signs | exe "silent sign place buffer=" .. bufnr('') | redir END
    var signlist = split(signs, '\n')

    var foldColumnWidth = (&foldcolumn ? &foldcolumn : 0)
    var numberColumnWidth = &number ? strwidth(string(line('$'))) : 0
    var signColumnWidth = len(signlist) >= 2 ? 2 : 0
    var width = winwidth(0) - foldColumnWidth - numberColumnWidth - signColumnWidth
    return width
enddef

# Return string of spaces to the end of window
# (override default '---' string)
def GetExpansionStr(): string
    return repeat(' ', GetWidth())
enddef

# If enabled 'g:FoldText_showCount' - return count of folded lines
def GetLinesCount(): string
    var count = ''
    if (g:FoldText_showCount)
        var foldSize = 1 + v:foldend - v:foldstart
        count = printf(g:FoldText_countFormat, foldSize)
    endif
    return count
enddef

def GetMiddle(): string
    return ' ' .. g:FoldText_placeholder .. ' '
enddef

def GetEnding(): string
    var foldEnding = strpart(getline(v:foldend), indent(v:foldend))

    if (foldEnding =~ END_BLOCK_REGEX && foldEnding =~ '^\s*\"')
        foldEnding = strpart(getline(v:foldend), indent(v:foldend) + 2)
    endif

    foldEnding = substitute(foldEnding, '\s\+$', '', '')
    return foldEnding
enddef

def GetBeginning(): string
    var foldStartLineNr = GetFoldStartLineNr()
    var line = getline(v:foldstart)
    if (foldStartLineNr <= v:foldend)
        var spaces = repeat(' ', &tabstop)
        line = substitute(getline(foldStartLineNr), '\t', spaces, 'g')
    endif

    var foldEnding = GetEnding()

    if (foldEnding =~ END_COMMENT_REGEX && getline(v:foldstart) =~ START_COMMENT_BLANK_REGEX)
        var nextLine = substitute(getline(v:foldstart + 1), '\v\s*\*', '', '')
        line = line .. nextLine
    endif
    return line
enddef

# MAIN
def FoldText(): string
    if (v:foldend == 0)
        return ''
    endif

    var foldLine = GetBeginning() .. GetMiddle() .. GetEnding()

    var count = GetLinesCount()
    var contentLine = count .. strcharpart(foldLine, count->strwidth())

    var expansionStr = GetExpansionStr()
    return contentLine .. strcharpart(expansionStr, contentLine->strwidth()) 
enddef

set foldtext=s:FoldText()
