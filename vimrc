set nocompatible           " -  be iMproved
filetype on
filetype off               " -  required!


" PLUG
  call plug#begin('~/.vim/plugged')
  Plug 'rking/ag.vim'
  Plug 'chrisbra/color_highlight'
  Plug 'JazzCore/ctrlp-cmatcher'
  Plug 'kien/ctrlp.vim'
  Plug 'editorconfig/editorconfig-vim'
  Plug 'scrooloose/nerdtree'
  Plug 'bling/vim-airline'
  Plug 'luochen1990/rainbow'
  Plug 'marijnh/tern_for_vim'
  Plug 'scrooloose/syntastic'
  Plug 'tpope/vim-commentary'
  Plug 'kana/vim-fakeclip'
  Plug 'pangloss/vim-javascript'
  Plug 'jelera/vim-javascript-syntax'
  Plug 'tpope/vim-surround'
  Plug 'altercation/vim-colors-solarized'
  Plug 'christoomey/vim-tmux-navigator'
  Plug 'tpope/vim-fugitive'
  Plug 'mxw/vim-jsx'
  Plug 'mattn/emmet-vim'
  Plug 'othree/html5.vim'
  Plug 'junegunn/goyo.vim'
  Plug 'christoomey/vim-tmux-navigator'
  call plug#end()
" ENDPLUG

" COLOR
  set t_Co=256
  colorscheme desert
" ENDCOLOR

" GENERIC OPTIONS
" - Highlight diffs
    filetype on
    augroup PatchDiffHighlight
        autocmd!
        autocmd FileType  diff   syntax enable
    augroup END
" - Misc
    set laststatus=2
    set encoding=utf-8
    syntax on
    filetype plugin indent on
    set autoindent
    set smartindent
    set number " line numbers
    set ruler
    set expandtab
    set autoread
    set shiftwidth=2
    set tabstop=2
    hi MatchParen ctermbg=black ctermfg=none cterm=underline
    set fo-=r
    set nofoldenable" -  disable folding
    set colorcolumn=100
    set clipboard=unnamed
    set title
    set ttyfast
    set nobackup
    set noswapfile
    set scrolloff=3
    set matchpairs+=>:<
    set gdefault "global replace

" - mouse support
    set ttymouse=xterm2
    set mouse=a

" - Cursor shape
    let &t_SI = "\<Esc>]50;CursorShape=1\x7"
    let &t_EI = "\<Esc>]50;CursorShape=0\x7"
" - Commands
    set showcmd

" - tab completion in command line
    set wildmode=list:longest

