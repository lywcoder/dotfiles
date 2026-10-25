" Resolve the shared configuration through this entry symlink.
let s:dotfiles_root = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')
execute 'source ' . fnameescape(s:dotfiles_root . '/linux/common/vim.vim')
unlet s:dotfiles_root
