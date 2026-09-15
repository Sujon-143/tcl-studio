//// something cool just happened!
//// we have seen earth from outside!


//shader_type spatial;
//render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert, specular_disabled, unshaded;
//
//// ─────────────────────────────────────────────
////  Sun / Moon directions — set from GDScript or just manually
//// ─────────────────────────────────────────────
//uniform vec3  sun_direction  = vec3( 0.3, 0.6, 0.0 );
//uniform vec3  moon_direction = vec3( -0.3, -0.6, 0.0 );
//uniform bool  light0_enabled = true;
//uniform bool  light1_enabled = true;
//
//// ─────────────────────────────────────────────
////  Sky
//// ─────────────────────────────────────────────
//group_uniforms sky;
	//uniform vec3 day_top_color       : source_color = vec3( 0.1,  0.6,  1.0  );
	//uniform vec3 day_bottom_color    : source_color = vec3( 0.4,  0.8,  1.0  );
	//uniform vec3 sunset_top_color    : source_color = vec3( 0.7,  0.75, 1.0  );
	//uniform vec3 sunset_bottom_color : source_color = vec3( 1.0,  0.5,  0.7  );
	//uniform vec3 night_top_color     : source_color = vec3( 0.02, 0.0,  0.04 );
	//uniform vec3 night_bottom_color  : source_color = vec3( 0.1,  0.0,  0.2  );
//
//// ─────────────────────────────────────────────
////  Horizon
//// ─────────────────────────────────────────────
//group_uniforms horizon;
	//uniform vec3  horizon_color : source_color = vec3( 0.0, 0.7, 0.8 );
	//uniform float horizon_blur  : hint_range( 0.0, 1.0, 0.01 ) = 0.05;
//
//// ─────────────────────────────────────────────
////  Sun
//// ─────────────────────────────────────────────
//group_uniforms sun;
	//uniform vec3  sun_color        : source_color = vec3( 10.0, 8.0, 1.0 );
	//uniform vec3  sun_sunset_color : source_color = vec3( 10.0, 0.0, 0.0 );
	//uniform float sun_size  : hint_range( 0.01, 1.0  ) = 0.2;
	//uniform float sun_blur  : hint_range( 0.01, 20.0 ) = 10.0;
//
//// ─────────────────────────────────────────────
////  Moon
//// ─────────────────────────────────────────────
//group_uniforms moon;
	//uniform vec3  moon_color : source_color = vec3( 1.0, 0.95, 0.7 );
	//uniform float moon_size  : hint_range( 0.01, 1.0  ) = 0.06;
	//uniform float moon_blur  : hint_range( 0.01, 10.0 ) = 0.1;
//
//// ─────────────────────────────────────────────
////  Clouds
//// ─────────────────────────────────────────────
//group_uniforms clouds;
	//uniform vec3  clouds_edge_color   : source_color = vec3( 0.8,  0.8,  0.98 );
	//uniform vec3  clouds_top_color    : source_color = vec3( 1.0,  1.0,  1.0  );
	//uniform vec3  clouds_middle_color : source_color = vec3( 0.92, 0.92, 0.98 );
	//uniform vec3  clouds_bottom_color : source_color = vec3( 0.83, 0.83, 0.94 );
	//uniform float clouds_speed     : hint_range( 0.0, 20.0, 0.01 ) = 2.0;
	//uniform float clouds_direction : hint_range( -0.5, 0.5,  0.0  ) = 0.2;
	//uniform float clouds_scale     : hint_range( 0.0,  4.0,  0.01 ) = 1.0;
	//uniform float clouds_cutoff    : hint_range( 0.0,  1.0,  0.01 ) = 0.3;
	//uniform float clouds_fuzziness : hint_range( 0.0,  2.0,  0.01 ) = 0.5;
	//uniform float clouds_weight    : hint_range( 0.0,  1.0,  0.01 ) = 0.0;
	//uniform float clouds_blur      : hint_range( 0.0,  1.0,  0.01 ) = 0.25;
//
//// ─────────────────────────────────────────────
////  Stars
//// ─────────────────────────────────────────────
//group_uniforms stars;
	//uniform sampler2D stars_texture : filter_linear_mipmap, hint_default_black;
	//uniform float stars_speed : hint_range( 0.0, 20.0, 0.01 ) = 1.0;
