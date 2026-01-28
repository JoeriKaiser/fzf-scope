# Completions for fzf_scope_clean

complete -c fzf_scope_clean -f

complete -c fzf_scope_clean -n __fish_use_subcommand -a prune -d "Trim log to max entries"
complete -c fzf_scope_clean -n __fish_use_subcommand -a project -d "Remove entries for a project"
complete -c fzf_scope_clean -n __fish_use_subcommand -a older-than -d "Remove entries older than N days"
complete -c fzf_scope_clean -n __fish_use_subcommand -a stats -d "Show log statistics"

# For 'project' subcommand, complete with directories from the log
complete -c fzf_scope_clean -n "__fish_seen_subcommand_from project" -xa "(awk -F'\t' '!seen[\$2]++ {print \$2}' $fzf_scope_file 2>/dev/null)"
