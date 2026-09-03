extends Node

var is_dragging : bool = false
var time_bar_pos : float = 0.0
var lookup_dirs : Array = []:
	set(new_value):
		_lookup_dirs(new_value)
		lookup_dirs = new_value
var music_menu_down : bool = false:
	set(value):
		if value:
			var twn = $"UI/Music Select".create_tween().set_parallel(true)
			twn.tween_property($"UI/Music Select","anchor_top",0.0,0.2)
			twn.tween_property($"UI/Music Select","anchor_bottom",1.0,0.2)
		else:
			$UI/MainButtonContainer/PauseButton.grab_focus()
			var twn = $"UI/Music Select".create_tween().set_parallel(true)
			twn.tween_property($"UI/Music Select","anchor_top",-1.0,0.2)
			twn.tween_property($"UI/Music Select","anchor_bottom",0.0,0.2)
		music_menu_down = value
var scanning : bool = false:
	set(value):
		$UI/LookupContainer/ScanningText.visible = value
		scanning = value
var is_typing : bool = false
@export var particle_curve : Curve
var background_color = null
var default_background_color = Color.from_hsv(0.66,1.0,1.0)
var color_exponents : Array[float] = [1.5,1.5,1.5]
var background_mode : String = "GRADIENT"
var current_index : int = -1
var random_mode : bool = false
var register : Array = []
## The general level of logging
@export var logging_level : Autoload.LOG_LEVEL = Autoload.LOG_LEVEL.VERBOSE
## Levels of logging for each log type
@export var custom_logging_level : Dictionary[String,Autoload.LOG_LEVEL] = {}
var dir = 0
var active = false:
	set(value):
		if value != active:
			if value == true:
				var tw = create_tween()
				tw.tween_property($Control,"modulate",Color.WHITE,0.5)
			else:
				var tw = create_tween()
				tw.tween_property($Control,"modulate",Color.TRANSPARENT,0.5)
		active = value
