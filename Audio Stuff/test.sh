#!/bin/bash
# Monitors for new audio sources and changes the route to default sink depending on if it is linked to anything else

# interval=1 # How often to monitor

# while true; do
    # sleep $interval
    
    # Parse PipeWire dump
    dump=$(echo "$(pw-dump)" | jq -r '
        {
            output_ids: [ .[] | select(.type == "PipeWire:Interface:Node" and .info.props["media.class"] == "Stream/Output/Audio") .id ],
            source_ids: [ .[] | select(.type == "PipeWire:Interface:Node" and .info.props["media.class"] == "Audio/Source") .id ],
            sinks: [ .[] | select(.type == "PipeWire:Interface:Node" and .info.props["media.class"] == "Audio/Sink") | { id: .id, name: .info.props["node.name"] } ],
            sources: [ .[] | select(.type == "PipeWire:Interface:Node" and .info.props["media.class"] == "Audio/Source") | { name: .info.props["node.name"], client_id: .info.props["client.id"] } ],
            inputs: [ .[] | select(.type == "PipeWire:Interface:Node" and .info.props["media.class"] == "Stream/Input/Audio") | { id: .id, client_id: .info.props["client.id"] } ],
            links: [ .[] | select(.type == "PipeWire:Interface:Link") | { input_node_id: .info["input-node-id"], output_node_id: .info["output-node-id"] } ]
        }
    ')

    # Get node ID's
    output_ids=$(echo "$dump" | jq -r '.output_ids[]')
    source_ids=$(echo "$dump" | jq -r '.source_ids[]')
    
    # Get default sink ID
    sink_name=$(pactl info | grep "Default Sink" | awk -F': ' '{print $2}')
    sink_id=$(echo "$dump" | jq -r --arg name "$sink_name" 'first(.sinks[] | select(.name == $name) .id)')
    
    # Get default source client ID
    source_name=$(pactl info | grep "Default Source" | awk -F': ' '{print $2}')
    source_client_id=$(echo "$dump" | jq -r --arg name "$source_name" 'first(.sources[] | select(.name == $name) .client_id)')
    
    # Get default input source ID
    input_source_id=$(echo "$dump" | jq -r --arg client_id "$source_client_id" 'first(.inputs[] | select(.client_id == ($client_id | tonumber)) .id)')

    # Loop through each output node
    for id in $output_ids; do
        # Check node links
        linked_to_sink=$(echo "$dump" | jq -r --arg id "$id" --arg sink_id "$sink_id" 'any(.links[]; .output_node_id == ($id | tonumber) and .input_node_id == ($sink_id | tonumber))')
        linked_to_other=$(echo "$dump" | jq -r --arg id "$id" --arg sink_id "$sink_id" 'any(.links[]; .output_node_id == ($id | tonumber) and .input_node_id != ($sink_id | tonumber))')

        # Unlink from default sink if linked to anything else
        if [[ "$linked_to_sink" = true && "$linked_to_other" = true ]]; then
            echo "Unlinking ID '$id' from default sink"
            pw-link -d $id $sink_id &
        else
            # Link to default sink if not linked to anything else
            if [[ "$linked_to_sink" = false && "$linked_to_other" = false ]]; then
                echo "Linking ID '$id' to default sink"
                pw-link $id $sink_id &
            fi
        fi
    done

    # Loop through each source node
    for id in $source_ids; do
        # Check node links
        linked_to_source=$(echo "$dump" | jq -r --arg id "$id" --arg source_id "$input_source_id" 'any(.links[]; .output_node_id == ($id | tonumber) and .input_node_id == ($source_id | tonumber))')
        linked_to_other=$(echo "$dump" | jq -r --arg id "$id" --arg source_id "$input_source_id" 'any(.links[]; .output_node_id == ($id | tonumber) and .input_node_id != ($source_id | tonumber))')

        # Unlink from default source if linked to anything else
        if [[ "$linked_to_source" = true && "$linked_to_other" = true ]]; then
            echo "Unlinking ID '$id' from default source"
            pw-link -d $id $input_source_id &
        fi
    done
# done