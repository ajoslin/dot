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
set ff=unix

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

Plug 'tpope/vim-fugitive'
Plug 'shinchu/lightline-gruvbox.vim'
Plug 'ellisonleao/gruvbox.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'MaximilianLloyd/tw-values.nvim'
Plug 'nvim-neotest/nvim-nio'

Plug 'HakonHarnes/img-clip.nvim'
Plug 'stevearc/dressing.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'MunifTanjim/nui.nvim'
Plug 'nvim-tree/nvim-web-devicons'
Plug 'MeanderingProgrammer/render-markdown.nvim'
Plug 'robitx/gp.nvim'

Plug 'chottolabs/kznllm.nvim'

Plug 'neovim/nvim-lspconfig'
Plug 'gbprod/yanky.nvim'
Plug 'yacineMTB/dingllm.nvim'
" Plug 'github/copilot.vim'
Plug 'supermaven-inc/supermaven-nvim'
Plug 'pmizio/typescript-tools.nvim'
Plug 'NvChad/nvim-colorizer.lua'

Plug 'akinsho/git-conflict.nvim'

Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'
Plug 'simrat39/rust-tools.nvim'
" Plug 'JoosepAlviste/nvim-ts-context-commentstring'
Plug 'folke/lsp-colors.nvim'
Plug 'kyazdani42/nvim-web-devicons'
Plug 'onsails/lspkind-nvim'
Plug 'ruanyl/vim-gh-line'
Plug 'williamboman/mason.nvim'
Plug 'williamboman/mason-lspconfig.nvim'
Plug 'themaxmarchuk/tailwindcss-colors.nvim'
Plug 'tpope/vim-abolish'

Plug 'christoomey/vim-tmux-navigator'
Plug 'tpope/vim-commentary'
Plug 'airblade/vim-rooter'

Plug 'itchyny/lightline.vim'
Plug 'sheerun/vim-polyglot'
Plug 'nvim-tree/nvim-tree.lua'
Plug 'elentok/format-on-save.nvim'

Plug 'tpope/vim-surround'
Plug 'dhruvasagar/vim-open-url'
Plug 'nvim-treesitter/nvim-treesitter', {'do':':TSUpdate', 'commit': '57a8acf0c4ed5e7f6dda83c3f9b073f8a99a70f9'}
Plug 'kwkarlwang/bufjump.nvim'
Plug 'pantharshit00/vim-prisma'
Plug 'junegunn/goyo.vim'
Plug 'tzachar/highlight-undo.nvim'
Plug 'antosha417/nvim-lsp-file-operations'
Plug 'filipdutescu/renamer.nvim', { 'branch': 'master' }
Plug 'stevearc/oil.nvim'
Plug 'iibe/gruvbox-high-contrast'

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
let g:Lf_ShowHidden = 1
let g:Lf_FilerShowHiddenFiles = 1

"Clap
let g:clap_layout = { 'relative': 'editor', 'width': '90%' }

" prints extra 0 char
autocmd FileType clap_input inoremap <silent> <buffer> <Esc> <C-R>=clap#exit()<CR><Esc>x 

nnoremap <leader>/ :Telescope live_grep<cr>
" nnoremap <leader>/ :Telescope live_grep<cr>
nnoremap <leader>* :Telescope grep_string<cr>
nnoremap <leader>r :Telescope resume<cr>
" nnoremap <leader>* :execute 'Clap grep2 ++query='.expand('<cword>')<cr>

nnoremap <leader>y :Telescope yank_history<cr>

nnoremap <leader>pf <cmd>lua require'telescope.builtin'.find_files({ find_command = {'rg', '--files', '--hidden', '-g', '!.git' }})<cr>

"lsp provider to find the cursor word definition and reference
nnoremap <silent> <leader>ch <cmd>lua vim.lsp.buf.hover()<cr>

" nnoremap <silent> <leader>ch <cmd>lua require("hover").hover, {desc = "hover.nvim"})<CR>
        " vim.keymap.set("n", "gK", require("hover").hover_select, {desc = "hover.nvim (select)"})

