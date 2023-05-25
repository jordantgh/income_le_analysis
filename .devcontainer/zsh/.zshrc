# Set up the prompt

email=$(git config --get user.email)

if [[ -z "$email" ]]; then
    username="anon"
else
    username=${email%%@*}
fi

source /root/.zshconfig/git-prompt.zsh/git-prompt.zsh
source /root/.zshconfig/gitprompt.zsh
PROMPT='%F{green}[%T]%f %F{blue}'"$username"'@devcontainer%f %F{yellow}%~%f $(gitprompt)%B%F{magenta}>%f '

setopt histignorealldups sharehistory

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

# # Terminal controls
# navigate by word
bindkey '^[[1;5D' backward-word  # Ctrl + left-arrow
bindkey '^[[1;5C' forward-word   # Ctrl + right-arrow
bindkey '^H' backward-kill-word  # Ctrl + backspace delete
bindkey '^[[3;5~' kill-word # Ctrl + delete deletes

# remove dot and slash from word characters to navigate line
WORDCHARS=${WORDCHARS//[\/.]}

# Keep 1000 lines of history within the shell and save it to /root/.zsh_history:
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=/root/.zsh_history

# Use modern completion system
source /root/.zshconfig/zsh-autocomplete/zsh-autocomplete.plugin.zsh
source /root/.zshconfig/zsh-autosuggestions/zsh-autosuggestions.zsh
source /etc/zsh_command_not_found
source /root/.zshconfig/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
