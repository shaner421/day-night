##
## A simple day and night system utilizing a sky shader material and some gradient textures.
##

@tool class_name Day_Night extends Node3D

#
# export variables
#

@export_group("Sky Configuration")
@export_subgroup("Sky Values")
## Allows you to set the time of day; the value is a float range from 0-2400.
@export_range(0,2400) var time_of_day = 1200
## a bool that enables time to pass.
@export var advance_time:bool = false
## a float range that allows you to control how quickly time passes.
@export_range(1.0,200.0) var time_interval:float = 5.0

@export_subgroup("Sky Colouring")
## Controls the sky's color during the day/night transition. Defaults to using a gradient in the resources folder.
@export var sky_color:GradientTexture1D = preload("res://Day&Night/resources/sky_color.tres")
## Controls the horizon's color during the day/night transition. Defaults to using a gradient in the resources folder.
@export var horizon_color:GradientTexture1D = preload("res://Day&Night/resources/horizon_color.tres")

@export_subgroup("Sun & Moon Values")

#sun
## determines the colour of the sun. Defaults to slightly yellow.
@export_color_no_alpha var sun_colour:Color = Color("f2d8b8")
## determines the sun's size; is a float range from 0.01-1.
@export_range(0.01,1.0) var sun_size:float = 0.06
## determines the sun's blur amount; is a float range from 0.01-1.
@export_range(0.01,1.0) var sun_blur:float = 0.3

#moon
## determines the colour of the moon. Defaults to slightly grey.
@export_color_no_alpha var moon_colour:Color = Color("999e90")
## determines the moon's size; is a float range from 0.01-1.
@export_range(0.01,1.0) var moon_size:float = 0.03
## determines the moon's blur amount; is a float range from 0.01-1.
@export_range(0.01,1.0) var moon_blur:float = 0.3

@export_subgroup("Scattering Values")
@export_range(0.0,1.0) var mie_strength:float = 0.5
@export_range(0.0,1.0) var mie_directional_factor:float = 0.9
@export_color_no_alpha var mie_colour:Color = Color(0.76, 0.4, 0.2)

@export_range(0.0,1.0) var rayleigh_strength:float = 0.5
@export_color_no_alpha var rayleigh_colour:Color = Color(0.26, 0.41, 0.58)
@export_subgroup("Stars Values")
@export var stars_noise_texture:NoiseTexture2D = preload("res://Day&Night/resources/starmap.tres")
@export_range(0.0,1.0) var stars_density:float = 0.8
@export_range(0.0,1.0) var stars_intensity:float = 0.5
@export_color_no_alpha var stars_colour:Color = Color(1.0, 0.95, 0.8)
#
# internal variables
#

# a value that contains time_of_day remapped from 0-2400 to 0-1.
var time_remap:float = 0.0
# a distribution curve from 0-1 that determine's the sun's light energy over the course of the day.
var sun_dist:Curve = preload("res://Day&Night/resources/light_curve.tres")
# a distribution curve from 1-0 that determine's the moon's light energy over the course of the day.
var moon_dist:Curve = preload("res://Day&Night/resources/moonlight_curve.tres")
# a distribution curve from 0-1 that determine's the horizon's size over the course of the day.
var horizon_dist:Curve = preload("res://Day&Night/resources/horizon_curve.tres")

#
# onready variables
#

# a reference to our sky shader in the world environment.
@onready var sky_shader:ShaderMaterial = $WorldEnvironment.environment.sky.sky_material
# a reference to our directional light that represents the sun.
@onready var sun:DirectionalLight3D = $gimbal/sun
# a reference to our directional light that represents the moon.
@onready var moon:DirectionalLight3D = $gimbal/moon

#
# built-in functions
#

# called every frame
func _physics_process(delta: float) -> void:
	update_time(advance_time,time_interval,delta)
	update_brightness()
	update_color()
	update_sun_moon()
	update_scattering()
	update_stars()

#
# custom functions
#

## this function will advance time based upon the time interval if the advance_time bool is enabled.
func update_time(advance_time,time_interval,delta):
	time_remap = remap(time_of_day,0.0,2400.0,0.0,1)
	var time_rotation = (time_remap * 360.0 ) + 90.0 #time_rotation needs to be +90 degrees because I messed up and am stupid. - Shane
	$gimbal.global_rotation_degrees.x = time_rotation
	
	if advance_time:
		time_of_day = wrapf(time_of_day + delta*time_interval,0.0,2400)

## this function will update the brightness of our sun+moon based on the light curves.
func update_brightness():
	$gimbal/sun.light_energy = sun_dist.sample(time_remap)
	$gimbal/moon.light_energy = clamp(moon_dist.sample(time_remap),0.0,0.01)

## this function updates the sky shader to use our sky and horizon colours and sets the horizon size based on our horizon size curve.
func update_color():
	#print(times)
	sky_shader.set_shader_parameter("sky_color", sky_color.gradient.sample(time_remap+0.5))
	sky_shader.set_shader_parameter("horizon_color", horizon_color.gradient.sample(time_remap))
	sky_shader.set_shader_parameter("horizon_width", horizon_dist.sample(time_remap))
	sky_shader.set_shader_parameter("time_of_day", time_of_day)

func update_scattering():
	sky_shader.set_shader_parameter("mie_strength",mie_strength)
	sky_shader.set_shader_parameter("mie_directional_factor",mie_directional_factor)
	sky_shader.set_shader_parameter("mie_color",mie_colour)
	
	sky_shader.set_shader_parameter("rayleigh_strength",rayleigh_strength)
	sky_shader.set_shader_parameter("rayleigh_color",rayleigh_colour)

func update_stars():
	sky_shader.set_shader_parameter("stars_density",stars_density)
	sky_shader.set_shader_parameter("stars_intensity",stars_intensity)
	sky_shader.set_shader_parameter("stars_color",stars_colour)
	sky_shader.set_shader_parameter("stars_noise_texture",stars_noise_texture)

## this function updates the size, colour, and blur of our sun+moon in the sky shader.
func update_sun_moon():
	sky_shader.set_shader_parameter("sun_col", sun_colour)
	sky_shader.set_shader_parameter("sun_size", sun_size)
	sky_shader.set_shader_parameter("sun_blur",sun_blur)
	
	sky_shader.set_shader_parameter("moon_col", moon_colour)
	sky_shader.set_shader_parameter("moon_size", moon_size)
	sky_shader.set_shader_parameter("moon_blur",moon_blur)


	
	
