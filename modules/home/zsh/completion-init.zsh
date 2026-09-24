# The default is a bare `compinit`, which dumps to ~/.zcompdump.
# `:h` is zsh's dirname modifier.
autoload -U compinit
_zcompdump=@zcompdump@
[[ -d ${_zcompdump:h} ]] || mkdir -p ${_zcompdump:h}
compinit -d "$_zcompdump"
unset _zcompdump
