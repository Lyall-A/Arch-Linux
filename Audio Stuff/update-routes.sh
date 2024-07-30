#!/bin/bash
# Routes audio sources to correct links

routes_location="$(dirname "$0")/routes" # Routes location
interval=0 # How often to monitor

while true; do
    sleep $interval
    # Dump PipeWire
    dump="$(pw-dump)"
    # Get all nodes
    nodes=$(echo "$dump" | jq -c '.[] | select(.type == "PipeWire:Interface:Node")')
    
    # Read routes
    routes=$(grep -vE "^(\s*|#.*)$" "$routes_location")

    declare -A node_name_map
    declare -A application_name_map
    declare -A application_process_binary_map

    # Loop through each node
    while IFS= read -r node; do
        id=$(echo "$node" | jq -r '.id')
        node_name=$(echo "$node" | jq -r '.info.props["node.name"]')
        application_name=$(echo "$node" | jq -r '.info.props["application.name"]')
        application_process_binary=$(echo "$node" | jq -r '.info.props["application.process.binary"]')

        node_name_map["$node_name"]=$id
        application_name_map["$application_name"]=$id
        application_process_binary_map["$application_process_binary"]=$id
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
            echo "Routing $from_id"
            pw-link $from_id $to_id &> /dev/null &
        fi
    done <<< "$routes"
done
