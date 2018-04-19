#! /bin/bash

source "${HOME}/workspace/bosh-devground/environments/taakako1-aws/creds/bbl.vars"
eval "$(bbl print-env)"
export HISTFILE=$(pwd)/bash-history
tmux
tmux source-file  ~/dotfiles/config/tmux/tmuxcolors-light.conf