var config : Dictionary = {}

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if Input.is_action_just_pressed("key_pause") and not is_typing:
			$UI/MainButtonContainer/PauseButton.button_pressed = not $UI/MainButtonContainer/PauseButton.button_pressed


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in %SongList.get_children():
		if i is MusicSelectButton:
			i.activated.connect(_on_one_of_the_buttons_pressed)
	$Control.modulate = Color.TRANSPARENT
	music_menu_down = false
	$UI/LookupContainer/ScanningText.hide()
	$UI/LookupContainer/ScrollContainer/VBoxContainer/AddElementButton/Input.hide()
	if not DirAccess.dir_exists_absolute("user://config"):
		DirAccess.make_dir_absolute("user://config")
	
	if not FileAccess.file_exists("user://config/lookup_paths"):
		var fd = FileAccess.open("user://config/lookup_paths",FileAccess.WRITE)
		fd.store_line("")
		fd.close()
	
	load_and_apply_config()
	
	var lines : Array = FileAccess.get_file_as_string("user://config/lookup_paths").split("\n",false)
	for line in lines:
		if not DirAccess.dir_exists_absolute(line):continue
		var new_line : LookupPath = load("uid://b1u6xdn66w8jo").instantiate()
		$UI/LookupContainer/ScrollContainer/VBoxContainer.add_child(new_line)
		new_line.filepath = line
		lookup_dirs.append(line)
		new_line.connect("RemoveSelf",lookup_dir_removed)
	
	await _lookup_dirs(lookup_dirs)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("key_open_appdata_folder") and not is_typing:
		OS.shell_open(ProjectSettings.globalize_path("user://"))
	
	$Background/RichTextLabel.pivot_offset = $Background/RichTextLabel.size / 2
	$Control.pivot_offset = $Control.size / 2
	$Control.rotation_degrees += clamp(remap($FuckassVisualizer.strength+randf_range(0.0,0.1),0.0,2.0,0.0,1.0),0.0,1.0) * delta * 60
	#$Control.modulate.a = int(clamp(remap($FuckassVisualizer.strength,0.0,1.0,0.0,1.0),0.0,1.0))
	$Background.size = get_viewport().size
	$Background/GPUParticles2D.position = get_viewport().size / 2
	
	is_typing = $UI/LookupContainer/ScrollContainer/VBoxContainer/AddElementButton/Input.has_focus() or %Search.has_focus()
	#$Background/TextureRect.modulate.h += 0.004 * delta * 60
	#if $Background/TextureRect.modulate.h > 1.0:
		#$Background/TextureRect.modulate.h -= 1.0
	
	if $AudioStreamPlayer.stream != null:
		$UI/Time.text = format_time(int($AudioStreamPlayer.get_playback_position())) + "/" + format_time(int($AudioStreamPlayer.stream.get_length()))
	else:
		$UI/Time.text = "No stream loaded."
	if $UI/LookupContainer/ScrollContainer.custom_minimum_size.y != $UI/LookupContainer/ScrollContainer/VBoxContainer.size.y:
		$UI/LookupContainer/ScrollContainer.custom_minimum_size.y = $UI/LookupContainer/ScrollContainer/VBoxContainer.size.y
	
	
	if Input.is_action_just_pressed("key_music_menu") and not is_typing:
		music_menu_down = not music_menu_down
	
	if Input.is_action_just_pressed("key_reload_config") and not is_typing:
		load_and_apply_config()
	
	if Input.is_action_just_pressed("key_full_reload") and not is_typing:
		load_and_apply_config()
		reload()
	
	if Input.is_key_pressed(KEY_Q) and not is_typing:
		Autoload.logger("Quit key received, quitting...",Autoload.LOG_LEVEL.INFO,"SYSTEM")
		var stream = $AudioStreamPlayer.stream
		$AudioStreamPlayer.stop()
		$AudioStreamPlayer.stream = null
		get_tree().quit()
	
	check_active()
	
	if $AudioStreamPlayer.stream == null: return
	
	if $UI/MainButtonContainer/PauseButton.button_pressed != $AudioStreamPlayer.stream_paused:
		$AudioStreamPlayer.stream_paused = $UI/MainButtonContainer/PauseButton.button_pressed
	
	if $UI/MainButtonContainer/LoopButton.button_pressed != $AudioStreamPlayer.stream.loop:
		$AudioStreamPlayer.stream.loop = $UI/MainButtonContainer/LoopButton.button_pressed
	
	if $UI/HSlider.max_value != $AudioStreamPlayer.stream.get_length() :
		$UI/HSlider.max_value = $AudioStreamPlayer.stream.get_length()
	
	if not is_dragging:
		$UI/HSlider.value = lerp($UI/HSlider.value,$AudioStreamPlayer.get_playback_position(),0.2)
	
	
	if particle_curve != null:
		$Background/GPUParticles2D.amount_ratio = clamp(particle_curve.sample($FuckassVisualizer.strength),0.0,1.0)
	else:
		$Background/GPUParticles2D.amount_ratio = clamp(remap($FuckassVisualizer.strength,0.0,2.0,0.0,1.0),0.0,1.0)
	$Background/GPUParticles2D.speed_scale = clamp($FuckassVisualizer.strength,0.0,2.0)

func reload() -> void:
	pass

func _on_pos_bar_drag_started() -> void:
	Autoload.logger("Detected seek bar drag start...",Autoload.LOG_LEVEL.VERBOSE,"CONTROLS")
	time_bar_pos = $UI/HSlider.value
	is_dragging = true

func _on_pos_bar_drag_ended(value_changed: bool) -> void:
	Autoload.logger("Detected seek bar drag end...",Autoload.LOG_LEVEL.VERBOSE,"CONTROLS")
	is_dragging = false
	if value_changed:
		Autoload.logger("Value changed, resetting seek bar position...",Autoload.LOG_LEVEL.VERBOSE,"CONTROLS")
		$AudioStreamPlayer.seek($UI/HSlider.value)
		$UI/HSlider.value = time_bar_pos

func _on_one_of_the_buttons_pressed(caller:Node,filepath:String):
	current_index = caller.get_index() + %SongList.get_child_count() * %SongList.page
	music_menu_down = false
	set_music(filepath)
	var fd = FileAccess.open("user://config/last_song",FileAccess.WRITE)
	fd.store_string(filepath)
	fd.close()

