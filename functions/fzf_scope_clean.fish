function fzf_scope_clean --description "Manage fzf-scope history log"
    set -l subcmd $argv[1]

    if not test -f $fzf_scope_file
        echo "fzf-scope: No log file found at $fzf_scope_file"
        return 1
    end

    switch $subcmd
        case prune
            # Keep only the most recent max_entries
            set -l total (wc -l < $fzf_scope_file)
            if test $total -gt $fzf_scope_max_entries
                set -l to_remove (math $total - $fzf_scope_max_entries)
                tail -n $fzf_scope_max_entries $fzf_scope_file > $fzf_scope_file.tmp
                mv $fzf_scope_file.tmp $fzf_scope_file
                echo "Pruned $to_remove entries, kept $fzf_scope_max_entries"
            else
                echo "Log has $total entries (max: $fzf_scope_max_entries), no pruning needed"
            end

        case project
            if test -z "$argv[2]"
                echo "Usage: fzf_scope_clean project <path>"
                return 1
            end
            set -l project_path $argv[2]
            set -l before (wc -l < $fzf_scope_file)
            awk -F'\t' -v root="$project_path" '$2 != root' $fzf_scope_file > $fzf_scope_file.tmp
            mv $fzf_scope_file.tmp $fzf_scope_file
            set -l after (wc -l < $fzf_scope_file)
            echo "Removed "(math $before - $after)" entries for $project_path"

        case older-than
            if test -z "$argv[2]"
                echo "Usage: fzf_scope_clean older-than <days>"
                return 1
            end
            set -l days $argv[2]
            set -l cutoff (math (date +%s) - $days \* 86400)
            set -l before (wc -l < $fzf_scope_file)
            awk -F'\t' -v cutoff="$cutoff" '$1 >= cutoff' $fzf_scope_file > $fzf_scope_file.tmp
            mv $fzf_scope_file.tmp $fzf_scope_file
            set -l after (wc -l < $fzf_scope_file)
            echo "Removed "(math $before - $after)" entries older than $days days"

        case stats
            set -l total (wc -l < $fzf_scope_file)
            set -l size (du -h $fzf_scope_file | cut -f1)
            echo "Log file: $fzf_scope_file"
            echo "Total entries: $total"
            echo "File size: $size"
            echo ""
            echo "Entries per project:"
            awk -F'\t' '{count[$2]++} END {for (p in count) printf "  %6d  %s\n", count[p], p}' $fzf_scope_file | sort -rn

        case ''
            echo "Usage: fzf_scope_clean <subcommand>"
            echo ""
            echo "Subcommands:"
            echo "  prune              Trim log to max entries (keeps most recent)"
            echo "  project <path>     Remove all entries for a specific project"
            echo "  older-than <days>  Remove entries older than N days"
            echo "  stats              Show log statistics"

        case '*'
            echo "Unknown subcommand: $subcmd"
            echo "Run 'fzf_scope_clean' for usage"
            return 1
    end
end