//
//// ─────────────────────────────────────────────
////  Globe appearance
//// ─────────────────────────────────────────────
//group_uniforms globe;
	//uniform float globe_alpha       : hint_range( 0.0, 1.0, 0.01 ) = 1.0;
	//uniform float fresnel_strength  : hint_range( 0.0, 5.0, 0.01 ) = 1.5;  // edge glow, set 0 to disable
	//uniform vec3  fresnel_color     : source_color = vec3( 0.4, 0.8, 1.0 );
//
//group_uniforms settings;
	//uniform float overwritten_time = 0.0;
//
//////////////////////////////////////////////////////////////////////////////////////////////////////
//// Noise
//////////////////////////////////////////////////////////////////////////////////////////////////////
//const int PRIME_X = 501125321;
//const int PRIME_Y = 1136930381;
//
//float _lerp( float a, float b, float t ) { return a + t * ( b - a ); }
//
//float cubic_lerp( float a, float b, float c, float d, float t )
//{
	//float p = d - c - ( a - b );
	//return t * t * t * p + t * t * ( a - b - p ) + t * ( c - a ) + b;
//}
//
//float ping_pong( float t )
//{
	//t -= trunc( t * 0.5 ) * 2.0;
	//return t < 1.0 ? t : 2.0 - t;
//}
//
//int _hash( int seed, int xp, int yp ) { return ( seed ^ xp ^ yp ) * 0x27d4eb2d; }
//
//float val_coord( int seed, int xp, int yp )
//{
	//int h = _hash( seed, xp, yp );
	//h *= h;
	//h ^= h << 19;
	//return float( h ) * ( 1.0 / 2147483648.0 );
//}
//
//float single_value_cubic( int seed, float x, float y )
//{
	//int x1 = int( floor( x ));
	//int y1 = int( floor( y ));
	//float xs = x - float( x1 );
	//float ys = y - float( y1 );
	//x1 *= PRIME_X;  y1 *= PRIME_Y;
	//int x0 = x1 - PRIME_X;  int y0 = y1 - PRIME_Y;
	//int x2 = x1 + PRIME_X;  int y2 = y1 + PRIME_Y;
	//int x3 = x1 + ( PRIME_X << 1 );
	//int y3 = y1 + ( PRIME_Y << 1 );
	//return cubic_lerp(
		//cubic_lerp( val_coord(seed,x0,y0), val_coord(seed,x1,y0), val_coord(seed,x2,y0), val_coord(seed,x3,y0), xs ),
		//cubic_lerp( val_coord(seed,x0,y1), val_coord(seed,x1,y1), val_coord(seed,x2,y1), val_coord(seed,x3,y1), xs ),
		//cubic_lerp( val_coord(seed,x0,y2), val_coord(seed,x1,y2), val_coord(seed,x2,y2), val_coord(seed,x3,y2), xs ),
		//cubic_lerp( val_coord(seed,x0,y3), val_coord(seed,x1,y3), val_coord(seed,x2,y3), val_coord(seed,x3,y3), xs ),
	//ys ) * ( 1.0 / ( 1.5 * 1.5 ));
//}
//
//const float FRACTAL_BOUNDING  = 1.0 / 1.75;
//const int   OCTAVES            = 5;
//const float PING_PONG_STRENGTH = 2.0;
//const float WEIGHTED_STRENGTH  = 0.0;
//const float GAIN               = 0.5;
//const float LACUNARITY         = 2.0;
//
//float gen_fractal_ping_pong( vec2 pos, int seed, float frequency )
//{
	//float x = pos.x * frequency;
	//float y = pos.y * frequency;
	//float sum = 0.0;
	//float amp = FRACTAL_BOUNDING;
	//for( int i = 0; i < OCTAVES; i++ )
	//{
		//float noise = ping_pong(( single_value_cubic( seed++, x, y ) + 1.0 ) * PING_PONG_STRENGTH );
		//sum += ( noise - 0.5 ) * 2.0 * amp;
		//amp *= _lerp( 1.0, noise, WEIGHTED_STRENGTH );
		//x *= LACUNARITY;
		//y *= LACUNARITY;
		//amp *= GAIN;
	//}
	//return sum * 0.5 + 0.5;