func set_music(filepath:String):
	Autoload.logger("Requested file : "+filepath,Autoload.LOG_LEVEL.VERBOSE,"MUSIC_LOADER")
	if not ResourceLoader.has_cached(filepath):
		Autoload.logger("Requested file is not cached. Loading from file...",Autoload.LOG_LEVEL.INFO,"MUSIC_LOADER")
		var stream = AudioStreamMP3.load_from_file(filepath)
		stream.resource_path = filepath
		$AudioStreamPlayer.stream = stream
	else:
		Autoload.logger("Requested file is cached, giving cached copy...",Autoload.LOG_LEVEL.INFO,"MUSIC_LOADER")
		$AudioStreamPlayer.stream = load(filepath)
	if background_color == null:
		Autoload.logger("Getting music thumbnail color...",Autoload.LOG_LEVEL.VERBOSE,"MUSIC_LOADER")
		var meta = MusicMeta.get_mp3_metadata($AudioStreamPlayer.stream)
		if meta.cover == null:
			create_tween().tween_property($Background/TextureRect,"modulate",default_background_color,0.5)
			create_tween().tween_property($Control/TextureRect,"modulate",Color.from_hsv((default_background_color.h+0.1),default_background_color.s,default_background_color.v),0.5)
			create_tween().tween_property($Control/TextureRect2,"modulate",Color.from_hsv((default_background_color.h-0.1),default_background_color.s,default_background_color.v),0.5)
		else:
			if background_mode == "GRADIENT":
				if $Background/TextureRect.texture is not GradientTexture2D: # To account for on-the-fly config changing, if the background texture is not a gradient, we make it one
					var new_gradient : GradientTexture2D = GradientTexture2D.new() # We copy all of the properties of the default background
					new_gradient.gradient = Gradient.new()
					new_gradient.gradient.add_point(0.0,Color(0.45,0.45,0.45,1.0))
					new_gradient.gradient.add_point(1.0,Color.WHITE)
					new_gradient.fill_from = Vector2(0.0,1.0)
					new_gradient.fill_to = Vector2(1.0,0.0)
				var image : Image = meta.cover.get_image()
				var image_size : Vector2i = image.get_size()
				var pixels : Array[Color] = []
				
				for i in range(11): # We grab 11 * 11 = 121 pixels from the thumbnail in a grid
					for j in range(11):
						pixels.append(image.get_pixel(clamp(int(image_size.x*(i/10.0)),0,image_size.x-1),clamp(int(image_size.y*(j/10.0)),0,image_size.y-1)))
				
				
				var avg : Color = Color.BLACK # We then calculate the average of all the colors
				for i in pixels:
					avg += i
				avg /= len(pixels)
				
				# To make the background more colorful we find the most intense color channel out of red, green and blue,
				# we get the number we need to multiply it by to get 1, and then we multiply all three values by it
				if avg.r >= avg.g && avg.r >= avg.b:
					var ratio = 1/avg.r
					avg.r = 1.0
					avg.g *= ratio
					avg.b *= ratio
				elif avg.g >= avg.r && avg.g >= avg.b:
					var ratio = 1/avg.g
					avg.r *= ratio
					avg.g = 1.0
					avg.b *= ratio
				else:
					var ratio = 1/avg.b
					avg.r *= ratio
					avg.g *= ratio
					avg.b = 1.0
					
				# We then apply a custom exponent to all three channels to up the contrast
				avg.r = avg.r ** color_exponents[0]
				avg.g = avg.g ** color_exponents[1]
				avg.b = avg.b ** color_exponents[2]
				create_tween().tween_property($Background/TextureRect,"modulate",avg,0.5)
				create_tween().tween_property($Control/TextureRect,"modulate",Color.from_hsv((avg.h+0.1),avg.s,avg.v),0.5)
				create_tween().tween_property($Control/TextureRect2,"modulate",Color.from_hsv((avg.h-0.1),avg.s,avg.v),0.5)
			elif background_mode == "BLURRED": # We set the background to an image created by grabbing 121 pixels from the thumbnail
				var image : Image = meta.cover.get_image()
				var image_size : Vector2i = image.get_size()
				var image_blurred : Image = Image.create_empty(11,11,false,Image.FORMAT_RGB8)
				for i in range(11):
					for j in range(11):
						image_blurred.set_pixel(i,j,image.get_pixel(clamp(int(image_size.x*(i/10.0)),0,image_size.x-1),clamp(int(image_size.y*(j/10.0)),0,image_size.y-1)))
				
				var text : ImageTexture = ImageTexture.create_from_image(image_blurred)
				$Background/TextureRect.modulate = Color.WHITE
				$Background/TextureRect.texture = text
				$Background/TextureRect.texture_filter = CanvasItem.TextureFilter.TEXTURE_FILTER_LINEAR # This allows something ressembling a blur (i will create a real blur shader... someday)
			
			elif background_mode == "THUMBNAIL": # We just grab the thumbnail from the music file's metadata
				$Background/TextureRect.modulate = Color.WHITE
				$Background/TextureRect.texture = meta.cover
	else:
		Autoload.logger("Background color is static, thumbnail fetch is unnecessary...",Autoload.LOG_LEVEL.VERBOSE,"MUSIC_LOADER")
		$Background/TextureRect.modulate = background_color
	Autoload.logger("Changing all instances of music title...",Autoload.LOG_LEVEL.VERBOSE,"MUSIC_LOADER")
	$UI/RichTextLabel.text = $AudioStreamPlayer.stream.resource_name if $AudioStreamPlayer.stream.resource_name != "" else $AudioStreamPlayer.stream.resource_path.get_file().trim_suffix(".mp3")
	$UI/RichTextLabel.tooltip_text = $AudioStreamPlayer.stream.resource_name if $AudioStreamPlayer.stream.resource_name != "" else $AudioStreamPlayer.stream.resource_path.get_file().trim_suffix(".mp3")
	get_window().title = ($AudioStreamPlayer.stream.resource_name if $AudioStreamPlayer.stream.resource_name != "" else $AudioStreamPlayer.stream.resource_path.get_file().trim_suffix(".mp3")) + " - Gofy Ahh Music Player"
	Autoload.logger("Playing music...",Autoload.LOG_LEVEL.VERBOSE,"MUSIC_LOADER")
	$AudioStreamPlayer.play()
	
	

