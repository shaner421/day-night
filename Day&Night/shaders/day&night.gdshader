//
// a simple sky shader that includes a sun + moon, sunrises and sunsets based on colour gradients.
//

//determines shader type
shader_type sky;

//
//shader parameters 
//

//sky variables
uniform vec3 sky_color : source_color; // colour of sky
uniform vec3 horizon_color: source_color; // colour of horizon
uniform float horizon_width = 0.05; // size of horizon

// sun variables
uniform vec3 sun_col: source_color = vec3(1.0); // sun colour
uniform float sun_size: hint_range(0.01, 1.0) = 0.05; // sun size
uniform float sun_blur: hint_range(0.01, 1.0) = 0.01; // sun blur amount

//moon variables
uniform vec3 moon_col: source_color = vec3(1.0); // moon colour
uniform float moon_size: hint_range(0.01, 1.0) = 0.01; // moon size
uniform float moon_blur: hint_range(0.01, 1.0) = 0.01; // moon blur amount

//
// custom functions
//

//function that returns a vec3 representing our sun, takes in light0's direction (sun)
//and the direction from the camera to the pixel being drawn.
vec3 sun(vec3 eyedir,vec3 light0_dir){
	// determine's the distance from the camera to light0 (sun)
	float sun_distance = distance(eyedir.xyz, light0_dir);
	// idk what this does
	float sun_power = 1.0 - clamp(sun_distance / sun_size, 0.0, 1.0);
	//determines the sun disc depending on sun blur value
	float sun_disc = clamp(sun_power / sun_blur, sun_power, 1.0);
	//vec3 variable containing the sun colour to be projected onto the sky
	vec3 sun = sun_col * sun_disc;
	return sun;
}

//function that returns a vec3 representing our moon, takes in light0's direction (sun)
//and the direction from the camera to the pixel being drawn.
vec3 moon(vec3 eyedir,vec3 light0_dir){
	// determines the distance from the camera to the opposite of light0's direction (sun)
	float moon_distance = distance(eyedir.xyz, -light0_dir);
	//idk what this does
	float moon_power = 1.0 - clamp(moon_distance / moon_size, 0.0, 1.0);
	//determines the moon's disc depending on the moon blur value
	float moon_disc = clamp(moon_power / moon_blur, moon_power, 1.0);
	//vec3 variable containing the moon's colour to be projected onto the sky.
	vec3 moon = moon_col * moon_disc;
	return moon;
}

//
// built-in functions
//

//called for every pixel in the skybox
void sky() {
	//creates the horizon along eyedir.y (range of 0-1 going from horizon to top of skybox)
	float sky_value = clamp(EYEDIR.y / horizon_width,0.0,1.0);
	//mixes the horizon into the sky based on the value above
	vec3 final_color = mix(horizon_color,sky_color,sky_value);
	//vec3 containing our sun and moon colours to be projected onto the sky
	vec3 sunmoon =  sun(EYEDIR,LIGHT0_DIRECTION) + moon(EYEDIR,LIGHT0_DIRECTION);
	//vec3 containing our final colour for our sky depending on the lights in the scene (light0 is sun, light1 is moon).
	vec3 sky = final_color * (LIGHT0_ENERGY+LIGHT1_ENERGY) +sunmoon;
	//sets the colour of the sky to our sky colour.
	COLOR = sky;
}


