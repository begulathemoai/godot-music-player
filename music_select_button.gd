extends Control

class_name MusicSelectButton

@export var filepath : String = ""
signal activated


func _on_pressed() -> void:
	activated.emit(self,filepath)

func _ready() -> void:
	$Button.text = filepath.get_file().trim_suffix("."+filepath.get_extension())
	
func _process(delta) -> void:
	self.custom_minimum_size.y = $Button.get_minimum_size().y
	var alpha : float
	if get_viewport().gui_get_focus_owner() != null:
		alpha = max(0.20,remap(abs(global_position.y-Autoload.mouse_pos.y),0.0,get_viewport().size.y,1.0,0.0)**2,remap(abs(global_position.y-Autoload.focus_pos.y),0.0,get_viewport().size.y,1.0,0.0))
	else:
		alpha = max(0.20,remap(abs(global_position.y-Autoload.mouse_pos.y),0.0,get_viewport().size.y,1.0,0.0)**2)
	$Button.modulate = Color(1.0,1.0,1.0,alpha) 

func is_from(folder:String) -> bool:
	return folder.trim_suffix("/") == filepath.get_base_dir()

func update_text():
	$Button.text = filepath.get_file().trim_suffix("."+filepath.get_extension())