func _on_add_element_button_pressed() -> void:
	var dialog = FileDialog.new()
	dialog.set_file_mode(FileDialog.FILE_MODE_OPEN_DIR)
	dialog.set_access(FileDialog.ACCESS_FILESYSTEM)
	dialog.set_use_native_dialog(true)
	dialog.connect("dir_selected", _on_dir_selected)
	add_child(dialog)
	dialog.popup_centered_ratio()
	#$UI/LookupContainer/ScrollContainer/VBoxContainer/AddElementButton/Input.visible = not $UI/LookupContainer/ScrollContainer/VBoxContainer/AddElementButton/Input.visible

func _on_dir_selected(dir) -> void:
	if not DirAccess.dir_exists_absolute(dir):return
	
	Autoload.logger("Adding new line to lookup dirs...",Autoload.LOG_LEVEL.INFO,"LOOKUP_MANAGER")
	var new_line : LookupPath = load("uid://b1u6xdn66w8jo").instantiate()
	$UI/LookupContainer/ScrollContainer/VBoxContainer.add_child(new_line)
	new_line.filepath = dir
	lookup_dirs.append(dir)
	save_lookup_dirs()
	await _lookup_dirs(lookup_dirs)

func _on_input_text_submitted(new_text: String) -> void:
	$UI/LookupContainer/ScrollContainer/VBoxContainer/AddElementButton/Input.text = ""
	$UI/LookupContainer/ScrollContainer/VBoxContainer/AddElementButton/Input.hide()
	if not DirAccess.dir_exists_absolute(new_text):return
	
	Autoload.logger("Adding new line to lookup dirs...",Autoload.LOG_LEVEL.INFO,"LOOKUP_MANAGER")
	var new_line : LookupPath = load("uid://b1u6xdn66w8jo").instantiate()
	$UI/LookupContainer/ScrollContainer/VBoxContainer.add_child(new_line)
	new_line.filepath = new_text
	lookup_dirs.append(new_text)
	save_lookup_dirs()
	await _lookup_dirs(lookup_dirs)

func _lookup_dirs(value:Array):
	if scanning:return
	scanning = true
	register = []
	for i in value:
		Autoload.logger("Found "+i+"...",Autoload.LOG_LEVEL.VERBOSE,"LOOKUP_MANAGER")
		var files = DirAccess.open(i)
		var count := 0
		for file in files.get_files():
			if not file.ends_with(".mp3"):continue
			count += 1
			#Autoload.logger("Adding entry to playlist : "+file,Autoload.LOG_LEVEL.VERBOSE,"LOOKUP_MANAGER")
			register.append(i+"/"+file)
			#await get_tree().create_timer(0.001).timeout
		Autoload.logger("Added "+str(count)+" entries to the playlist.",Autoload.LOG_LEVEL.VERBOSE,"LOOKUP_MANAGER")
	%SongList.reg = register
	scanning = false

