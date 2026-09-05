extends Container
class_name PageContainer

var song_reg : Array[QueueManager.Song]:
	set(value):
		song_reg=value
		update_display()
var page = 0:
	set(value):
		$HBoxContainer/CenterContainer/HBoxContainer/Page.set_value_no_signal(value+1)
		page = value
		update_display()
var page_max = 0
var rows_per_page = 12
var min_size : int = 40
var line_ref : PackedScene = preload("res://scenes/ui/music_select_button.tscn")
var number_of_children
var mouse_inside : bool = false
@onready var callback : Callable = get_tree().get_root().get_node("Main")._on_one_of_the_buttons_pressed

func _ready() -> void:
	await get_tree().create_timer(0.1).timeout
	_on_resized()
	%Intro.play("intro")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	mouse_inside = get_rect().has_point(get_local_mouse_position())
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP) and mouse_inside:
		_on_right_pressed()
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN) and mouse_inside:
		_on_left_pressed()
	page_max = ceil(len(song_reg) / rows_per_page)
	if page > page_max:
		page=page_max
	if has_node("HBoxContainer/CenterContainer/HBoxContainer/DisplayMax"):
		$HBoxContainer/CenterContainer/HBoxContainer/DisplayMax.text = " / "+str(page_max+1)
	
	
	

func update_display():
	var inc = 0
	for i in get_children():
		if i is MusicSelectButton:
			if page*rows_per_page+inc > len(song_reg) - 1:
				i.get_node("Button").disabled = true
				i.song = null
				i.update_text()
			else:
				i.get_node("Button").disabled = false
				i.song = song_reg[page*rows_per_page+inc]
				i.update_text()
			inc += 1

func _on_left_pressed() -> void:
	page -= 1
	if page < 0:
		page = page_max

func _on_right_pressed() -> void:
	page += 1
	if page > page_max:
		page = 0


func _on_resized() -> void: 
	number_of_children = max(2,int(size.y / min_size))
	rows_per_page = number_of_children - 1
	if number_of_children < get_child_count():
		var to_del = get_child_count() - number_of_children
		for i in get_children():
			if i is MusicSelectButton:
				i.queue_free()
				to_del -= 1
			if to_del == 0:
				break
	elif number_of_children > get_child_count():
		while number_of_children > get_child_count():
			var new_child : MusicSelectButton = line_ref.instantiate()
			new_child.size_flags_vertical += Control.SIZE_EXPAND
			add_child(new_child)
			move_child(new_child,0)
			new_child.activated.connect(callback)
	update_display()


func _on_page_value_changed(value: float) -> void:
	page = int(value)-1
