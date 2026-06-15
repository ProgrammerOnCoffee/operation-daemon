class_name EventScene extends Node
# Literally just a signal bus for the end of the event.
# Emit the signal and the map will handle transitioning back to it and freeing the event scene
# (This will get recursively searched for, it just has to be in the event scene.)

@warning_ignore("unused_signal")
signal event_finished