nnoremap <silent> <leader>ca <cmd>lua vim.lsp.buf.code_action()<CR>
nnoremap <silent> <leader>cn <cmd>lua require('renamer').rename()<CR>
nnoremap <silent> <leader>cd :Telescope lsp_definitions<cr>
nnoremap <silent> <leader>cs <cmd>vim.lsp.buf.definition()<cr>
nnoremap <silent> <leader>cr :Telescope lsp_references<cr>
nnoremap <silent> <leader>cm :Telescope lsp_implementations<cr>
nnoremap <silent> <leader>cw :Telescope lsp_dynamic_workspace_symbols<cr>
nnoremap <silent> <leader>co :Telescope lsp_document_symbols<cr>
" inoremap <silent> <C-s> <cmd>lua vim.lsp.buf.signature_help()<CR>

nnoremap <silent> <leader>gr <cmd>:GpRewrite<CR>
nnoremap <silent> <leader>gn <cmd>:GpChatToggle<CR>

nnoremap <silent> <leader>e <cmd>lua vim.diagnostic.open_float()<CR>

nnoremap <leader>ff :Oil<cr>:set ma<cr>

nnoremap <silent> <leader>go :OpenURL <cfile><CR>

let g:open_url_default_mappings = 0
let g:gh_line_map_default = 0
let g:gh_line_blame_map_default = 1
let g:gh_line_map = '<leader>gl'

"Buffers
nnoremap <leader>bp :bp<cr>
nnoremap <leader>bn :bn<cr>
nnoremap <leader>bb :Clap recent_files<cr>
nnoremap <leader>bg :Clap bcommits<cr>

:command X !git x &

"Vimrc
augroup reload_vimrc
	autocmd!
	autocmd! BufWritePost $MYVIMRC,$MYGVIMRC nested source %
augroup END

set background=dark
" let g:gruvbox_contrast_dark = 'hard'
" colorscheme gruvbox-high-contrast
colorscheme gruvbox

"colorscheme catppuccin-latte
let g:lightline = {
      \ 'colorscheme': 'gruvbox',
      \ 'component_function': {
      \   'filename': 'LightlineFilename',
      \   'method': 'NearestMethodOrFunction'
      \ },
      \ }

function! LightlineFilename()
  return expand("%")
endfunction


hi LineNr guibg=bg
set foldcolumn=0
hi foldcolumn guibg=bg
hi VertSplit guibg=bg guifg=#777777



"----------LSP
lua require('lsp-config')
lua require('telescope-config')
lua require('jump-config')
lua require('tree-config')

lua require'colorizer'.setup()
lua require('lspkind').init({ preset = 'codicons' })

"Completion
set completeopt=menu,menuone,noselect

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
"
"
let g:rooter_patterns = ['.git']

cabbrev wq execute "lua vim.lsp.buf.formatting_seq_sync()" <bar> wq

" Configure LSP through rust-tools.nvim plugin.
" rust-tools will configure and enable certain LSP features for us.
" See https://github.com/simrat39/rust-tools.nvim#configuration
lua <<EOF

-- nvim_lsp object
local nvim_lsp = require'lspconfig'

require('rust-tools').setup({
    tools = {
        runnables = {
            use_telescope = true
        },
        inlay_hints = {
            auto = true,
            show_parameter_hints = false,
            parameter_hints_prefix = "",
            other_hints_prefix = "",
        },
    },

    -- all the opts to send to nvim-lspconfig
    -- these override the defaults set by rust-tools.nvim
    -- see https://github.com/neovim/nvim-lspconfig/blob/master/CONFIG.md#rust_analyzer
    server = {
        -- on_attach is a callback called when the language server attachs to the buffer
        -- on_attach = on_attach,
        settings = {
            -- to enable rust-analyzer settings visit:
            -- https://github.com/rust-analyzer/rust-analyzer/blob/master/docs/user/generated_config.adoc
            ["rust-analyzer"] = {
                -- enable clippy on save
                checkOnSave = {
                    command = "clippy"
                },
            }
        }
    },
})
EOF
