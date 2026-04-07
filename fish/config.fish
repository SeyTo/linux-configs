if status is-interactive
    # Commands to run in interactive sessions can go here
end

abbr -a v nvim
abbr -a l "ls -la"
abbr -a c "cd .. && ls -la"
abbr -a b bat
abbr -a q exit
abbr -a g git 
abbr -a y yarn 
abbr -a n pnpm
abbr -a cgo cargo 
abbr -a w wd 
abbr -a wa wd add! 
abbr -a wl wd list 
abbr -a d docker 
abbr -a dc docker-compose 
abbr -a caa ~/.caa/bin/caa -d 
abbr -a x xdg-open 
abbr -a t tmux
abbr -a py python
abbr -a psyu "paru -Syu --noconfirm"
abbr -a randpass "openssl rand -base64 14 | xclip -selection clipboard"
abbr -a lg lazygit
abbr -a ld lazydocker
abbr -a s sudo
abbr -a ps "paru -S "
abbr -a tm tmux


fish_vi_key_bindings

alias stfu="shutdown -P now"
alias v="nvim"
alias pro="cd ~/_proj"
alias obs='tmux -c \'nvim --cmd "cd /a/_obs/" /a/_obs/\''
alias obstools='tmux -c \'nvim --cmd "cd /a/_obs/" /a/_obs/Tech/Tools.md\''
alias sni="cd ~/_repo/_snippets/;nvim ."
alias day="~/scripts/theme.sh l"
alias night="~/scripts/theme.sh d"
alias vim=nvim
alias kctl="minikube kubectl --"

# override the vim mode inspector
function fish_mode_prompt

end

# pnpm
set -gx PNPM_HOME "/home/rj/.local/share/pnpm"
set -gx PATH "$PNPM_HOME" $PATH
# pnpm end

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /opt/anaconda/bin/conda
    eval /opt/anaconda/bin/conda "shell.fish" "hook" $argv | source
end
# <<< conda initialize <<<

set -U __done_min_cmd_duration 5000  # default: 5000 ms

# If commands runs >= 10 seconds, notify user on completion
if test $CMD_DURATION
    if test $CMD_DURATION -gt (math "1000 * 6")
        set secs (math "$CMD_DURATION / 1000")
        notify-send "$history[1]" "Returned $status, took $secs seconds"
    end
end

function fish_user_key_bindings
    bind yy fish_clipboard_copy
    bind Y fish_clipboard_copy
    bind p fish_clipboard_paste
end
