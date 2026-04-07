# Path to Oh My Fish install.
set -q XDG_DATA_HOME
  and set -gx OMF_PATH "$XDG_DATA_HOME/omf"
  or set -gx OMF_PATH "$HOME/.local/share/omf"

# Load Oh My Fish configuration.
source $OMF_PATH/init.fish

set fish_bind_mode insert
bind -M insert -m default jk backward-char force-repaint

# accept-autosuggestion alternative
bind -M insert \cs forward-char

# aliases
function repo --wraps cd --description 'open repo directory'
  cd /a/_repo
end

# history serach forward and backward
bind -M insert \cp history-search-backward
bind -M insert \cn history-search-forward
