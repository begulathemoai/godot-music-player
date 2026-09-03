extends HBoxContainer

class_name LookupPath

@export var filepath : String = "":
	set(new_text):
		$TextDisplay.text = str(get_index()) +":"+new_text
		filepath = new_text
		tooltip_text = filepath
		$TextDisplay.tooltip_text = filepath
signal RemoveSelf
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$TextDisplay.text = str(get_index()+1) +":"+filepath
	tooltip_text = filepath
	$TextDisplay.tooltip_text = filepath



func _on_remove_self_pressed() -> void:
	RemoveSelf.emit(filepath)
	queue_free()
