" Share the WSL editing behavior, resolving the source through symlinks.
let s:dotfiles_root = fnamemodify(resolve(expand('<sfile>:p')), ':h:h:h')
execute 'source ' . fnameescape(s:dotfiles_root . '/ubuntu/.vimrc')
unlet s:dotfiles_root
