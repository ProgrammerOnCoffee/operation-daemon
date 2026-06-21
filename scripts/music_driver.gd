class_name MusicDriver extends AudioStreamPlayer
## Manages the vertical adaptive music.

@export var tracks:Dictionary[String, AudioStreamOggVorbis]
## Offset a [member tracks] track's volume by a certain amount when audible, in db. 
@export var track_volume_offsets:Dictionary[String,float]
@export var initial_track:String

## Index to stream stuff.
var stream_names:Array[String]

var bpm:float
var bar_beats:float

var beat:float:
	set(to):
		beat_delta = abs(beat - to)
		beat = to
var beat_delta:float
var bar:float

var current_stream:int = 0
var stream_buffer:int = -1

var transition_start_bar:float

func _ready() -> void:
	stream = AudioStreamSynchronized.new()
	
	var keys := tracks.keys()
	stream.stream_count = keys.size()
	for i in keys.size():
		stream.set_sync_stream(i, tracks[keys[i]])
		stream.set_sync_stream_volume(i, linear_to_db(0.0))
	
	current_stream = get_stream_index(initial_track)
	
	play()
	
	# Grab the bpm and bar_beats from the substreams.
	for i in stream.stream_count:
		var substream := stream.get_sync_stream(i) as AudioStreamOggVorbis
		
		if substream.bpm       and not bpm:       bpm       = substream.bpm
		if substream.bar_beats and not bar_beats: bar_beats = substream.bar_beats
		
		# Both have been found, stop looking.
		if bar_beats and bpm: break
	
	stream_names.resize(stream.stream_count)
	for string in tracks.keys():
		stream_names[get_stream_index(string)] = string
	
	Global.request_track_transition.connect(buffer_stream_name)

func _process(_delta: float) -> void: if stream is AudioStreamSynchronized:
	
	## Debug to allow switching track w/ an input.
	#if Input.is_action_just_pressed("qte_press"): buffer_stream(1 - current_stream)
	
	#print("S2 ",  (get_playback_position() +  AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()) * bpm / 60)
	beat = (get_playback_position() +  AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()) * bpm / 60
	bar = beat / bar_beats
	
	#print(bar)
	
	# The only way the start of the transition is over 1u away
	# is if the track just looped.
	if abs(transition_start_bar - bar) > 1:
		transition_start_bar = ceil(bar)
	
	# Resolve buffers
	if stream_buffer != -1 and transition_start_bar != -1 and bar >= transition_start_bar:
		current_stream = stream_buffer
		
		if buffer_should_reset:
			play(0.0)
		
		# Update the beepy em
		bpm = (stream.get_sync_stream(current_stream) as AudioStreamOggVorbis).bpm
		beat = (get_playback_position() +  AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()) * bpm / 60
		beat_delta = 0.0
		
		stream_buffer = -1
		transition_start_bar = -1
	
	# Manage track volumes for cross-fading. Takes 1 bar, using bar_delta.
	#print("BD\t", beat_delta)
	for i in stream.stream_count:
		#stream.set_sync_stream_volume(i, 0.0)
		#print(i,"=\t",stream.get_sync_stream_volume(i))
		var new_volume = linear_to_db(move_toward(db_to_linear(stream.get_sync_stream_volume(i) - (track_volume_offsets[stream_names[i]] if track_volume_offsets.has(stream_names[i]) else 0)), (i == current_stream) as int, beat_delta / bar_beats)) 
		#print(i,(i == current_stream) as int,":\t",db_to_linear(stream.get_sync_stream_volume(i)),"\t", new_volume)
		
		print("B4", new_volume)
		if track_volume_offsets.has(stream_names[i]):
			new_volume += track_volume_offsets[stream_names[i]]
		print("AF", new_volume)
		
		stream.set_sync_stream_volume(i, new_volume)

var buffer_should_reset := false
func buffer_stream(index:int, should_reset_track := false):
	buffer_should_reset = should_reset_track
	
	stream_buffer = index
	
	if transition_start_bar == -1:
		# Snap the transition start to the nearest half-bar after this.
		transition_start_bar = ceil(bar * 2) / 2

func buffer_stream_name(from_name:String): buffer_stream(get_stream_index(from_name))

func get_stream_index(from_name:String) -> int: 
	if stream is AudioStreamSynchronized:
		for i in stream.stream_count:
			if stream.get_sync_stream(i) == tracks[from_name]:
				return i
	return -1
