#!/bin/bash
source scripts/lib/common.sh

echo "=== Testing Workers Section ==="

remote_workers_conf="$HOME/.cluster_config/nodes_list.conf"
total_workers=0
online_workers=0
offline_workers=0

echo "Checking remote workers config..."
if [ -f "$remote_workers_conf" ]; then
    echo "File exists: $remote_workers_conf"
    echo "Content:"
    cat "$remote_workers_conf"
    echo ""

    echo "Processing workers..."
    while IFS= read -r line; do
        echo "Processing line: '$line'"
        if [[ $line =~ ^# ]] || [ -z "$line" ]; then
            echo "  Skipping comment/empty line"
            continue
        fi

        # Parse the line
        name=""
        alias=""
        ip=""
        user=""
        port=""
        status=""
        read -r name alias ip user port status <<< "$line"
        echo "  Parsed: name='$name', alias='$alias', ip='$ip', user='$user', port='$port', status='$status'"
        ((total_workers++))

        echo "  Testing connection to $user@$ip:$port..."
        if timeout 5 ssh -o BatchMode=yes -o ConnectTimeout=2 -o StrictHostKeyChecking=no -p "$port" "$user@$ip" "echo 'OK'" >/dev/null 2>&1; then
            echo "  Result: ONLINE"
            ((online_workers++))
        else
            echo "  Result: OFFLINE"
            ((offline_workers++))
        fi
    done < <(grep -vE '^\s*#|^\s*$' "$remote_workers_conf")
else
    echo "File does not exist: $remote_workers_conf"
fi

echo ""
echo "Summary: Total=$total_workers, Online=$online_workers, Offline=$offline_workers"
