class_name MusicDriver extends AudioStreamPlayer
## Manages the vertical adaptive music.

@export var tracks:Dictionary[String, AudioStreamOggVorbis]

var bpm:float
var bar_beats:int

var beat:float
var bar:int

var current_stream:int = 0
var stream_buffer:int = -1

var transition_start_bar:float

func _ready() -> void:
	stream = AudioStreamSynchronized.new()
	
	var keys := tracks.keys()
	stream.stream_count = keys.size()
	for i in keys.size():
		stream.set_sync_stream(i, tracks[keys[i]])
	
	
	play()
	
	# Grab the bpm and bar_beats from the substreams.
	for i in stream.stream_count:
		var substream := stream.get_sync_stream(i) as AudioStreamOggVorbis
		
		if substream.bpm       and not bpm:       bpm       = substream.bpm
		if substream.bar_beats and not bar_beats: bar_beats = substream.bar_beats
		
		# Both have been found, stop looking.
		if bar_beats and bpm: break
	
	_set_stream_to(0)
	
	Global.request_track_transition.connect(buffer_stream_name)

func _process(_delta: float) -> void:
	beat = (get_playback_position() +  AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()) * bpm / 60
	bar = floori(beat / bar_beats)
	
	# The only way the start of the transition is over 1u away
	# is if the track just looped.
	if abs(transition_start_bar - bar) > 1:
		transition_start_bar = ceil(bar)
	
	# Resolve
	if stream_buffer != -1 and transition_start_bar != -1 and bar >= transition_start_bar:
		_set_stream_to(stream_buffer)
		stream_buffer = -1
		transition_start_bar = -1

func _set_stream_to(index:int): if stream is AudioStreamSynchronized:
	current_stream = index
	for i in stream.stream_count:
		stream.set_sync_stream_volume(i, linear_to_db((i == index) as int))

func buffer_stream(index:int):
	
	stream_buffer = index
	
	if transition_start_bar == -1:
		transition_start_bar = ceil(bar)

func buffer_stream_name(from_name:String): buffer_stream(get_stream_index(from_name))

func get_stream_index(from_name:String) -> int: 
	if stream is AudioStreamSynchronized:
		for i in stream.stream_count:
			if stream.get_sync_stream(i) == tracks[from_name]:
				return i
	return -1