func save_lookup_dirs():
	Autoload.logger("Saving lookup dirs...",Autoload.LOG_LEVEL.INFO,"LOOKUP_MANAGER")
	var fd = FileAccess.open("user://config/lookup_paths",FileAccess.WRITE)
	fd.store_string("\n".join(lookup_dirs))
	fd.close()

func format_time(time : int) -> String:
	var new_string : String = ""
	if time > 3600:
		@warning_ignore("integer_division")
		new_string += "%02d" % int(time / 3600)
		new_string += ":"
		@warning_ignore("integer_division")
		time -= int(time / 3600) * 3600 
	@warning_ignore("integer_division")
	new_string += "%02d" % int(time / 60)
	new_string += ":"
	@warning_ignore("integer_division")
	time -= int(time / 60) * 60
	new_string += "%02d" % time
	
	return new_string

func lookup_dir_removed(filepath:String) -> void:
	if filepath in lookup_dirs:
		lookup_dirs.erase(filepath)
		save_lookup_dirs()
		await _lookup_dirs(lookup_dirs)

func load_and_apply_config() -> void:
	Autoload.logger("Getting config file...",Autoload.LOG_LEVEL.INFO,"CONFIG_MANAGER")
	if not FileAccess.file_exists("user://config/config.toml"):
		DirAccess.copy_absolute("res://example_config.toml","user://config/config.toml")
	
	var out = TOML.parse("user://config/config.toml")
	config = out
	if out.has("background"):
		if out["background"].has("shader"):
			if out["background"]["shader"].has("shader_level"):
				var value = out["background"]["shader"]["shader_level"]
				if value is String and value == "AUTO":
					$FuckassVisualizer.shader_level = null
				elif value is float or value is int:
					$FuckassVisualizer.shader_level = clamp(value,0.0,5.0)
				else:
					$FuckassVisualizer.shader_level = null
		if out["background"].has("scale"):
			if out["background"]["scale"].has("background_scale"):
				var value = out["background"]["scale"]["background_scale"]
				if value is String and value == "AUTO":
					$FuckassVisualizer.background_scale = null
				elif value is float or value is int:
					$FuckassVisualizer.background_scale = value
				else:
					$FuckassVisualizer.background_scale = null
		if out["background"].has("color"):
			if out["background"]["color"].has("background_color"):
				var value = out["background"]["color"]["background_color"]
				if value is String and value == "AUTO":
					background_color = null
				elif value is String and is_string_color(value):
					background_color = get_string_color(value)
				else:
					background_color = null
			
			if out["background"]["color"].has("default_background_color"):
				var value = out["background"]["color"]["default_background_color"]
				if is_string_color(value):
					default_background_color = get_string_color(value)
				else:
					default_background_color = Color.from_hsv(0.66,1.0,1.0)
			
			var temp_exps : Array[float] = [1.5,1.5,1.5]
			
			if out["background"]["color"].has("red_exponent"):
				var value = out["background"]["color"]["red_exponent"]
				if value is float:
					temp_exps[0] = value
					
			if out["background"]["color"].has("green_exponent"):
				var value = out["background"]["color"]["green_exponent"]
				if value is float:
					temp_exps[1] = value
					
			if out["background"]["color"].has("blue_exponent"):
				var value = out["background"]["color"]["blue_exponent"]
				if value is float:
					temp_exps[2] = value
			
			color_exponents = temp_exps
		if out["background"].has("mode"):
			if out["background"]["mode"].has("background_mode"):
				var value = out["background"]["mode"]["background_mode"]
				if value is String:
					if value == "GRADIENT":
						background_mode = "GRADIENT"
					elif value == "THUMBNAIL":
						background_mode = "THUMBNAIL"
					elif value == "BLURRED":
						background_mode = "BLURRED"
					else:
						background_mode = "GRADIENT"
				else:
					background_mode = "GRADIENT"
		if out["background"].has("text"):
			if out["background"]["text"].has("background_text"):
				var value = out["background"]["text"]["background_text"]
				$Background/RichTextLabel.text = str(value)
			if out["background"]["text"].has("dynamic_text_color"):
				var value = out["background"]["text"]["dynamic_text_color"]
				if value is bool:
					$Background/RichTextLabel.set_instance_shader_parameter(&"InvertMode",value)
			if out["background"]["text"].has("text_color"):
				var value = out["background"]["text"]["text_color"]
				if value is String and is_string_color(value):
					$Background/RichTextLabel.modulate = get_string_color(value)
				else:
					$Background/RichTextLabel.modulate = Color.WHITE

