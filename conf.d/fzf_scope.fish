# fzf-scope: Project-scoped command history for fish shell
# Auto-loaded on shell startup

# Configuration variables (user-overridable)
set -q fzf_scope_file; or set -U fzf_scope_file ~/.local/share/fish/fzf_scope.log
set -q fzf_scope_max_entries; or set -U fzf_scope_max_entries 50000
set -q fzf_scope_exclude_patterns; or set -U fzf_scope_exclude_patterns

# Register preexec hook to log commands
function _fzf_scope_preexec --on-event fish_preexec
    _fzf_scope_log $argv[1]
end

# Keybinding: Ctrl+Alt+R for project-scoped history search
bind \e\cr _fzf_project-scope
bind -M insert \e\cr _fzf_project-scope  # vi mode support