//}
//
//////////////////////////////////////////////////////////////////////////////////////////////////////
//// Moon phase helper
//////////////////////////////////////////////////////////////////////////////////////////////////////
//float sphere_intersect( vec3 view_dir, vec3 sphere_pos, float radius )
//{
	//float b = dot( -sphere_pos, view_dir );
	//float c = dot( -sphere_pos, -sphere_pos ) - radius * radius;
	//float h = b * b - c;
	//return h < 0.0 ? -1.0 : -b - sqrt( h );
//}
//
//////////////////////////////////////////////////////////////////////////////////////////////////////
//// Varying
//////////////////////////////////////////////////////////////////////////////////////////////////////
//varying vec3 world_normal;   // surface normal in world space  (for fresnel)
//varying vec3 local_pos;      // local vertex position          (used as EYEDIR equivalent)
//
//////////////////////////////////////////////////////////////////////////////////////////////////////
//// Vertex
//////////////////////////////////////////////////////////////////////////////////////////////////////
//void vertex()
//{
	//// Local position of the sphere vertex — used like EYEDIR to sample the sky
	//local_pos  = VERTEX;
	//// World normal for fresnel
	//world_normal = normalize( ( MODEL_MATRIX * vec4( NORMAL, 0.0 ) ).xyz );
//}
//
//////////////////////////////////////////////////////////////////////////////////////////////////////
//// Fragment
//////////////////////////////////////////////////////////////////////////////////////////////////////
//void fragment()
//{
	//// ── Direction: use local vertex position normalised, same role as EYEDIR ──
	//// When viewed from outside, the normal points outward and local_pos is outward.
	//// When viewed from inside (cull_disabled), the geometry is the same — the sky
	//// wraps naturally because we're sampling based on position, not view direction.
	//vec3 dir = normalize( local_pos );
//
	//float time = overwritten_time != 0.0 ? overwritten_time : TIME;
//
	//// ── SKY ──────────────────────────────────────────────────────────────────
	//float ey = abs( sin( dir.y * PI * 0.5 ));
//
	//vec3 sky_color = mix( day_bottom_color, day_top_color, ey );
	//sky_color = mix( sky_color, vec3( 0.0 ), clamp(( 0.7 - clouds_cutoff ) * clouds_weight, 0.0, 1.0 ));
//
	//float sunset_amount   = clamp( 0.5 - abs( sun_direction.y ), 0.0, 0.5 ) * 2.0;
	//float sunset_distance = clamp( 1.0 - pow( distance( dir, sun_direction ), 2.0 ), 0.0, 1.0 );
	//vec3  sky_sunset      = mix( sunset_bottom_color, sunset_top_color, ey + 0.5 );
	//sky_sunset  = mix( sky_sunset, sunset_bottom_color, sunset_amount * sunset_distance );
	//sky_color   = mix( sky_color, sky_sunset, sunset_amount );
//
	//float night_amount = clamp( -sun_direction.y + 0.7, 0.0, 1.0 );
	//vec3  sky_night    = mix( night_bottom_color, night_top_color, ey );
	//sky_color = mix( sky_color, sky_night, night_amount );
//
	//vec3 color = sky_color;
//
	//// ── HORIZON ──────────────────────────────────────────────────────────────
	//float horizon_amount = 0.0;
	//if( dir.y < 0.0 )
	//{
		//horizon_amount = clamp( abs( dir.y ) / horizon_blur, 0.0, 1.0 );
		//vec3 h_color   = mix( horizon_color, sky_color, night_amount * 0.9 );
		//h_color = mix( h_color, vec3( 0.0 ), ( 1.0 - clouds_cutoff ) * clouds_weight * 0.7 );
		//color   = mix( color, h_color, horizon_amount );
	//}
