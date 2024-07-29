#!/bin/bash
# Routes audio sources to correct links

routes_location="$(dirname "$0")/routes" # Routes location
interval=1 # How often to monitor

while true; do
    sleep $interval
    # Dump PipeWire
    dump="$(pw-dump)"
    # Get all node ID's
    filtered_nodes_ids=$(echo "$dump" | jq -r '.[] | select(.type == "PipeWire:Interface:Node") .id')

    # Loop through each node
    for id in $filtered_nodes_ids; do
        # Get node details
        node=$(echo "$dump" | jq -r --arg id "$id" '.[] | select(.id == ($id | tonumber))')
        node_name=$(echo "$node" | jq -r '.info.props["node.name"]') # Type 1
        application_name=$(echo "$node" | jq -r '.info.props["application.name"]') # Type 2
        application_process_binary=$(echo "$node" | jq -r '.info.props["application.process.binary"]') # Type 3
        
        # Loop through each route
        grep -vE "^(\s*|#.*)$" "$routes_location" | while read line; do
            # Get route details
            route_from=$(echo "$line" | awk -F" : " '{print $1}')
            route_to=$(echo "$line" | awk -F" : " '{print $2}')
            route_from_type=$(echo "$line" | awk -F" : " '{print $3}')
            route_to_type=$(echo "$line" | awk -F" : " '{print $4}')

            # Defaults
            if [ "$route_from_type" = "" ]; then route_from_type=1; fi
            if [ "$route_to_type" = "" ]; then route_to_type=1; fi

            if [[( $route_from = $node_name && $route_from_type = 1 ) || ( $route_from = $application_name && $route_from_type = 2 ) || ( $route_from = $application_process_binary && $route_from_type = 3 ) ]]; then
                # Node matches route, get route to ID
                if [ "$route_to_type" = 1 ]; then
                    route_to_node_id=$(echo "$dump" | jq -r  --arg route_to "$route_to" 'first(.[] | select(.type == "PipeWire:Interface:Node" and .info.props["node.name"] == $route_to) .id)')
                else
                if [ "$route_to_type" = 2 ]; then
                    route_to_node_id=$(echo "$dump" | jq -r  --arg route_to "$route_to" 'first(.[] | select(.type == "PipeWire:Interface:Node" and .info.props["application.name"] == $route_to) .id)')
                else
                if [ "$route_to_type" = 3 ]; then
                    route_to_node_id=$(echo "$dump" | jq -r  --arg route_to "$route_to" 'first(.[] | select(.type == "PipeWire:Interface:Node" and .info.props["application.process.binary"] == $route_to) .id)')
                fi
                fi
                fi

                if [ "$route_to_node_id" != "" ]; then
                    # Link
                    pw-link $id $route_to_node_id &> /dev/null &
                    # pw-link $id $route_to_node_id &
                fi
            fi
        done
    done
done