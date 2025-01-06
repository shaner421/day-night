shader_type sky;

// Sky and horizon color, along with horizon size
uniform vec3 sky_color : source_color;
uniform vec3 horizon_color: source_color;
uniform float horizon_width = 0.05;

// Sun color, size and blur value
uniform vec3 sun_col: source_color = vec3(1.0);
uniform float sun_size: hint_range(0.01, 1.0) = 0.05;
uniform float sun_blur: hint_range(0.01, 1.0) = 0.01;

// Moon color, size and blur value
uniform vec3 moon_col: source_color = vec3(1.0);
uniform float moon_size: hint_range(0.01, 1.0) = 0.01;
uniform float moon_blur: hint_range(0.01, 1.0) = 0.01;

// Mie scattering parameters
uniform float mie_strength: hint_range(0.0, 1.0) = 0.5;
uniform float mie_directional_factor: hint_range(0.0, 1.0) = 0.76;
uniform vec3 mie_color: source_color = vec3(0.76, 0.4, 0.2);

// Rayleigh scattering parameters
uniform float rayleigh_strength: hint_range(0.0, 2.0) = 1.0;
uniform vec3 rayleigh_color: source_color = vec3(0.26, 0.41, 0.58);

// Star parameters
uniform sampler2D stars_noise_texture;  // Noise texture for star distribution
uniform float stars_density: hint_range(0.01, 0.999) = 0.997;  // Higher value = fewer stars
uniform vec3 stars_color: source_color = vec3(1.0, 0.95, 0.8);  // Slightly warm white
uniform float stars_intensity: hint_range(0.0, 1.0) = 0.5;  // Overall star brightness
uniform float time_of_day: hint_range(0.0, 2400.0) = 1200.0;  // 24-hour format

// Calculate star visibility based on time of day
float get_star_visibility(float time) {
    // Convert 24-hour time to a 0-1 range
    float normalized_time = time / 2400.0;
    
    // Define twilight periods
    float sunrise_start = 0.25;  // 6:00
    float sunrise_end = 0.291667;  // 7:00
    float sunset_start = 0.75;  // 18:00
    float sunset_end = 0.791667;  // 19:00
    
    // Stars are fully visible at night
    if (normalized_time > sunset_end || normalized_time < sunrise_start) {
        return 1.0;
    }
    // Stars fade out during sunrise
    else if (normalized_time < sunrise_end) {
        return 1.0 - smoothstep(sunrise_start, sunrise_end, normalized_time);
    }
    // Stars fade in during sunset
    else if (normalized_time > sunset_start) {
        return smoothstep(sunset_start, sunset_end, normalized_time);
    }
    return 0.0;
}

// Hash function for pseudo-random number generation
float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(443.897, 441.423, 437.195));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

// Generate stars based on view direction
vec3 get_stars(vec3 dir) {
    // Convert direction to UV coordinates using spherical mapping
    vec2 star_uv = vec2(
        atan(dir.x, dir.z) / (2.0 * PI) + 0.5,
        acos(dir.y) / PI
    );
    
    // Initialize star value
    float star = 0.0;
    
    // Create multiple layers of stars with different densities and scales
    for(float i = 0.0; i < 3.0; i++) {
        // Create different UV scales for each layer
        vec2 uv = star_uv * (1.0 + i * 2.0);
        
        // Sample noise texture at different scales
        float noise = texture(stars_noise_texture, uv).r;
        noise *= texture(stars_noise_texture, uv * 2.345 + 0.123).r;
        
        // Vary density per layer
        float layer_density = stars_density - (i * 0.001);
        
        // Add stars for this layer
        float layer_star = step(layer_density, noise);
        
        // Add some variation in brightness
        float brightness = hash(uv + i) * 0.5 + 0.5;
        layer_star *= brightness;
        
        // Add twinkle effect that varies per layer
        float twinkle = texture(stars_noise_texture, uv + TIME * (0.1 + i * 0.05)).r;
        layer_star *= 0.8 + 0.2 * twinkle;
        
        // Accumulate stars
        star += layer_star;
    }
    
    // Normalize and apply time-based visibility
    star = clamp(star, 0.0, 1.0);
    star *= get_star_visibility(time_of_day) * stars_intensity;
    
    return stars_color * star;
}

// Creates the sun and sets it to the direction of light0 in the scene
vec3 sun(vec3 eyedir, vec3 light0_dir) {
    float sun_distance = distance(eyedir.xyz, light0_dir);
    float sun_power = 1.0 - clamp(sun_distance / sun_size, 0.0, 1.0);
    float sun_disc = clamp(sun_power / sun_blur, sun_power, 1.0);
    vec3 sun = sun_col * sun_disc;
    return sun;
}

// Creates the moon and sets it to the direction of light1 in the scene
vec3 moon(vec3 eyedir, vec3 light0_dir) {
    float moon_distance = distance(eyedir.xyz, -light0_dir);
    float moon_power = 1.0 - clamp(moon_distance / moon_size, 0.0, 1.0);
    float moon_disc = clamp(moon_power / moon_blur, moon_power, 1.0);
    vec3 moon = moon_col * moon_disc;
    return moon;
}

// Calculations for mie scattering
float miePhase(float cosTheta) {
    float g = mie_directional_factor;
    float scale = 3.0 / (8.0 * PI);
    
    float num = (1.0 - g * g) * (1.0 + cosTheta * cosTheta);
    float denom = (2.0 + g * g) * pow((1.0 + g * g - 2.0 * g * cosTheta), 1.5);
    
    return scale * num / denom;
}

// Calculations for Rayleigh scattering
float rayleighPhase(float cosTheta) {
    float scale = 3.0 / (16.0 * PI);
    return scale * (1.0 + cosTheta * cosTheta);
}

// Main function for 3D sky shader
void sky() {
    float sky_value = clamp(EYEDIR.y / horizon_width, 0.0, 1.0);
    vec3 final_color = mix(horizon_color, sky_color, sky_value);
    
    float cosTheta = dot(normalize(EYEDIR), normalize(LIGHT0_DIRECTION));
    
    // Calculate Mie scattering
    float mieScatter = miePhase(cosTheta) * mie_strength;
    vec3 mieColor = mie_color * mieScatter;
    
    // Calculate Rayleigh scattering
    float rayleighScatter = rayleighPhase(cosTheta) * rayleigh_strength;
    vec3 rayleighColor = rayleigh_color * rayleighScatter;
    
    // Enhance scattering near horizon
    float horizonFactor = 1.0 - abs(EYEDIR.y);
    horizonFactor *= horizonFactor;
    mieColor *= horizonFactor;
    rayleighColor *= horizonFactor;
    
    // Height-based atmosphere density
    float density = exp(-max(0.0, EYEDIR.y) * 4.0);
    rayleighColor *= density;
    
    // Generate stars and combine with existing effects
    vec3 stars = get_stars(normalize(EYEDIR));
    vec3 sunmoon = sun(EYEDIR, LIGHT0_DIRECTION) + moon(EYEDIR, LIGHT0_DIRECTION);
    vec3 sky = final_color * (LIGHT0_ENERGY + LIGHT1_ENERGY) + sunmoon + mieColor + rayleighColor + stars;
    
    COLOR = sky;
}