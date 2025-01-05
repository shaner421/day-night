shader_type sky;

uniform vec3 sky_color : source_color;
uniform vec3 horizon_color: source_color;
uniform float horizon_width = 0.05;

// Sun Stuff
uniform vec3 sun_col: source_color = vec3(1.0);
uniform float sun_size: hint_range(0.01, 1.0) = 0.05;
uniform float sun_blur: hint_range(0.01, 1.0) = 0.01;

uniform vec3 moon_col: source_color = vec3(1.0);
uniform float moon_size: hint_range(0.01, 1.0) = 0.01;
uniform float moon_blur: hint_range(0.01, 1.0) = 0.01;
// Stars should be at black background
uniform sampler2D stars_texture : filter_linear_mipmap, hint_default_black;
uniform float stars_speed : hint_range( 0.0, 20.0, 0.01 ) = 1.0;




vec3 sun(vec3 eyedir,vec3 light0_dir){
	float sun_distance = distance(eyedir.xyz, light0_dir);
	float sun_power = 1.0 - clamp(sun_distance / sun_size, 0.0, 1.0);
	float sun_disc = clamp(sun_power / sun_blur, sun_power, 1.0);
	vec3 sun = sun_col * sun_disc;
	return sun;
}
vec3 moon(vec3 eyedir,vec3 light0_dir){
	float moon_distance = distance(eyedir.xyz, -light0_dir);
	float moon_power = 1.0 - clamp(moon_distance / moon_size, 0.0, 1.0);
	float moon_disc = clamp(moon_power / moon_blur, moon_power, 1.0);
	vec3 moon = moon_col * moon_disc;
	return moon;
}


void sky() {
	
	
	
	float sky_value = clamp(EYEDIR.y / horizon_width,0.0,1.0);
	vec3 final_color = mix(horizon_color,sky_color,sky_value);
	vec3 sunmoon =  sun(EYEDIR,LIGHT0_DIRECTION) + moon(EYEDIR,LIGHT0_DIRECTION);
	vec3 sky = final_color * (LIGHT0_ENERGY+LIGHT1_ENERGY) +sunmoon;
	COLOR = sky;
}


