#!/bin/bash

#check open ports and log their status

set -e
#=========================

find_open_ports() {
    # check 1-65535 ports
    open_ports=()
    for port in {1..65535}; do
        (echo >/dev/tcp/localhost/$port) &>/dev/null && open_ports+=($port)
        echo -ne "Checking port $port\r"
    done
    if [ ${#open_ports[@]} -eq 0 ]; then
        echo "No open ports found."
    else
        echo "Open ports: ${open_ports[*]}"
    fi
}

find_open_ports
#=========================
# End of script 