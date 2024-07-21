# My audio
## (it's slightly more difficult and annoying than Voicemeeter on Windows)

Audio setup on Linux using PipeWire, Carla, qpwgraph, xbindkeys, virtual sinks and virtual MIDI.

* Carla is being used as a plugin host
* qpwgraph is being used as a graph that automatically links all my applications
* Audio monitoring script automatically unlinks applications from default sink if it is also linked to anything else
* xbindkeys is being used to setup keyboard keybinds that send MIDI commands to plugins in Carla (such as volume control)
* Virtual sinks is mainly just to make things cleaner
* Virtual MIDI is for my keybinds