import Quickshell
import Quickshell.Services.Pipewire

Scope {
    id: root

    property var sink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource
    property var outputs: Pipewire.nodes.values.filter(node => node.audio && node.isSink && !node.isStream)
    property var inputs: Pipewire.nodes.values.filter(node => node.audio && !node.isSink && !node.isStream)
    property real volume: sink && sink.audio ? sink.audio.volume : 0
    property bool muted: sink && sink.audio ? sink.audio.muted : false
    property string outputName: sink ? (sink.description || sink.nickname || sink.name) : "No output"
    property string inputName: source ? (source.description || source.nickname || source.name) : "No input"
    readonly property string health: sink && sink.audio ? "normal" : "unknown"

    function setVolume(value: real): void {
        if (!root.sink || !root.sink.audio)
            return;
        root.sink.audio.volume = Math.max(0, Math.min(1.5, value));
        root.sink.audio.muted = value <= 0;
    }

    function toggleMute(): void {
        if (root.sink && root.sink.audio)
            root.sink.audio.muted = !root.sink.audio.muted;
    }

    function selectOutput(node): void {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function selectInput(node): void {
        Pipewire.preferredDefaultAudioSource = node;
    }

    PwObjectTracker {
        objects: root.outputs.concat(root.inputs).concat([root.sink, root.source])
    }
}
