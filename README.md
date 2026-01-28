# fzf-scope

A fish shell plugin that logs command history with directory context and provides project-scoped history search via fzf.

Designed to complement [fzf.fish](https://github.com/PatrickF1/fzf.fish).

## Features

- Automatically logs commands with their git project context (or working directory)
- Search history scoped to your current project with `Ctrl+Alt+R`
- Keeps global `Ctrl+R` history search untouched
- Cleanup utilities to manage log size

## Installation

### Fisher

```fish
fisher install JoeriKaiser/fzf-scope
```

### Oh My Fish

```fish
omf install fzf-scope
```

### Manual

```fish
git clone https://github.com/JoeriKaiser/fzf-scope ~/.config/fish/fzf-scope
set -p fish_function_path ~/.config/fish/fzf-scope/functions
source ~/.config/fish/fzf-scope/conf.d/fzf_scope.fish
```

## Usage

### Project-scoped history search

Press `Ctrl+Alt+R` to search command history filtered to your current git project. If you're not in a git repository, it filters by the exact current directory.

### Cleanup utility

```fish
# Show log statistics
fzf_scope_clean stats

# Trim log to max entries (default 50000)
fzf_scope_clean prune

# Remove all entries for a specific project
fzf_scope_clean project /path/to/project

# Remove entries older than N days
fzf_scope_clean older-than 30
```

## Configuration

Set these variables in your `config.fish` before the plugin loads:

```fish
# Path to log file (default: ~/.local/share/fish/fzf_scope.log)
set -U fzf_scope_file ~/.local/share/fish/fzf_scope.log

# Maximum log entries before pruning is recommended (default: 50000)
set -U fzf_scope_max_entries 50000

# Regex patterns to exclude from logging (e.g., commands with secrets)
set -U fzf_scope_exclude_patterns 'password' 'secret' 'token' 'API_KEY'
```

## How it works

1. A `fish_preexec` hook logs every command with:
   - Unix timestamp
   - Git repository root (or `$PWD` if not in a repo)
   - The command itself

2. When you press `Ctrl+Alt+R`, the plugin:
   - Filters the log to entries matching your current project
   - Deduplicates commands (most recent first)
   - Pipes to fzf for selection
   - Places the selected command on your command line

## License

MIT
