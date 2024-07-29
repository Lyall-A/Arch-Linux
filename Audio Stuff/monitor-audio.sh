#!/bin/bash
# Monitors for new audio sources and changes the route to default sink depending on if it is linked to anything else

interval=1 # How often to monitor

while true; do
    sleep $interval
    # Dump PipeWire
    dump="$(pw-dump)"
    # Get all node ID's
    filtered_nodes_ids=$(echo "$dump" | jq -r '.[] | select(.type == "PipeWire:Interface:Node" and .info.props["node.name"] and .info.props["media.class"] == "Stream/Output/Audio") .id')
    # Get default sink ID
    sink_id=$(echo "$dump" | jq -r --arg name $(pactl info | grep "Default Sink" | awk -F': ' '{print $2}') 'first(.[] | select(.type == "PipeWire:Interface:Node" and .info.props["node.name"] == $name and .info.props["media.class"] == "Audio/Sink") .id)')

    # Loop through each node
    for id in $filtered_nodes_ids; do
        # Check if node is linked to default sink
        linked_to_sink=$(echo "$dump" | jq -r --arg id "$id" --arg sink_id "$sink_id" 'any(.[]; .type == "PipeWire:Interface:Link" and .info["output-node-id"] == ($id | tonumber) and .info["input-node-id"] == ($sink_id | tonumber))')
        # Check if node is linked to anything else
        linked_to_other=$(echo "$dump" | jq -r --arg id "$id" --arg sink_id "$sink_id" 'any(.[]; .type == "PipeWire:Interface:Link" and .info["output-node-id"] == ($id | tonumber) and .info["input-node-id"] != ($sink_id | tonumber))')
        # echo "Node ID: ${id}, linked to default sink: ${linked_to_sink}, linked to other: ${linked_to_other}"

        # Unlink from default sink if linked to anything else
        if [[ $linked_to_sink = true && $linked_to_other = true ]]; then
            echo "Unlinking $id from default sink"
            pw-link -d $id $sink_id
        else
            # Link to default sink if not linked to anything else
            if [[ $linked_to_sink = false && $linked_to_other = false ]]; then
                echo "Linking $id to default sink"
                pw-link $id $sink_id
            fi
        fi
    done
done