set nocompatible               " Be iMproved
filetype plugin indent on
syntax enable
set number
set ignorecase
set gdefault
set termguicolors
set nohlsearch

" Allows you to change buffers even if the current on has unsaved changes
set hidden

" Intuit the indentation of new lines when creating them
set smartindent
" On pressing tab, insert 2 spaces
set expandtab
" show existing tab with 2 spaces width
set tabstop=2
set softtabstop=2
" when indenting with '>', use 2 spaces width
set shiftwidth=2
set splitbelow
set splitright

" Return to last edit position when opening files
" It's some magic I picked up somewhere, no idea how it works
" or what alternatives are out there
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

" Who wants .swap files??
set noswapfile

" Enable mouse support
set mouse=a

" Turn persistent undo on
" means that you can undo even when you close a buffer/VIM
set undodir=~/.vim_runtime/temp_dirs/undodir
set undofile

" Blinking cursor
set guicursor=a:blinkon100

call plug#begin(stdpath('data') . '/plugged')

Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'

Plug 'neovim/nvim-lspconfig'
Plug 'nvim-lua/plenary.nvim'
Plug 'glepnir/lspsaga.nvim'
" Plug 'ray-x/lsp_signature.nvim'
Plug 'hrsh7th/nvim-compe'
Plug 'jose-elias-alvarez/null-ls.nvim'
Plug 'jose-elias-alvarez/nvim-lsp-ts-utils'
Plug 'folke/lsp-colors.nvim'
Plug 'kyazdani42/nvim-web-devicons'
Plug 'onsails/lspkind-nvim'
Plug 'RishabhRD/popfix'
Plug 'RishabhRD/nvim-lsputils'
Plug 'folke/trouble.nvim'
Plug 'ruanyl/vim-gh-line'

Plug 'ctrlpvim/ctrlp.vim'

Plug 'christoomey/vim-tmux-navigator'
Plug 'tpope/vim-commentary'
Plug 'airblade/vim-rooter'

Plug 'itchyny/lightline.vim'
Plug 'phanviet/vim-monokai-pro'
Plug 'sheerun/vim-polyglot'
Plug 'preservim/nerdtree'

Plug 'Yggdroot/LeaderF'
Plug 'tamago324/LeaderF-filer'
Plug 'tpope/vim-surround'
Plug 'dhruvasagar/vim-open-url'
Plug 'nvim-treesitter/nvim-treesitter'

call plug#end()
"End dein Scripts-------------------------

"Semicolon!
map ; :

"Hotkeys for leader
let mapleader=" "

"Configuration
nnoremap <leader>ve :e $MYVIMRC<cr>
nnoremap <leader>vi :PlugInstall<cr>
nnoremap <leader>vc :PlugClean<cr>

"Windows
nnoremap <leader>wv :vsp<cr>
nnoremap <leader>ws :sp<cr>

"Commentary
xmap <leader>;  <Plug>Commentary
nmap <leader>;  <Plug>Commentary
omap <leader>;  <Plug>Commentary
nmap <leader>;; <Plug>CommentaryLine

"Files
nnoremap <leader>/ :Telescope live_grep<cr>
nnoremap <leader>* :Telescope grep_string<cr>
nnoremap <leader>pt :NERDTreeToggle<cr>
nnoremap <leader>pv :NERDTreeVCS<cr>
nnoremap <leader>ff :LeaderfFiler %:p:h<cr>
nnoremap <leader>fn :NERDTreeFind<cr>

nnoremap <leader>pf :Telescope git_files<cr>

nnoremap <leader>rl :CtrlP<cr>:CtrlP<cr>

"lsp provider to find the cursor word definition and reference
nnoremap <silent> <leader>ch <cmd>lua require('lspsaga.hover').render_hover_doc()<CR>
nnoremap <silent> <leader>cp <cmd>lua require'lspsaga.provider'.preview_definition()<CR>
nnoremap <silent> <leader>cm :TSLspRenameFile<CR>
nnoremap <silent> <leader>ci :TSLspOrganize<CR>
nnoremap <silent> <leader>ca :Telescope lsp_code_actions theme=get_cursor<cr>
nnoremap <silent> <leader>cn :Lspsaga rename<CR>
nnoremap <silent> <leader>cd :Telescope lsp_definitions<cr>
nnoremap <silent> <leader>cr :Telescope lsp_references<cr>
nnoremap <silent> <leader>cw :Telescope lsp_dynamic_workspace_symbols<cr>
nnoremap <silent> <leader>co :Telescope lsp_document_symbols<cr>
nnoremap <silent> <leader>ce <cmd>lua require'lspsaga.diagnostic'.show_line_diagnostics()<CR>
nnoremap <silent> <leader>ct :TroubleToggle<CR>
inoremap <silent> <C-s> <cmd>lua vim.lsp.buf.signature_help()<CR>