//
	//// ── MOON ─────────────────────────────────────────────────────────────────
	//float moon_amount = 0.0;
	//if( light1_enabled )
	//{
		//float m_size  = moon_size + cos( moon_direction.y * PI ) * moon_size * 0.25;
		//float m_dist  = distance( dir, moon_direction ) / m_size;
		//moon_amount   = clamp(( 1.0 - m_dist ) / moon_blur, 0.0, 1.0 );
		//if( moon_amount > 0.0 )
		//{
			//float m_i     = sphere_intersect( dir, moon_direction, m_size );
			//vec3  m_n     = normalize( moon_direction - dir * m_i );
			//float m_ndotl = pow( clamp( dot( m_n, -sun_direction ), 0.05, 1.0 ), 2.0 );
			//moon_amount  *= 1.0 - horizon_amount;
			//color = mix( color, moon_color, m_ndotl * moon_amount );
		//}
	//}
//
	//// ── SUN ──────────────────────────────────────────────────────────────────
	//float sun_dist = 0.0;
	//if( light0_enabled )
	//{
		//sun_dist      = distance( dir, sun_direction );
		//float s_size  = sun_size + cos( sun_direction.y * PI ) * sun_size * 0.25;
		//float s_amount = clamp(( 1.0 - sun_dist / s_size ) / sun_blur, 0.0, 1.0 );
		//if( s_amount > 0.0 )
		//{
			//float ss = ( sun_direction.y > 0.0 ) ? clamp( cos( sun_direction.y * PI ), 0.0, 1.0 ) : 1.0;
			//vec3 s_color = mix( sun_color, sun_sunset_color, ss );
			//s_amount = clamp( s_amount * ( 1.0 - moon_amount ), 0.0, 1.0 );
			//s_amount *= 1.0 - horizon_amount;
			//if( s_color.r > 1.0 || s_color.g > 1.0 || s_color.b > 1.0 )
				//s_color *= s_amount;
			//color = mix( color, s_color, s_amount );
		//}
	//}
//
	//// ── STARS ─────────────────────────────────────────────────────────────────
	//vec2 sky_uv = dir.xz / sqrt( max( dir.y, 0.001 ));
	//if( dir.y > -0.01 && sun_direction.y < 0.0 )
	//{
		//float sc = cos( stars_speed * time * 0.005 );
		//float ss = sin( stars_speed * time * 0.005 );
		//vec2  st_uv = vec2(
			//sky_uv.x * sc - sky_uv.y * ss,
			//sky_uv.x * ss + sky_uv.y * sc
		//);
		//vec3 st_col = texture( stars_texture, st_uv ).rgb * -sun_direction.y;
		//st_col     *= 1.0 - moon_amount;
		//color      += st_col;
	//}
//
	//// ── CLOUDS ────────────────────────────────────────────────────────────────
	//if( dir.y > 0.0 )
	//{
		//float cspeed = time * clouds_speed * 0.01;
		//float sx = sin( clouds_direction * PI * 2.0 );
		//float cy = cos( clouds_direction * PI * 2.0 );
//
		//vec2 mv   = vec2( sx, cy ) * cspeed;
		//float n_t = gen_fractal_ping_pong(( sky_uv + mv ) * clouds_scale, 0, 0.5 );
//
		//mv        = vec2( sx * 0.97, cy * 1.07 ) * cspeed * 0.89;
		//float n_m = gen_fractal_ping_pong(( sky_uv + mv ) * clouds_scale, 1, 0.75 );
//
		//mv        = vec2( sx * 1.01, cy * 0.89 ) * cspeed * 0.79;
		//float n_b = gen_fractal_ping_pong(( sky_uv + mv ) * clouds_scale, 2, 1.0 );
//
		//n_b = smoothstep( clouds_cutoff, clouds_cutoff + clouds_fuzziness, n_b );
		//n_m = smoothstep( clouds_cutoff, clouds_cutoff + clouds_fuzziness, n_m + n_b * 0.2 ) * 1.1;
		//n_t = smoothstep( clouds_cutoff, clouds_cutoff + clouds_fuzziness, n_t + n_m * 0.4 ) * 1.2;
//
		//float ca = clamp( n_t + n_m + n_b, 0.0, 1.0 );
		//ca      *= clamp( abs( dir.y ) / clouds_blur, 0.0, 1.0 );
