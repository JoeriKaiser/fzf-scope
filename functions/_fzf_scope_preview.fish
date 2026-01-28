function _fzf_scope_preview --description "Generate preview for fzf-scope" --argument-names selected_line
    # Parse the selected line to extract session_id and timestamp
    # Format: "YYYY-MM-DD HH:MM │ ./path/ │ [✗] command"
    # We need to find this entry in the log and show adjacent session commands

    # Extract the command (everything after the last │)
    set -l cmd (string replace -r '^.*│ (?:\e\[31m✗\e\[0m )?' '' -- $selected_line)

    # Extract timestamp from the line (YYYY-MM-DD HH:MM)
    set -l display_ts (string match -r '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}' -- $selected_line)

    # Get project root
    set -l project_root (git rev-parse --show-toplevel 2>/dev/null; or echo $PWD)

    # Find matching entries in log and get session context
    # We need to find entries with the same session_id near this timestamp
    awk -F'\t' -v root="$project_root" -v cmd="$cmd" -v display_ts="$display_ts" '
    BEGIN {
        found_idx = -1
        count = 0
    }
    $2 == root {
        # Convert unix timestamp to display format for comparison
        ts_cmd = "date -d @" $1 " +\"%Y-%m-%d %H:%M\" 2>/dev/null"
        ts_cmd | getline formatted_ts
        close(ts_cmd)

        if (formatted_ts == display_ts && $6 == cmd) {
            found_idx = count
            found_session = $4
        }

        timestamps[count] = formatted_ts
        sessions[count] = $4
        exit_codes[count] = $5
        commands[count] = $6
        count++
    }
    END {
        if (found_idx == -1) {
            print "Command: " cmd
            exit
        }

        print "─── Session Context ───"
        print ""

        # Show 3 commands before and after from same session
        start = found_idx - 3
        if (start < 0) start = 0
        end = found_idx + 3
        if (end >= count) end = count - 1

        for (i = start; i <= end; i++) {
            if (sessions[i] == found_session) {
                prefix = "  "
                suffix = ""
                if (i == found_idx) {
                    prefix = "▶ "
                }
                if (exit_codes[i] != "0" && exit_codes[i] != "") {
                    suffix = "  ← failed (exit " exit_codes[i] ")"
                }
                print prefix commands[i] suffix
            }
        }

        print ""
        print "─── Syntax Highlighted ───"
        print ""
    }
    ' $fzf_scope_file

    # Syntax highlight the command
    echo $cmd | fish_indent --ansi
end
