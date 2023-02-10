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

Plug 'nvim-lua/popup.nvim'
Plug 'tpope/vim-fugitive'
Plug 'nvim-lua/plenary.nvim'
Plug 'akinsho/flutter-tools.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'williamboman/nvim-lsp-installer'
" plug 'williamboman/nvim-lsp-installer'
Plug 'weilbith/nvim-code-action-menu'

Plug 'neovim/nvim-lspconfig'
Plug 'nvim-lua/plenary.nvim'
Plug 'tami5/lspsaga.nvim'
Plug 'github/copilot.vim'
Plug 'norcalli/nvim-colorizer.lua'
Plug 'tpope/vim-abolish'

Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/vim-vsnip'
Plug 'hrsh7th/nvim-cmp'
Plug 'simrat39/rust-tools.nvim'
Plug 'hrsh7th/cmp-vsnip'
Plug 'JoosepAlviste/nvim-ts-context-commentstring'
Plug 'jose-elias-alvarez/null-ls.nvim'
Plug 'jose-elias-alvarez/typescript.nvim'
Plug 'folke/lsp-colors.nvim'
Plug 'kyazdani42/nvim-web-devicons'
Plug 'onsails/lspkind-nvim'
Plug 'RishabhRD/popfix'
Plug 'RishabhRD/nvim-lsputils'
Plug 'folke/trouble.nvim'
Plug 'ruanyl/vim-gh-line'
Plug 'williamboman/mason.nvim'
Plug 'williamboman/mason-lspconfig.nvim'
Plug 'MunifTanjim/prettier.nvim'
Plug 'themaxmarchuk/tailwindcss-colors.nvim'

Plug 'christoomey/vim-tmux-navigator'
Plug 'tpope/vim-commentary'
Plug 'airblade/vim-rooter'

Plug 'itchyny/lightline.vim'
Plug 'phanviet/vim-monokai-pro'
Plug 'sheerun/vim-polyglot'
Plug 'preservim/nerdtree'

Plug 'Yggdroot/LeaderF' " , { 'do': ':LeaderfInstallCExtension' }
Plug 'tamago324/LeaderF-filer'
Plug 'tpope/vim-surround'
Plug 'dhruvasagar/vim-open-url'
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'kwkarlwang/bufjump.nvim'
Plug 'phaazon/hop.nvim'
Plug 'pantharshit00/vim-prisma'
Plug 'hrsh7th/cmp-nvim-lsp-signature-help'
Plug 'edgedb/edgedb-vim'
Plug 'junegunn/goyo.vim'

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
" nnoremap <leader>* :execute 'Clap grep2 ++query='.expand('<cword>')<cr>
nnoremap <leader>pt :NERDTreeToggle<cr>
nnoremap <leader>pv :NERDTreeVCS<cr>
nnoremap <leader>ff :LeaderfFiler %:p:h<cr>
nnoremap <leader>fn :NERDTreeFind<cr>

nnoremap <leader>pg :Clap gfiles<cr>
nnoremap <leader>pf :Telescope find_files<cr>

"lsp provider to find the cursor word definition and reference
nnoremap <silent> <leader>ch <cmd>lua require('lspsaga.hover').render_hover_doc()<CR>
nnoremap <silent> <leader>cp <cmd>lua require'lspsaga.provider'.preview_definition()<CR>
nnoremap <silent> <leader>cv :TSLspRenameFile<CR>
nnoremap <silent> <leader>ci :TSLspOrganize<CR>
nnoremap <silent> <leader>ca :CodeActionMenu<CR>
nnoremap <silent> <leader>cn :Lspsaga rename<CR>
nnoremap <silent> <leader>cd :Telescope lsp_definitions<cr>
nnoremap <silent> <leader>cs :TypescriptGoToSourceDefinition<cr>
nnoremap <silent> <leader>cr :Telescope lsp_references<cr>
nnoremap <silent> <leader>cm :Telescope lsp_implementations<cr>
nnoremap <silent> <leader>cw :Telescope lsp_dynamic_workspace_symbols<cr>
nnoremap <silent> <leader>co :Telescope lsp_document_symbols<cr>
nnoremap <silent> <leader>ce <cmd>lua require'lspsaga.diagnostic'.show_line_diagnostics()<CR>
inoremap <silent> <C-s> <cmd>lua vim.lsp.buf.signature_help()<CR>

nnoremap <silent> <leader>e <cmd>lua require'lspsaga.diagnostic'.show_line_diagnostics()<CR>

nnoremap <silent> <leader>gn <cmd>lua vim.lsp.diagnostic.goto_next()<CR>:CodeActionMenu<cr>
nnoremap <silent> <leader>gp <cmd>lua vim.lsp.diagnostic.goto_prev()<CR>:CodeActionMenu<cr>
nnoremap <silent> <leader>go :OpenURL <cfile><CR>

nnoremap <silent> <leader>hf :HopPattern<cr>
nnoremap <silent> <leader>hF <cmd>lua require'hop'.hint_words({ direction = require'hop.hint'.HintDirection.BEFORE_CURSOR })<cr>

let g:open_url_default_mappings = 0
let g:gh_line_map_default = 0
let g:gh_line_blame_map_default = 1
let g:gh_line_map = '<leader>gl'

nnoremap <leader>xx <cmd>TroubleToggle<cr>
nnoremap <leader>xw <cmd>TroubleToggle workspace_diagnostics<cr>
nnoremap <leader>xd <cmd>TroubleToggle document_diagnostics<cr>
nnoremap <leader>xq <cmd>TroubleToggle quickfix<cr>
nnoremap <leader>xl <cmd>TroubleToggle loclist<cr>
nnoremap gR <cmd>TroubleToggle lsp_references<cr>

"Buffers
nnoremap <leader>bp :bp<cr>
nnoremap <leader>bn :bn<cr>
nnoremap <leader>bb :Clap recent_files<cr>
nnoremap <leader>bg :Clap bcommits<cr>

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

"---------------NerdTree
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif
let NERDTreeMapActivateNode='l'
let NERDTreeMapJumpParent='h'
let NERDTreeShowHidden=1
"--------------- end nerdtree


"----------LSP
lua require('lsp-config')
lua require('telescope-config')
lua require('jump-config')

lua require'colorizer'.setup()
lua require'hop'.setup()
lua require('lspkind').init({ preset = 'codicons' })

"Completion
set completeopt=menu,menuone,noselect

lua <<EOF
  -- Setup nvim-cmp.
  local cmp = require'cmp'

  cmp.setup({
    completion = {
      completeopt = 'menu,menuone,noinsert'
    },
    formatting = {
      format = require('lspkind').cmp_format(),
    },
    snippet = {
      -- REQUIRED - you must specify a snippet engine
      expand = function(args)
        vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
        -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
        -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
        -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
      end,
    },
    mapping = {
      ['<C-j>'] = cmp.mapping.select_next_item(),
      ['<C-k>'] = cmp.mapping.select_prev_item(),
      ['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
      ['<C-l>'] = cmp.mapping.confirm({ select = false }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
      ['<Tab>'] = cmp.config.disable
    },
    sources = cmp.config.sources({
      { name = 'nvim_lsp_signature_help' },
      { name = 'nvim_lsp' },
      -- { name = 'cmp_tabnine' }, -- For vsnip users.
      { name = 'path' }, -- For vsnip users.
      -- { name = 'luasnip' }, -- For luasnip users.
      -- { name = 'ultisnips' }, -- For ultisnips users.
      -- { name = 'snippy' }, -- For snippy users.
    })
  })
EOF

" lua << EOF
"   require("flutter-tools").setup{} -- use defaults
" EOF

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
