extends Node
var mouse_pos : Vector2 = Vector2.ZERO
var focus_pos : Vector2 = Vector2.ZERO
@onready var main = get_tree().get_root().get_node("Main")
enum LOG_LEVEL {
	VERBOSE=1,
	INFO=2,
	WARNING=3,
	ERROR=4,
	NONE=5
}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	mouse_pos = get_viewport().get_mouse_position()
	if get_viewport().gui_get_focus_owner() != null:
		if get_viewport().gui_get_focus_owner() in get_tree().get_root().get_node("Main").get_node("%SongList").get_children():
			focus_pos = get_viewport().gui_get_focus_owner().global_position
		else:
			focus_pos = Vector2(-1000000,-1000000)

func logger(text:String,level:LOG_LEVEL=LOG_LEVEL.INFO,type:String="") -> void:
	type = type.to_upper()
	
	if level == LOG_LEVEL.NONE:
		logger("A log cannot be created with LOG_LEVEL.NONE !",LOG_LEVEL.ERROR,"LOGGING")
	
	var can_log : bool = true
	if main.custom_logging_level.has(type):
		if level < main.custom_logging_level[type]:
			can_log = false
	
	if level >= main.logging_level and can_log:
		if level == LOG_LEVEL.VERBOSE:
			print_rich("[color=Dimgray]<VERBOSE> : "+text+"[/color]") if type == "" else print_rich("[color=Dimgray]<VERBOSE>{"+type+"} : "+text+"[/color]")
		elif level == LOG_LEVEL.INFO:
			print_rich("<INFO> : "+text) if type == "" else print_rich("<INFO>{"+type+"} : "+text)
		elif level == LOG_LEVEL.WARNING:
			print_rich("[color=yellow]<WARNING> : "+text+"[/color]") if type == "" else print_rich("[color=yellow]<WARNING>{"+type+"} : "+text+"[/color]")
		elif level == LOG_LEVEL.ERROR:
			print_rich("[color=red]<ERROR> : "+text+"[/color]") if type == "" else print_rich("[color=red]<ERROR>{"+type+"} : "+text+"[/color]")