nnoremap <silent> <leader>e <cmd>lua require'lspsaga.diagnostic'.show_line_diagnostics()<CR>

nnoremap <silent> <leader>gn <cmd>lua vim.lsp.diagnostic.goto_next()<CR>
nnoremap <silent> <leader>gp <cmd>lua vim.lsp.diagnostic.goto_prev()<CR>
nnoremap <silent> <leader>go :OpenURL <cfile><CR>

let g:open_url_default_mappings = 0
let g:gh_line_map_default = 0
let g:gh_line_blame_map_default = 1
let g:gh_line_map = '<leader>gl'

"Buffers
nnoremap <leader>bp :bp<cr>
nnoremap <leader>bn :bn<cr>
nnoremap <leader>bb :Telescope buffers<cr>

"Vimrc
augroup reload_vimrc
	autocmd!
	autocmd! BufWritePost $MYVIMRC,$MYGVIMRC nested source %
augroup END

colorscheme monokai_pro
let g:lightline = {
      \ 'colorscheme': 'monokai_pro',
      \ 'component_function': {
      \   'filename': 'LightlineFilename',
      \ },
      \ }

function! LightlineFilename()
  return expand("%")
endfunction


hi LineNr guibg=bg
set foldcolumn=0
hi foldcolumn guibg=bg
hi VertSplit guibg=bg guifg=#777777

"---------------NerdTree
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif
let NERDTreeMapActivateNode='l'
let NERDTreeMapJumpParent='h'

"--------------- end nerdtree


"----------LSP
lua require("lsp-config")
lua require('telescope-config')
"Completion
function! s:s(delta) abort
  if pumvisible()
    let l:i = complete_info(['selected']).selected
    call timer_start(0, { -> nvim_select_popupmenu_item(l:i + a:delta, v:true, v:false, {}) })
  endif
  return "\<Ignore>"
endfunction
inoremap <silent><expr><C-j>     <SID>s(+1)
inoremap <silent><expr><C-k>     <SID>s(-1)

inoremap <silent><expr> <C-l> compe#confirm('<CR>')

"LSP Saga

"scroll the saga help windows
nnoremap <silent> <C-n> <cmd>lua require('lspsaga.action').smart_scroll_with_saga(1)<CR>
nnoremap <silent> <C-p> <cmd>lua require('lspsaga.action').smart_scroll_with_saga(-1)<CR>

" vim.lsp.handlers['textDocument/references'] = require'lsputil.locations'.references_handler
" vim.lsp.handlers['textDocument/definition'] = require'lsputil.locations'.definition_handler
" vim.lsp.handlers['textDocument/codeAction'] = require'lsputil.codeAction'.code_action_handler
lua <<EOF
vim.lsp.handlers['textDocument/declaration'] = require'lsputil.locations'.declaration_handler
vim.lsp.handlers['textDocument/typeDefinition'] = require'lsputil.locations'.typeDefinition_handler
vim.lsp.handlers['textDocument/implementation'] = require'lsputil.locations'.implementation_handler
vim.lsp.handlers['textDocument/documentSymbol'] = require'lsputil.symbols'.document_handler
vim.lsp.handlers['workspace/symbol'] = require'lsputil.symbols'.workspace_handler
EOF
"-----------end lsp

"------filr.vim
    " let g:Lf_FilerNormalMap = {
    " \  'i':     'switch_insert_mode',
    " \  '<C-g>': 'close_preview_popup',
    " \  '<C-c>': 'close_preview_popup',
    " \}
    " let g:Lf_FilerInsertMap = {
    " \  '<Esc>':     'switch_normal_mode',
    " \  '<C-g>': 'close_preview_popup',
    " \  '<C-c>': 'close_preview_popup',
    " \}
"------

"------Ctrlp
if executable('rg')
  set grepprg=rg\ --color=never
  let g:ctrlp_user_command = 'rg %s --files --color=never --glob ""'
  let g:ctrlp_use_caching = 0
endif
"------End Ctrlp