//
		//vec3 cc = mix( vec3( 0.0 ), clouds_top_color, n_t );
		//cc = mix( cc, clouds_middle_color, n_m );
		//cc = mix( cc, clouds_bottom_color, n_b );
		//cc = mix( clouds_edge_color, cc, n_t );
		//cc = mix( cc, clamp( sun_color, 0.0, 1.0 ), pow( 1.0 - clamp( sun_dist, 0.0, 1.0 ), 5.0 ));
		//cc = mix( cc, sunset_bottom_color, sunset_amount * 0.75 );
		//cc = mix( cc, sky_color, clamp( night_amount, 0.0, 0.98 ));
		//cc = mix( cc, vec3( 0.0 ), clouds_weight * 0.9 );
//
		//color = mix( color, cc, ca );
	//}
//
	//// ── FRESNEL EDGE GLOW ─────────────────────────────────────────────────────
	//// Gives the globe a nice glassy rim when viewed from outside
	//vec3  view_dir = normalize( CAMERA_POSITION_WORLD - ( MODEL_MATRIX * vec4( local_pos, 1.0 ) ).xyz );
	//float fresnel  = pow( 1.0 - abs( dot( world_normal, view_dir ) ), fresnel_strength );
	//color = mix( color, fresnel_color, fresnel * 0.4 );
//
	//ALBEDO = color;
	//ALPHA  = globe_alpha;
//}




//// version 2... making the actual cloud
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, diffuse_lambert, specular_disabled, unshaded;

// ─────────────────────────────────────────────
//  Sun / Moon directions
// ─────────────────────────────────────────────
uniform vec3  sun_direction  = vec3( 0.3, 0.6, 0.0 );
uniform vec3  moon_direction = vec3( -0.3, -0.6, 0.0 );
uniform bool  light0_enabled = true;
uniform bool  light1_enabled = true;

// ─────────────────────────────────────────────
//  Sky
// ─────────────────────────────────────────────
group_uniforms sky;
	uniform vec3 day_top_color       : source_color = vec3( 0.1,  0.6,  1.0  );
	uniform vec3 day_bottom_color    : source_color = vec3( 0.4,  0.8,  1.0  );
	uniform vec3 sunset_top_color    : source_color = vec3( 0.7,  0.75, 1.0  );
	uniform vec3 sunset_bottom_color : source_color = vec3( 1.0,  0.5,  0.7  );
	uniform vec3 night_top_color     : source_color = vec3( 0.02, 0.0,  0.04 );
	uniform vec3 night_bottom_color  : source_color = vec3( 0.1,  0.0,  0.2  );

// ─────────────────────────────────────────────
//  Sun
// ─────────────────────────────────────────────
group_uniforms sun;
	uniform vec3  sun_color        : source_color = vec3( 10.0, 8.0, 1.0 );
	uniform vec3  sun_sunset_color : source_color = vec3( 10.0, 0.0, 0.0 );
	uniform float sun_size  : hint_range( 0.01, 1.0  ) = 0.2;
	uniform float sun_blur  : hint_range( 0.01, 20.0 ) = 10.0;

// ─────────────────────────────────────────────
//  Moon
// ─────────────────────────────────────────────
group_uniforms moon;
	uniform vec3  moon_color : source_color = vec3( 1.0, 0.95, 0.7 );
	uniform float moon_size  : hint_range( 0.01, 1.0  ) = 0.06;
	uniform float moon_blur  : hint_range( 0.01, 10.0 ) = 0.1;

// ─────────────────────────────────────────────
//  Clouds
// ─────────────────────────────────────────────
group_uniforms clouds;
	uniform vec3  clouds_edge_color   : source_color = vec3( 0.8,  0.8,  0.98 );
	uniform vec3  clouds_top_color    : source_color = vec3( 1.0,  1.0,  1.0  );
	uniform vec3  clouds_middle_color : source_color = vec3( 0.92, 0.92, 0.98 );
	uniform vec3  clouds_bottom_color : source_color = vec3( 0.83, 0.83, 0.94 );
	uniform float clouds_speed     : hint_range( 0.0, 20.0, 0.01 ) = 2.0;
	uniform float clouds_direction : hint_range( -0.5, 0.5,  0.0  ) = 0.2;
	uniform float clouds_scale     : hint_range( 0.1,  6.0,  0.01 ) = 2.0;
	uniform float clouds_cutoff    : hint_range( 0.0,  1.0,  0.01 ) = 0.3;
	uniform float clouds_fuzziness : hint_range( 0.0,  2.0,  0.01 ) = 0.5;
	uniform float clouds_weight    : hint_range( 0.0,  1.0,  0.01 ) = 0.0;

