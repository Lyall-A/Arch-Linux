#!/bin/bash
# Monitors for new audio sources and unlinks it from the default sink if it is also linked to anything else

while true
do
    previous_sources=$(pw-dump | jq -r '.[] | select(.type == "PipeWire:Interface:Node" and .info.props["node.name"] and .info.props["media.class"] == "Stream/Output/Audio") .id')
    sleep 1
    current_sources=$(pw-dump | jq -r '.[] | select(.type == "PipeWire:Interface:Node" and .info.props["node.name"] and .info.props["media.class"] == "Stream/Output/Audio") .id')
    sink_id=$(pw-dump | jq -r --arg name $(pactl info | grep "Default Sink" | awk -F': ' '{print $2}') '.[] | select(.info.props["node.name"] == $name) .id')

    for id in $current_sources
    do
        if ! echo "$previous_sources" | grep -q "$id"
        then
            linked_to_sink=$(pw-dump | jq -r --arg id "$id" --arg sink_id "$sink_id" 'first(.[] | select(.type == "PipeWire:Interface:Link" and .info["output-node-id"] == ($id | tonumber) and .info["input-node-id"] == ($sink_id | tonumber)) .info["input-node-id"] == ($sink_id | tonumber))')
            linked_to_other=$(pw-dump | jq -r --arg id "$id" --arg sink_id "$sink_id" 'first(.[] | select(.type == "PipeWire:Interface:Link" and .info["output-node-id"] == ($id | tonumber) and .info["input-node-id"] != ($sink_id | tonumber)) .info["input-node-id"] != ($sink_id | tonumber))')

            if [[ $linked_to_sink == true && $linked_to_other == true ]]
            then
            echo "Unlinking $id from default sink"
                pw-link -d $id $sink_id
            fi
        fi
    done
done