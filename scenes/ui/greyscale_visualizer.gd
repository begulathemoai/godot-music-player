extends TextureRect
var strength : float = 0.0
var maximum : float = 1.0
@export var scale_curve : Curve
var audio_level : float
var shader_level = null
var background_scale = null
var scale_setter : Vector2 = Vector2.ONE:
	set(value):
		if scale_setter != value:
			if $"../Background/TextureRect".texture is GradientTexture2D:
				$"../Background/TextureRect".scale = value
			$"../Background/GPUParticles2D".scale = value
			$"../Background/RichTextLabel".scale = value
			scale_setter = value
			
var strength2 : float = 0.0

signal maximum_exceeded

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pivot_offset = size / 2


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	strength2 = lerp(strength2,strength,0.05)
	audio_level = (db_to_linear(AudioServer.get_bus_peak_volume_left_db(0,0)) + db_to_linear(AudioServer.get_bus_peak_volume_right_db(0,0))) / 2
	#if not pivot_offset == size / 2 + (get_global_mouse_position() / 20):
	pivot_offset = size / 2 + (get_global_mouse_position() / 20)
	

	maximum = max(maximum,0.35)
	if maximum < audio_level:
		maximum_exceeded.emit(audio_level,maximum)
		maximum = audio_level
	maximum -= 0.01 * delta * 60
	
	strength = lerp(strength,remap(audio_level,0.0,maximum,0.0,3.0),0.3)
	
	#if background_scale == null:
	if scale_curve != null:
		scale_setter = lerp(scale_setter,Vector2(scale_curve.sample(strength),scale_curve.sample(strength)),0.7)
	else:
		scale_setter = lerp(scale_setter,Vector2(remap(strength,0.0,5.0,1.0,1.5),remap(strength,0.0,5.0,1.0,1.5)),0.5)
	#else:
		#scale_setter = Vector2(background_scale,background_scale)
	
	if shader_level == null:
		set_instance_shader_parameter(&"Strength",strength)
		set_instance_shader_parameter(&"Strength2",strength2)
	else:
		set_instance_shader_parameter(&"Strength",shader_level)
		set_instance_shader_parameter(&"Strength2",shader_level)
