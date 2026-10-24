" ==========================================
" ~/.vimrc
" ==========================================

" 1. 基础设置
set nocompatible
filetype plugin indent on
syntax enable
set encoding=utf-8

" Leader 使用空格
let mapleader = " "

" 2. 显示
set number
set relativenumber
" set cursorline
set signcolumn=yes
set scrolloff=5
set nowrap

" 3. 缩进
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set autoindent
set smartindent

" 4. 搜索
set ignorecase
set smartcase
set incsearch
set hlsearch

" 5. 编辑行为
set hidden
set backspace=indent,eol,start
set splitright
set splitbelow
set wildmenu
set showmatch

" 6. 响应速度
set updatetime=300
set timeoutlen=500

" 7. 持久撤销
if has('persistent_undo')
    let s:undo_dir = expand('~/.vim/undo')
    if !isdirectory(s:undo_dir)
        call mkdir(s:undo_dir, 'p')
    endif
    let &undodir = s:undo_dir
    set undofile
endif

" 8. 常用快捷键
nnoremap <leader>w :write<CR>
nnoremap <leader>q :quit<CR>
nnoremap <leader>h :nohlsearch<CR>

" 9. Vim 分屏导航
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" 10. 自动文件类型缩进
augroup my_indent
    autocmd!
    autocmd FileType python setlocal shiftwidth=4 tabstop=4 softtabstop=4 expandtab
    autocmd FileType c,cpp setlocal shiftwidth=4 tabstop=4 softtabstop=4 expandtab
    autocmd FileType make setlocal noexpandtab
augroup END
" 模式光标设置
let &t_EI = "\e[2 q" " Normal 模式：实心方块 (若想闪烁方块可设为 \e[1 q)
let &t_SI = "\e[6 q" " Insert 模式：实心竖条 (若想闪烁竖条可设为 \e[5 q)
let &t_SR = "\e[4 q" " Replace 模式：下划线   (若想闪烁下划线可设为 \e[3 q)