func is_string_color(p_input:String) -> bool:
	if p_input == "": return false # We check if the string is not empty
	
	var split_input : PackedStringArray = p_input.split(";",true) # We split the string for further processing
	if len(split_input) not in [3,4]: return false # If the length of the array is not 3 (hsv) or 4 (hsva) we return false
	
	for i : String in split_input:
		if i == "": # If the string is empty we return false
			return false
		if not i.is_valid_float(): # If the string is not a valid float we return false
			return false
	
	return true

func get_string_color(p_input:String) -> Color:
	if p_input == "": return Color.BLACK
	
	var split_input : PackedStringArray = p_input.split(";",true) # We split the string for further processing
	if len(split_input) not in [3,4]: return Color.BLACK # If the length of the array is not 3 (hsv) or 4 (hsva) we return false
	
	for i : String in split_input:
		if i == "": # If the string is empty we return false
			return Color.BLACK
		if not i.is_valid_float(): # If the string is not a valid float we return false
			return Color.BLACK
	
	var new_color : Color = Color.BLACK
	
	new_color.h = float(split_input[0])
	new_color.s = float(split_input[1])
	new_color.v = float(split_input[2])
	if len(split_input) == 4:
		new_color.a = float(split_input[3])
	return new_color

func next():
	if current_index == -1: 
		if $AudioStreamPlayer.stream and $AudioStreamPlayer.stream.resource_path:
			current_index = register.find($AudioStreamPlayer.stream.resource_path)
	if len(register) < 2: return
	if not random_mode:
		if len(register) - 1 < current_index + 1:
			current_index = 0
		else:
			current_index += 1
	else:
		var rand : int = randi_range(0,len(register)-1)
		while rand == current_index:
			rand = randi_range(0,len(register)-1)
		current_index = rand
	
	set_music(register[current_index])

func _on_audio_stream_player_finished() -> void:
	if not $UI/MainButtonContainer/LoopButton.button_pressed:
		next()


func _on_random_button_toggled(toggled_on: bool) -> void:
	random_mode = toggled_on

func check_active():
	active = $AudioStreamPlayer.stream != null and not $UI/MainButtonContainer/PauseButton.button_pressed


func _on_search_text_changed(new_text: String) -> void:
	if new_text == "": 
		%SongList.reg = register
		return
	
	var tags = []
	var other = []
	for i in new_text.split(" "):
		if i.begins_with("folder:"):
			tags.append(i)
		else:
			other.append(i)
	new_text = " ".join(other)
	var new_reg = []
	for i : String in register:
		var check : int = 0
		if new_text.to_lower() in i.to_lower() or new_text == "":
			check += 1
		
		for j : String in tags:
			if j.begins_with("folder:"):
				j = j.trim_prefix("folder:")
				if j.is_valid_int():
					if int(j) < $UI/LookupContainer/ScrollContainer/VBoxContainer.get_child_count():
						var folder_path = $UI/LookupContainer/ScrollContainer/VBoxContainer.get_child(int(j))
						if folder_path is LookupPath:
							if folder_path.filepath.trim_suffix("/") == i.get_base_dir():
								check += 1
				else:
					if j.trim_suffix("/") == i.get_base_dir():
							check += 1
		if check == len(tags) + 1:
			new_reg.append(i)
	%SongList.reg = new_reg

func load_last_mus() -> void:
	if FileAccess.file_exists("user://config/last_song"):
		if FileAccess.file_exists(FileAccess.get_file_as_string("user://config/last_song")):
			set_music(FileAccess.get_file_as_string("user://config/last_song"))

func _on_search_text_submitted(new_text: String) -> void:
	$UI/MainButtonContainer/PauseButton.call_deferred("grab_focus")
