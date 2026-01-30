#!/bin/bash

# Generic function to monitor a process and execute a command after it finishes
# Uses ENV var WAIT_PERSISTENCE (default: 10) for the grace period
# Uses ENV var WAIT_TIMEOUT (optional) to force execution after X seconds
# Usage: wait_and_run <proc_name> <command>
wait_and_run() {
    local proc_name="$1"
    local exec_cmd="$2"
    
    local persistence="${WAIT_PERSISTENCE:-10}"
    local timeout="${WAIT_TIMEOUT:-0}"
    local check_interval=5
    local start_time=$(date +%s)

    # 1. Pre-request sudo and keep it alive
    echo "Refreshing sudo credentials..."
    if sudo -v; then
        ( while true; do sudo -v; sleep 60; done ) &
        local sudo_keepalive_pid=$!
        trap "kill $sudo_keepalive_pid 2>/dev/null" EXIT RETURN
    else
        echo "Sudo failed. Proceeding without elevated keep-alive."
    fi

    echo "Monitoring for: '$proc_name'"
    echo "Persistence: ${persistence}s | Timeout: ${timeout:-None}s"

    # 2. Main Monitoring Loop
    while true; do
        # Check for Global Timeout
        if [ "$timeout" -gt 0 ]; then
            local current_time=$(date +%s)
            local total_elapsed=$((current_time - start_time))
            if [ "$total_elapsed" -ge "$timeout" ]; then
                echo "Wait timeout of ${timeout}s reached. Forcing execution..."
                break
            fi
        fi

        if pgrep -x "$proc_name" > /dev/null; then
            # Process exists, keep waiting
            sleep "$check_interval"
        else
            # Process not found, start the persistence countdown
            local p_elapsed=0
            local confirmed_gone=true
            
            while [ "$p_elapsed" -lt "$persistence" ]; do
                sleep 1
                if pgrep -x "$proc_name" > /dev/null; then
                    confirmed_gone=false
                    echo "Process '$proc_name' reappeared. Resetting wait..."
                    break
                fi
                ((p_elapsed++))
            done

            if [ "$confirmed_gone" = true ]; then
                break
            fi
        fi
    done

    # 3. Cleanup and Execute
    [ -n "$sudo_keepalive_pid" ] && kill "$sudo_keepalive_pid" 2>/dev/null
    echo "Condition met. Executing action..."
    
    eval "$exec_cmd"
}
