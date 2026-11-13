#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

# bun (optional)
if [ -d "$HOME/.bun" ]; then
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
fi
