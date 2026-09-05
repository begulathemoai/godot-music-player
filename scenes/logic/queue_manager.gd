extends Node

class_name QueueManager

var queue : Array[Song]
var song_register : Array[Song]
var registered_uids : Array[String]
var thread : Thread
var fetch_queue : Array[Song]


func _init() -> void:
	thread = Thread.new()

func _process(delta: float) -> void:
	await _fetcher()

func add_to_register(filepath:String):
	var song = Song.new(filepath)
	if song.valid:
		song_register.append(song)
		song.queue_fetch.connect(request_metadata.bind(song))

func add_to_queue_and_play(uid:String) -> AudioStreamMP3:
	for i in song_register:
		if i.uid == uid:
			queue.append(i)
			return i.as_audiostream()
	
	return null

func clear_queue() -> void:
	queue = []

func get_song_stream(stream:AudioStreamMP3) -> Song:
	var path = stream.resource_path
	if path == null:
		return null
	return get_song_filepath(path)

func get_song_uid(uid:String) -> Song:
	for i in song_register:
		if i.uid == uid:
			return i
	
	return null

func get_song_filepath(filepath:String) -> Song:
	for i in song_register:
		if i.filepath == filepath:
			return i
	
	return null

func request_metadata(song:Song) -> void:
	fetch_queue.append(song)

func _fetcher() -> void:
	if len(fetch_queue) > 0:
		var song : Song = fetch_queue.pop_front()
		thread.start(_get_metadata.bind(song))
		
		await thread.wait_to_finish()
		song.queue_fetch_finished.emit()

func _get_metadata(song:Song) -> void:
	song.edit_lock.lock()
	if not song.valid:
		Autoload.logger("Metadata could not be updated successfully as "+song.filepath+" is not a valid filepath",Autoload.LOG_LEVEL.ERROR,"CLASS_SONG")
		song.valid = false
		return
	var meta = MusicMeta.get_mp3_metadata(AudioStreamMP3.load_from_file(song.filepath))
	song.album = meta.album
	song.name = meta.title if meta.title != "" else song.filepath.get_file().trim_suffix(".mp3").capitalize()
	song.artist = meta.artist
	song._is_metadata_fetch_complete = true
	
	song.edit_lock.unlock()

class Song:
	var uid : String = ""
	var edit_lock : Mutex = Mutex.new()
	var name : String = "":
		get():
			if not _is_metadata_fetched:
				update_metadata()
			if not _is_metadata_fetch_complete:
				return "loading"
			return name
	var album : String = "":
		get():
			if not _is_metadata_fetched:
				update_metadata()
			if not _is_metadata_fetch_complete:
				return "loading"
			return album
	var artist : String = "":
		get():
			if not _is_metadata_fetched:
				update_metadata()
			if not _is_metadata_fetch_complete:
				return "loading"
			return artist
	var filepath : String = ""
	var _is_metadata_fetched: bool = false
	var _is_metadata_fetch_complete : bool = false
	signal queue_fetch
	signal queue_fetch_finished
	var valid : bool = false:
		get():
			if not FileAccess.file_exists(filepath):
				valid = false
			return valid
	
	func update_metadata() -> void:
		if not valid:
			Autoload.logger("Metadata could not be updated successfully as "+filepath+" is not a valid filepath",Autoload.LOG_LEVEL.ERROR,"CLASS_SONG")
			valid = false
			return
		queue_fetch.emit()
		_is_metadata_fetched = true
	
	func _fetch_complete() -> void:
		_is_metadata_fetch_complete = true
		queue_fetch_finished.emit()
	
	func as_audiostream() -> AudioStreamMP3:
		if valid:
			return AudioStreamMP3.load_from_file(filepath)
		else:
			return null
	
	func _init(p_filepath:String) -> void:
		if not FileAccess.file_exists(p_filepath) or not p_filepath.ends_with(".mp3"):
			Autoload.logger("Song() instance could not be created successfully as "+p_filepath+" is not a valid filepath",Autoload.LOG_LEVEL.ERROR,"CLASS_INIT_SONG")
			return
		
		filepath = p_filepath
		
		valid = true
