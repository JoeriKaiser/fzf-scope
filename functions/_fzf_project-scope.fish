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

    # Get project name for header
    set -l project_name (basename $project_root)

    # Get current command line token for initial query
    set -l initial_query (commandline --current-token)

    # Build header
    set -l header_line1 "╭─ $project_name ────────────────────────────────────────╮"
    set -l header_line2 "│ tab: select  ctrl-a: all  ctrl-d: none  ?: preview │"
    set -l header_line3 "╰──────────────────────────────────────────────────────╯"

    # Filter log for current project, format for display, deduplicate
    # Format: "YYYY-MM-DD HH:MM │ ./subdir/ │ [✗] command"
    set -l selected (
        awk -F'\t' -v root="$project_root" '
        BEGIN { OFS="" }
        {
            # Handle both old 3-field and new 6-field format
            if (NF == 3) {
                # Old format: timestamp, project_root, command
                if ($2 == root) {
                    ts = $1
                    cmd = $3
                    subdir = "./"
                    exit_status = ""
                    session = ""
                    print ts "\t" subdir "\t" exit_status "\t" cmd
                }
            } else if (NF >= 6) {
                # New format: timestamp, project_root, working_dir, session_id, exit_status, command
                if ($2 == root) {
                    ts = $1
                    working_dir = $3
                    session = $4
                    exit_status = $5
                    cmd = $6

                    # Calculate subdir relative to project root
                    if (working_dir == root) {
                        subdir = "./"
                    } else {
                        subdir = "./" substr(working_dir, length(root) + 2) "/"
                    }

                    print ts "\t" subdir "\t" exit_status "\t" cmd
                }
            }
        }
        ' $fzf_scope_file \
        | sort -t\t -k1 -rn \
        | awk -F'\t' '
        {
            cmd = $4
            if (!seen[cmd]++) {
                # Format timestamp
                ts_cmd = "date -d @" $1 " +\"%Y-%m-%d %H:%M\" 2>/dev/null"
                ts_cmd | getline formatted_ts
                close(ts_cmd)

                # Format subdir (pad to 10 chars)
                subdir = $2

                # Add failure indicator
                status_indicator = ""
                if ($3 != "" && $3 != "0") {
                    status_indicator = "\033[31m✗\033[0m "
                }

                printf "%s │ %-10s │ %s%s\n", formatted_ts, subdir, status_indicator, cmd
            }
        }
        ' \
        | fzf \
            --height=50% \
            --layout=reverse \
            --scheme=history \
            --query="$initial_query" \
            --no-sort \
            --multi \
            --header="$header_line1
$header_line2
$header_line3" \
            --header-first \
            --preview="_fzf_scope_preview {}" \
            --preview-window="bottom:30%:wrap" \
            --bind="ctrl-a:select-all" \
            --bind="ctrl-d:deselect-all" \
            --bind="?:toggle-preview" \
            --ansi
    )

    # If selection made, extract commands and put on command line
    if test -n "$selected"
        # Extract just the command part (after last │, removing ✗ if present)
        set -l commands
        for line in $selected
            set -l cmd (string replace -r '^.*│ (?:\e\[31m✗\e\[0m )?' '' -- $line)
            set -a commands $cmd
        end
        commandline --replace -- (string join \n $commands)
    end

    commandline -f repaint
end
