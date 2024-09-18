// Rewrite of monitor-audio, update-midi, update-routes scripts in JS
const cp = require("child_process");
const path = require("path");
const fs = require("fs/promises");

const pactlInterval = 5000;
const pwDumpInterval = 250;
const linkCheckInterval = 250;
const defaultMidiValue = 127;
const macrosLocation = path.resolve(__dirname, "macros");
const macroSavesLocation = path.resolve(__dirname, "macro-saves");
const midiUpdateInterval = 5000;

const pactl = {
    defaultSink: { },
    defaultSource: { }
};
let rawPwDump;
const pwDump = {
    nodes: [],
    links: [],
    sinks: [],
    outputs: [],
    sources: [],
};

(function checkLinks() {
    for (const output of pwDump.outputs) {
        const linkedToSink = pwDump.links.find(i => i.info["input-node-id"] === pactl.defaultSink.id && i.info["output-node-id"] === output.id);
        const linkedToOther = pwDump.links.find(i => i.info["input-node-id"] !== pactl.defaultSink.id && i.info["output-node-id"] === output.id);

        // Unlink from default sink if linked to something else, or link to default sink if linked to nothing
        if (linkedToOther && linkedToSink) {
            console.log(`Unlinking ID ${output.id} (${output.info.props["node.name"]}) from default sink ID ${pactl.defaultSink.id} (${pactl.defaultSink.info.props["node.name"]})`);
            unlink(output.id, pactl.defaultSink.id);
        } else
        if (!linkedToOther && !linkedToSink) {
            console.log(`Linking ID ${output.id} (${output.info.props["node.name"]}) to default sink ID ${pactl.defaultSink.id} (${pactl.defaultSink.info.props["node.name"]})`);
            link(output.id, pactl.defaultSink.id);
        }
    }

    // TODO: sources

    setTimeout(checkLinks, linkCheckInterval);
})();

(async function updateMidi() {
    // const macrosFile = (await fs.readFile(macrosLocation, "utf-8")).replace(/\s*#.*/g, "");
    // console.log(macrosFile)
})();

(function updatePwDump() {
    cp.exec("pw-dump", (err, stdout, stderr) => {
        try {
            rawPwDump = JSON.parse(stdout);

            pwDump.nodes = rawPwDump.filter(i => i.type === "PipeWire:Interface:Node");
            pwDump.links = rawPwDump.filter(i => i.type === "PipeWire:Interface:Link");
            pwDump.sinks = pwDump.nodes.filter(i => i.info.props["media.class"] === "Audio/Sink");
            pwDump.sources = pwDump.nodes.filter(i => i.info.props["media.class"] === "Audio/Source");
            pwDump.outputs = pwDump.nodes.filter(i => i.info.props["media.class"] === "Stream/Output/Audio");
        } catch (err) { };

        setTimeout(updatePwDump, pwDumpInterval);
    });
})();

(function updatePactl() {
    cp.exec("pactl info", (err, stdout, stderr) => {
        try {
            pactl.defaultSink = pwDump.sinks.find(i => i.info.props["node.name"] === stdout.match(/Default Sink: (.*)/)[1]) || pactl.defaultSink;
            pactl.defaultSource = pwDump.sources.find(i => i.info.props["node.name"] === stdout.match(/Default Source: (.*)/)[1]) || pactl.defaultSource;
        } catch (err) { };

        setTimeout(updatePactl, pactlInterval);
    });
})();

function unlink(output, input) {
    cp.exec(`pw-link -d ${output} ${input}`);
}

function link(output, input) {
    cp.exec(`pw-link ${output} ${input}`);
}