// ─────────────────────────────────────────────
//  Stars
// ─────────────────────────────────────────────
group_uniforms stars;
	uniform sampler2D stars_texture : filter_linear_mipmap, hint_default_black;
	uniform float stars_speed : hint_range( 0.0, 20.0, 0.01 ) = 1.0;

// ─────────────────────────────────────────────
//  Globe
// ─────────────────────────────────────────────
group_uniforms globe;
	uniform float globe_alpha      : hint_range( 0.0, 1.0, 0.01 ) = 1.0;
	uniform float fresnel_strength : hint_range( 0.0, 5.0, 0.01 ) = 1.5;
	uniform vec3  fresnel_color    : source_color = vec3( 0.4, 0.8, 1.0 );

group_uniforms settings;
	uniform float overwritten_time = 0.0;

////////////////////////////////////////////////////////////////////////////////////////////////////
// 3D Value Noise — no UV, no projection, works uniformly on any sphere point
////////////////////////////////////////////////////////////////////////////////////////////////////
const int PRIME_X = 501125321;
const int PRIME_Y = 1136930381;
const int PRIME_Z = 1338452629;

float _lerp( float a, float b, float t ) { return a + t * ( b - a ); }

float ping_pong( float t )
{
	t -= trunc( t * 0.5 ) * 2.0;
	return t < 1.0 ? t : 2.0 - t;
}

float val_coord3( int seed, int xp, int yp, int zp )
{
	int h = ( seed ^ xp ^ yp ^ zp ) * 0x27d4eb2d;
	h *= h;
	h ^= h << 19;
	return float( h ) * ( 1.0 / 2147483648.0 );
}

float value_noise_3d( int seed, float x, float y, float z )
{
	int x0 = int( floor( x ));
	int y0 = int( floor( y ));
	int z0 = int( floor( z ));
	float fx = x - float( x0 );
	float fy = y - float( y0 );
	float fz = z - float( z0 );
	// Smoothstep interpolants
	float ux = fx * fx * ( 3.0 - 2.0 * fx );
	float uy = fy * fy * ( 3.0 - 2.0 * fy );
	float uz = fz * fz * ( 3.0 - 2.0 * fz );
	int px0 = x0 * PRIME_X;  int py0 = y0 * PRIME_Y;  int pz0 = z0 * PRIME_Z;
	int px1 = px0 + PRIME_X; int py1 = py0 + PRIME_Y; int pz1 = pz0 + PRIME_Z;
	return _lerp(
		_lerp( _lerp( val_coord3(seed,px0,py0,pz0), val_coord3(seed,px1,py0,pz0), ux ),
		       _lerp( val_coord3(seed,px0,py1,pz0), val_coord3(seed,px1,py1,pz0), ux ), uy ),
		_lerp( _lerp( val_coord3(seed,px0,py0,pz1), val_coord3(seed,px1,py0,pz1), ux ),
		       _lerp( val_coord3(seed,px0,py1,pz1), val_coord3(seed,px1,py1,pz1), ux ), uy ),
	uz );
}

const float FRACTAL_BOUNDING  = 1.0 / 1.75;
const int   OCTAVES            = 5;
const float PING_PONG_STRENGTH = 2.0;
const float WEIGHTED_STRENGTH  = 0.0;
const float GAIN               = 0.5;
const float LACUNARITY         = 2.0;

