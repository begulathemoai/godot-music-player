extends Control

class_name MusicSelectButton

@export var filepath : String = ""
var song : QueueManager.Song:
	set(val):
		if song is QueueManager.Song:
			song.queue_fetch_finished.disconnect(update_text)
		song=val
		if val is QueueManager.Song:
			if not is_node_ready():
				await ready
			song.queue_fetch_finished.connect(update_text)
signal activated


func _on_pressed() -> void:
	if song:
		activated.emit(self,song.filepath)

func _ready() -> void:
	if !song:return
	$Button.text = song.name if song.name != "" else song.filepath.get_file().trim_suffix("."+filepath.get_extension())
	
func _process(delta) -> void:
	self.custom_minimum_size.y = $Button.get_minimum_size().y
	var alpha : float
	if get_viewport().gui_get_focus_owner() != null:
		alpha = max(0.20,remap(abs(global_position.y-Autoload.mouse_pos.y),0.0,get_viewport().size.y,1.0,0.0)**2,remap(abs(global_position.y-Autoload.focus_pos.y),0.0,get_viewport().size.y,1.0,0.0))
	else:
		alpha = max(0.20,remap(abs(global_position.y-Autoload.mouse_pos.y),0.0,get_viewport().size.y,1.0,0.0)**2)
	$Button.modulate = Color(1.0,1.0,1.0,alpha) 

func is_from(folder:String) -> bool:
	if !song:return false
	return folder.trim_suffix("/") == song.filepath.get_base_dir()

func update_text():
	if !song:return
	print(get_children())
	$Button.text = song.name if song.name != "" else song.filepath.get_file().trim_suffix("."+filepath.get_extension())
