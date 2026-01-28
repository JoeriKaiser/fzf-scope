function _fzf_scope_log --description "Log command with directory context and exit status" --argument-names exit_status cmd
    # Skip empty commands
    test -z "$cmd"; and return

    # Check against exclude patterns
    for pattern in $fzf_scope_exclude_patterns
        if string match -rq -- $pattern $cmd
            return
        end
    end

    # Determine project root (git root or PWD)
    set -l project_root (git rev-parse --show-toplevel 2>/dev/null)
    if test $status -ne 0
        set project_root $PWD
    end

    # Get Unix timestamp
    set -l timestamp (date +%s)

    # Ensure log directory exists
    set -l log_dir (dirname $fzf_scope_file)
    if not test -d $log_dir
        mkdir -p $log_dir
    end

    # Append to log file: timestamp<tab>project_root<tab>working_dir<tab>session_id<tab>exit_status<tab>command
    echo -e "$timestamp\t$project_root\t$PWD\t$fish_pid\t$exit_status\t$cmd" >> $fzf_scope_file
end
