@tool class_name Day_Night extends Node3D

@export_category("Sky Values")
@export_range(0,2400) var time_of_day = 1800

@export var advance_time:bool = false
@export_range(5.0,150.0) var time_interval:float = 5.0
var time_remap:float = 0.0

@export_category("Sky Colouring")
@export var sky_color:GradientTexture1D = preload("res://Day&Night/resources/sky_color.tres")
@export var horizon_color:GradientTexture1D = preload("res://Day&Night/resources/horizon_color.tres")

var sun_dist:Curve = preload("res://Day&Night/resources/light_curve.tres")
var moon_dist:Curve = preload("res://Day&Night/resources/moonlight_curve.tres")
var horizon_dist:Curve = preload("res://Day&Night/resources/horizon_curve.tres")
@onready var sky_shader:ShaderMaterial = $WorldEnvironment.environment.sky.sky_material
@onready var sun:DirectionalLight3D = $gimbal/sun
@onready var moon:DirectionalLight3D = $gimbal/moon

func update_time(advance_time,time_interval,delta):
	time_remap = remap(time_of_day,0.0,2400.0,0.0,1)
	var time_rotation = (time_remap * 360.0 ) + 90.0
	$gimbal.global_rotation_degrees.x = time_rotation
	
	if advance_time:
		time_of_day = wrapf(time_of_day + delta*time_interval,0.0,2400)

func update_brightness():
	$gimbal/sun.light_energy = sun_dist.sample(time_remap)
	$gimbal/moon.light_energy = clamp(moon_dist.sample(time_remap),0.0,0.01)

func update_color():
	#print(times)
	sky_shader.set_shader_parameter("sky_color", sky_color.gradient.sample(time_remap+0.5))
	sky_shader.set_shader_parameter("horizon_color", horizon_color.gradient.sample(time_remap))
	sky_shader.set_shader_parameter("horizon_width", horizon_dist.sample(time_remap))
func _ready():
	pass

func _physics_process(delta: float) -> void:
	update_time(advance_time,time_interval,delta)
	update_brightness()
	update_color()
	
	
