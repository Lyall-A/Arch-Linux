#!/bin/bash
# Routes audio sources to correct links

routes_location="$(dirname "$0")/routes" # Routes location
interval=1 # How often to monitor

while true; do
    sleep $interval

    # Get all nodes from PipeWire dump
    nodes=$(echo "$(pw-dump)" | jq -r '.[] | select(.type == "PipeWire:Interface:Node") | [ .id, .info.props["node.name"], .info.props["application.name"], .info.props["application.process.binary"] ] | @tsv')
    
    # Read routes
    routes=$(grep -vE "^(\s*|#.*)$" "$routes_location")

    declare -A node_name_map
    declare -A application_name_map
    declare -A application_process_binary_map

    # Loop through each node
    while IFS=$'\t' read -r id node_name application_name application_process_binary; do
        if [ -n "$node_name" ]; then node_name_map["$node_name"]=$id; fi
        if [ -n "$application_name" ]; then application_name_map["$application_name"]=$id; fi
        if [ -n "$application_process_binary" ]; then application_process_binary_map["$application_process_binary"]=$id; fi
    done <<< "$nodes"

    # Loop through each route
    while IFS= read -r line; do
        route_from=$(echo "$line" | awk -F" : " '{print $1}')
        route_to=$(echo "$line" | awk -F" : " '{print $2}')
        route_from_type=$(echo "$line" | awk -F" : " '{print $3}')
        route_to_type=$(echo "$line" | awk -F" : " '{print $4}')

        # Defaults
        route_from_type=${route_from_type:-1}
        route_to_type=${route_to_type:-1}

        case $route_from_type in
            1) from_id=${node_name_map["$route_from"]} ;;
            2) from_id=${application_name_map["$route_from"]} ;;
            3) from_id=${application_process_binary_map["$route_from"]} ;;
        esac

        case $route_to_type in
            1) to_id=${node_name_map["$route_to"]} ;;
            2) to_id=${application_name_map["$route_to"]} ;;
            3) to_id=${application_process_binary_map["$route_to"]} ;;
        esac

        if [[ -n "$from_id" && -n "$to_id" ]]; then
            # Link the nodes
            pw-link "$from_id" "$to_id" &> /dev/null &
        fi
    done <<< "$routes"
done
