extends Resource

class_name QueueManager

var queue : Array[Song]
var song_register : Array[Song]
var registered_uids : Array[String]
func add_to_register(filepath:String):
	var song = Song.new(filepath)
	if song.valid:
		song_register.append(song)



class Song:
	var uid : String = ""
	var name : String = "":
		get():
			if not _is_metadata_fetched:
				update_metadata()
			return name
	var album : String = "":
		get():
			if not _is_metadata_fetched:
				update_metadata()
			return album
	var artist : String = "":
		get():
			if not _is_metadata_fetched:
				update_metadata()
			return artist
	var filepath : String = ""
	var _is_metadata_fetched: bool = false
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
		var meta = MusicMeta.get_mp3_metadata(AudioStreamMP3.load_from_file(filepath))
		album = meta.album
		name = meta.title if meta.title != "" else filepath.get_file().trim_suffix(".mp3").capitalize()
		artist = meta.artist
		_is_metadata_fetched = true
	
	func as_audiostream() -> AudioStreamMP3:
		if valid:
			return AudioStreamMP3.load_from_file(filepath)
		else:
			return AudioStreamMP3.new()
	
	func _init(p_filepath:String) -> void:
		if not FileAccess.file_exists(p_filepath) or not p_filepath.ends_with(".mp3"):
			Autoload.logger("Song() instance could not be created successfully as "+p_filepath+" is not a valid filepath",Autoload.LOG_LEVEL.ERROR,"CLASS_INIT_SONG")
			return
		
		filepath = p_filepath
		
		valid = true
