function _fzf_project-scope --description "Search project-scoped command history with fzf"
    # Check if log file exists
    if not test -f $fzf_scope_file
        echo "fzf-scope: No history log found yet. Run some commands first."
        return 1
    end

    # Determine current project root
    set -l project_root (git rev-parse --show-toplevel 2>/dev/null)
    if test $status -ne 0
        set project_root $PWD
    end

    # Get current command line token for initial query
    set -l initial_query (commandline --current-token)

    # Filter log for current project, extract commands, deduplicate (most recent first)
    set -l selected (
        awk -F'\t' -v root="$project_root" '
            $2 == root { print $1, $3 }
        ' $fzf_scope_file \
        | sort -rn \
        | cut -d' ' -f2- \
        | awk '!seen[$0]++' \
        | fzf \
            --height=40% \
            --layout=reverse \
            --scheme=history \
            --query="$initial_query" \
            --no-sort
    )

    # If selection made, put it on the command line
    if test -n "$selected"
        commandline --replace -- $selected
    end

    commandline -f repaint
end