" - Ignore
    set wildignore+=node_modules
    set wildignore+=*.o,*.obj,.git,*.rbc,*.class,.svn,*.beam
    set wildignore+=*.jpg,*.jpeg,*.gif,*.png,*.gif,*.psd,*.ico
    set wildignore+=.sass-cache,.DS_Store,.bundle
    set wildignore+=.coffee.js
    set wildignore+=*.rbc,*.scssc,*.sassc
    set wildignore+=*/spec/dummy/*
    set wildignore+=*/tmp/*

" KEYBINDINGS
    let mapleader=" "
    set backspace=indent,eol,start
    noremap ; :

" - jump more naturally between wrapped lines
    noremap j gj
    noremap k gk
    noremap Hh <Esc>

" - easier window nav
    noremap <C-h> <C-w>h
    noremap <C-j> <C-w>j
    noremap <C-k> <C-w>k
    noremap <C-l> <C-w>l

" - splits open in more logical spots
    set splitbelow
    set splitright

" - Source vimrc
    map <C-E> :so ~/.vimrc<CR>

" - Remove trailing whitespace
    map <Leader>w :%s/\s\+$//e<CR>

" - This rewires n and N to do the highlighing...
    nnoremap <silent> n   n:call HLNext(0.1)<cr>
    nnoremap <silent> N   N:call HLNext(0.1)<cr>
" END KEYBINDINGS

" PLUGINCONFIG
" - Ag
    map <Leader>n :w<CR>:cn<CR>
    map <Leader>N :w<CR>:cN<CR>
    map <Leader>s :Ag

" - Colorizer
    let g:colorizer_auto_filetype='css,html,styl,less,scss'
    map <Leader>c :ColorHighlight<CR>

" - Ctrl p
    let g:ctrlp_working_path_mode = ''
    map <Leader>t :CtrlP<CR>
    map <Leader>g :CtrlPMRU<CR>
    map <Leader>f :CtrlPLine<CR>
    :let g:ctrlp_map = '<Leader>t'
    :let g:ctrlp_working_path_mode = 0
    :let g:ctrlp_switch_buffer = 0
    :let g:ctrlp_match_func = {'match': 'matcher#cmatch'}
    :let g:ctrlp_custom_ignore = {'dir': 'dist'}

" - Emmet.vim
    " let g:user_emmet_leader_key='<Leader>y'

" - Goyo writing mode
    function! GoyoBefore()
      :syntax off
      :set linebreak
      :set nojoinspaces
      " :set spell
    endfunction
    function! GoyoAfter()
      :syntax on
      :set nolinebreak
      :set joinspaces
      " :set nospell
    endfunction
    let g:goyo_callbacks = [function('GoyoBefore'), function('GoyoAfter')]

" - JSX Highlight
    let g:jsx_ext_required = 0

" - NERDTree
    :map <Leader>r :NERDTreeToggle<CR>

" - Powerline
    let g:airline_powerline_fonts = 1

" - Rainbow
    let g:rainbow_active = 1
    let g:rainbow_conf = {
    \   'guifgs': [
    \     '#458588',
    \     '#b16286',
    \     '#cc241d',
    \     '#d65d0e',
    \     '#458588',
    \     '#b16286',
    \     '#cc241d',
    \     '#d65d0e',
    \     '#458588',
    \     '#b16286',
    \     '#cc241d',
    \     '#d65d0e',
    \     '#458588',
    \     '#b16286',
    \     '#cc241d',
    \     '#d65d0e'
    \   ],
    \   'ctermfgs': [
    \     'brown',
    \     'Darkblue',
    \     'darkgray',
    \     'darkgreen',
    \     'darkcyan',
    \     'darkred',
    \     'darkmagenta',
    \     'brown',
    \     'lightgreen',
    \     'green',
    \     'darkmagenta',
    \     'Darkblue',
    \     'darkgreen',
    \     'darkcyan',
    \     'darkred',
    \     'red'
    \   ]
    \}

" - Syntastic
    let g:syntastic_html_checkers = []
    let g:syntastic_javascript_checkers = ['jsxhint']
    let g:syntastic_check_on_open = 1
    let g:syntastic_always_populate_loc_list = 1
" -  Next and previous error hotkeys
    map <Leader>e :lnext<CR>
    map <Leader>E :lprev<CR>

" - tabular
    :let g:tabular_loaded = 1

" - tern
    map <Leader>g :TernRename<CR>
" END PLUGINCONFIG

" FUNCTIONS
" -  ring match in red for a short time
    function! HLNext (blinktime)
        highlight RedOnRed ctermfg=red ctermbg=red
        let [bufnum, lnum, col, off] = getpos('.')
        let matchlen = strlen(matchstr(strpart(getline('.'),col-1),@/))
        echo matchlen
        let ring_pat = (lnum > 1 ? '\%'.(lnum-1).'l\%>'.max([col-4,1]) .'v\%<'.(col+matchlen+3).'v.\|' : '')
                \ . '\%'.lnum.'l\%>'.max([col-4,1]) .'v\%<'.col.'v.'
                \ . '\|'
                \ . '\%'.lnum.'l\%>'.max([col+matchlen-1,1]) .'v\%<'.(col+matchlen+3).'v.'
                \ . '\|'
                \ . '\%'.(lnum+1).'l\%>'.max([col-4,1]) .'v\%<'.(col+matchlen+3).'v.'
        let ring = matchadd('RedOnRed', ring_pat, 101)
        redraw
        exec 'sleep ' . float2nr(a:blinktime * 1000) . 'm'
        call matchdelete(ring)
        redraw
    endfunction
" ENDFUNCTIONS