float gen_fractal_3d( vec3 pos, int seed, float frequency )
{
	float x = pos.x * frequency;
	float y = pos.y * frequency;
	float z = pos.z * frequency;
	float sum = 0.0;
	float amp = FRACTAL_BOUNDING;
	for( int i = 0; i < OCTAVES; i++ )
	{
		float noise = ping_pong(( value_noise_3d( seed++, x, y, z ) + 1.0 ) * PING_PONG_STRENGTH );
		sum += ( noise - 0.5 ) * 2.0 * amp;
		amp *= _lerp( 1.0, noise, WEIGHTED_STRENGTH );
		x *= LACUNARITY;
		y *= LACUNARITY;
		z *= LACUNARITY;
		amp *= GAIN;
	}
	return sum * 0.5 + 0.5;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// Moon phase helper
////////////////////////////////////////////////////////////////////////////////////////////////////
float sphere_intersect( vec3 view_dir, vec3 sphere_pos, float radius )
{
	float b = dot( -sphere_pos, view_dir );
	float c = dot( -sphere_pos, -sphere_pos ) - radius * radius;
	float h = b * b - c;
	return h < 0.0 ? -1.0 : -b - sqrt( h );
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// Varyings
////////////////////////////////////////////////////////////////////////////////////////////////////
varying vec3 world_normal;
varying vec3 local_pos;

////////////////////////////////////////////////////////////////////////////////////////////////////
// Vertex
////////////////////////////////////////////////////////////////////////////////////////////////////
void vertex()
{
	local_pos    = VERTEX;
	world_normal = normalize( ( MODEL_MATRIX * vec4( NORMAL, 0.0 ) ).xyz );
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// Fragment
////////////////////////////////////////////////////////////////////////////////////////////////////
void fragment()
{
	vec3  dir  = normalize( local_pos );
	float time = overwritten_time != 0.0 ? overwritten_time : TIME;

	// ── SKY GRADIENT ─────────────────────────────────────────────────────────
	float ey = dir.y * 0.5 + 0.5;

	vec3 sky_color = mix( day_bottom_color, day_top_color, ey );
	sky_color = mix( sky_color, vec3( 0.0 ), clamp(( 0.7 - clouds_cutoff ) * clouds_weight, 0.0, 1.0 ));

	float sunset_amount   = clamp( 0.5 - abs( sun_direction.y ), 0.0, 0.5 ) * 2.0;
	float sunset_distance = clamp( 1.0 - pow( distance( dir, sun_direction ), 2.0 ), 0.0, 1.0 );
	vec3  sky_sunset      = mix( sunset_bottom_color, sunset_top_color, ey );
	sky_sunset  = mix( sky_sunset, sunset_bottom_color, sunset_amount * sunset_distance );
	sky_color   = mix( sky_color, sky_sunset, sunset_amount );

	float night_amount = clamp( -sun_direction.y + 0.7, 0.0, 1.0 );
	vec3  sky_night    = mix( night_bottom_color, night_top_color, ey );
	sky_color = mix( sky_color, sky_night, night_amount );

	vec3 color = sky_color;

	// ── MOON ─────────────────────────────────────────────────────────────────
	float moon_amount = 0.0;
	if( light1_enabled )
	{
		float m_size  = moon_size + cos( moon_direction.y * PI ) * moon_size * 0.25;
		float m_dist  = distance( dir, moon_direction ) / m_size;
		moon_amount   = clamp(( 1.0 - m_dist ) / moon_blur, 0.0, 1.0 );
		if( moon_amount > 0.0 )
		{
			float m_i     = sphere_intersect( dir, moon_direction, m_size );
			vec3  m_n     = normalize( moon_direction - dir * m_i );
			float m_ndotl = pow( clamp( dot( m_n, -sun_direction ), 0.05, 1.0 ), 2.0 );
			color = mix( color, moon_color, m_ndotl * moon_amount );
		}
	}

	// ── SUN ──────────────────────────────────────────────────────────────────
	float sun_dist = 0.0;
	if( light0_enabled )
	{
		sun_dist       = distance( dir, sun_direction );
		float s_size   = sun_size + cos( sun_direction.y * PI ) * sun_size * 0.25;
		float s_amount = clamp(( 1.0 - sun_dist / s_size ) / sun_blur, 0.0, 1.0 );
		if( s_amount > 0.0 )
		{
			float ss     = ( sun_direction.y > 0.0 ) ? clamp( cos( sun_direction.y * PI ), 0.0, 1.0 ) : 1.0;
			vec3 s_color = mix( sun_color, sun_sunset_color, ss );
			s_amount     = clamp( s_amount * ( 1.0 - moon_amount ), 0.0, 1.0 );
			if( s_color.r > 1.0 || s_color.g > 1.0 || s_color.b > 1.0 )
				s_color *= s_amount;
			color = mix( color, s_color, s_amount );
		}
	}

	// ── STARS ─────────────────────────────────────────────────────────────────
	if( sun_direction.y < 0.0 )
	{
		vec2 sky_uv = dir.xz / sqrt( max( abs( dir.y ), 0.001 ));
		float sc = cos( stars_speed * time * 0.005 );
		float ss = sin( stars_speed * time * 0.005 );
		vec2  st_uv = vec2(
			sky_uv.x * sc - sky_uv.y * ss,
			sky_uv.x * ss + sky_uv.y * sc
		);
		vec3 st_col = texture( stars_texture, st_uv ).rgb * -sun_direction.y;
		st_col *= 1.0 - moon_amount;
		color  += st_col;
	}

	// ── CLOUDS — pure 3D noise, uniform over entire sphere surface ────────────
	{
		float cspeed = time * clouds_speed * 0.01;

		// Drift as a 3D offset rotating around Y — no UV needed
		float drift_angle = clouds_direction * PI * 2.0;
		vec3  drift = vec3( sin( drift_angle ), 0.0, cos( drift_angle ) ) * cspeed;

		// Use the surface direction scaled by clouds_scale as the 3D noise position
		vec3 p = dir * clouds_scale;

		// Three layers with slightly different offsets/seeds for depth
		float n_t = gen_fractal_3d( p + drift,                       0, 0.5  );
		float n_m = gen_fractal_3d( p + drift * 0.89 + vec3( 3.7 ),  1, 0.75 );
		float n_b = gen_fractal_3d( p + drift * 0.79 + vec3( 7.1 ),  2, 1.0  );

		n_b = smoothstep( clouds_cutoff, clouds_cutoff + clouds_fuzziness, n_b );
		n_m = smoothstep( clouds_cutoff, clouds_cutoff + clouds_fuzziness, n_m + n_b * 0.2 ) * 1.1;
		n_t = smoothstep( clouds_cutoff, clouds_cutoff + clouds_fuzziness, n_t + n_m * 0.4 ) * 1.2;

		float ca = clamp( n_t + n_m + n_b, 0.0, 1.0 );

		vec3 cc = mix( vec3( 0.0 ), clouds_top_color, n_t );
		cc = mix( cc, clouds_middle_color, n_m );
		cc = mix( cc, clouds_bottom_color, n_b );
		cc = mix( clouds_edge_color, cc, n_t );
		cc = mix( cc, clamp( sun_color, 0.0, 1.0 ), pow( 1.0 - clamp( sun_dist, 0.0, 1.0 ), 5.0 ));
		cc = mix( cc, sunset_bottom_color, sunset_amount * 0.75 );
		cc = mix( cc, sky_color, clamp( night_amount, 0.0, 0.98 ));
		cc = mix( cc, vec3( 0.0 ), clouds_weight * 0.9 );

		color = mix( color, cc, ca );
	}

	// ── FRESNEL EDGE GLOW ─────────────────────────────────────────────────────
	vec3  view_dir = normalize( CAMERA_POSITION_WORLD - ( MODEL_MATRIX * vec4( local_pos, 1.0 ) ).xyz );
	float fresnel  = pow( 1.0 - abs( dot( world_normal, view_dir ) ), fresnel_strength );
	color = mix( color, fresnel_color, fresnel * 0.4 );

	// Sky background is transparent; clouds, sun, moon and fresnel rim are opaque.
	// cloud alpha: measure how much the final color differs from the bare sky gradient.
	float sky_lum     = dot( sky_color, vec3( 0.333 ) );
	float color_lum   = dot( color,     vec3( 0.333 ) );
	float cloud_alpha = clamp( abs( color_lum - sky_lum ) * 4.0, 0.0, 1.0 );
	float sun_alpha   = light0_enabled ? clamp( 1.0 - sun_dist / max( sun_size, 0.001 ), 0.0, 1.0 ) : 0.0;
	float feature_alpha = clamp( cloud_alpha + sun_alpha + moon_amount + fresnel * 0.5, 0.0, 1.0 );

	ALBEDO = color;
	ALPHA  = feature_alpha * globe_alpha;
}





