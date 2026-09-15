shader_type sky;
render_mode use_quarter_res_pass;

// Originaly based on https://godotshaders.com/shader/stylized-sky-shader-with-clouds/ but there's not much left

group_uniforms sky;
	uniform vec3 day_top_color : source_color = vec3( 0.1, 0.6, 1.0 );
	uniform vec3 day_bottom_color : source_color = vec3( 0.4, 0.8, 1.0 );
	uniform vec3 sunset_top_color : source_color = vec3( 0.7, 0.75, 1.0 );
	uniform vec3 sunset_bottom_color : source_color = vec3( 1.0, 0.5, 0.7 );
	uniform vec3 night_top_color : source_color = vec3( 0.02, 0.0, 0.04 );
	uniform vec3 night_bottom_color : source_color = vec3( 0.1, 0.0, 0.2 );

group_uniforms horizon;
	uniform vec3 horizon_color : source_color = vec3( 0.0, 0.7, 0.8 );
	uniform float horizon_blur : hint_range( 0.0, 1.0, 0.01 ) = 0.05;

group_uniforms sun;
	uniform vec3 sun_color : source_color = vec3( 10.0, 8.0, 1.0 );
	uniform vec3 sun_sunset_color : source_color = vec3( 10.0, 0.0, 0.0 );
	uniform float sun_size : hint_range( 0.01, 1.0 ) = 0.2;
	uniform float sun_blur : hint_range( 0.01, 20.0 ) = 10.0;

group_uniforms moon;
	uniform vec3  moon_bright_color   : source_color = vec3( 0.95, 0.93, 0.88 );
	uniform vec3  moon_dark_color     : source_color = vec3( 0.25, 0.23, 0.20 );
	uniform float moon_size           : hint_range( 0.01, 0.5 ) = 0.06;
	uniform float moon_blur           : hint_range( 0.0,  1.0 ) = 0.05;
	uniform float moon_crater_scale   : hint_range( 1.0, 20.0 ) = 6.0;
	uniform float moon_crater_depth   : hint_range( 0.0,  1.0 ) = 0.55;
	uniform float moon_noise_scale    : hint_range( 1.0, 20.0 ) = 8.0;
	uniform float moon_noise_strength : hint_range( 0.0,  1.0 ) = 0.25;

group_uniforms clouds;
//	uniform sampler2D clouds_top_texture    : filter_linear_mipmap, hint_default_black;
//	uniform sampler2D clouds_middle_texture : filter_linear_mipmap, hint_default_black;
//	uniform sampler2D clouds_bottom_texture : filter_linear_mipmap, hint_default_black;
	uniform vec3  clouds_edge_color   : source_color = vec3( 0.8, 0.8, 0.98 );
	uniform vec3  clouds_top_color    : source_color = vec3( 1.0, 1.0, 1.00 );
	uniform vec3  clouds_middle_color : source_color = vec3( 0.92, 0.92, 0.98 );
	uniform vec3  clouds_bottom_color : source_color = vec3( 0.83, 0.83, 0.94 );
	uniform float clouds_speed        : hint_range( 0.0, 20.0, 0.01 ) = 2.0;
	uniform float clouds_direction    : hint_range( -0.5, 0.5, 0.0 )  = 0.2;
	uniform float clouds_scale        : hint_range( 0.0,  4.0, 0.01 ) = 1.0;
	uniform float clouds_cutoff       : hint_range( 0.0,  1.0, 0.01 ) = 0.3;
	uniform float clouds_fuzziness    : hint_range( 0.0,  2.0, 0.01 ) = 0.5;
	uniform float clouds_weight       : hint_range( 0.0,  1.0, 0.01 ) = 0.0;
	uniform float clouds_blur         : hint_range( 0.0,  1.0, 0.01 ) = 0.25;

group_uniforms stars;
	uniform sampler2D stars_texture : filter_linear_mipmap, hint_default_black;
	uniform float stars_speed : hint_range( 0.0, 20.0, 0.01 ) = 1.0;

group_uniforms settings;
	uniform float overwritten_time = 0.0;

////////////////////////////////////////////////////////////////////////////////////////////////////
// Cloud noise — FastNoiseLite cubic fractal ping-pong
////////////////////////////////////////////////////////////////////////////////////////////////////
	const int PRIME_X = 501125321;
	const int PRIME_Y = 1136930381;
	float lerp( float a, float b, float t ) { return a + t * ( b - a ); }
	float cubic_lerp( float a, float b, float c, float d, float t )
	{
		float p = d - c - ( a - b );
		return t * t * t * p + t * t * ( a - b - p ) + t * ( c - a ) + b;
	}
	float ping_pong( float t )
	{
		t -= trunc( t * 0.5 ) * 2.0;
		return t < 1.0 ? t : 2.0 - t;
	}
	int ihash( int seed, int xp, int yp ) { return ( seed ^ xp ^ yp ) * 0x27d4eb2d; }
	float val_coord( int seed, int xp, int yp )
	{
		int h = ihash( seed, xp, yp );
		h *= h;
		h ^= h << 19;
		return float( h ) * ( 1.0 / 2147483648.0 );
	}
	float single_value_cubic( int seed, float x, float y )
	{
		int x1 = int( floor( x ) ) * PRIME_X;
		int y1 = int( floor( y ) ) * PRIME_Y;
		float xs = x - floor( x );
		float ys = y - floor( y );
		int x0 = x1 - PRIME_X; int x2 = x1 + PRIME_X; int x3 = x1 + ( PRIME_X << 1 );
		int y0 = y1 - PRIME_Y; int y2 = y1 + PRIME_Y; int y3 = y1 + ( PRIME_Y << 1 );
		return cubic_lerp(
			cubic_lerp( val_coord(seed,x0,y0), val_coord(seed,x1,y0), val_coord(seed,x2,y0), val_coord(seed,x3,y0), xs ),
			cubic_lerp( val_coord(seed,x0,y1), val_coord(seed,x1,y1), val_coord(seed,x2,y1), val_coord(seed,x3,y1), xs ),
			cubic_lerp( val_coord(seed,x0,y2), val_coord(seed,x1,y2), val_coord(seed,x2,y2), val_coord(seed,x3,y2), xs ),
			cubic_lerp( val_coord(seed,x0,y3), val_coord(seed,x1,y3), val_coord(seed,x2,y3), val_coord(seed,x3,y3), xs ),
		ys ) * ( 1.0 / ( 1.5 * 1.5 ) );
	}
	const float FRACTAL_BOUNDING  = 1.0 / 1.75;
	const int   OCTAVES           = 5;
	const float PING_PONG_STRENGTH = 2.0;
	const float WEIGHTED_STRENGTH  = 0.0;
	const float GAIN               = 0.5;
	const float LACUNARITY         = 2.0;
	float gen_fractal_ping_pong( vec2 pos, int seed, float frequency )
	{
		float x = pos.x * frequency;
		float y = pos.y * frequency;
		float sum = 0.0;
		float amp = FRACTAL_BOUNDING;
		for( int i = 0; i < OCTAVES; i++ )
		{
			float noise = ping_pong( ( single_value_cubic( seed++, x, y ) + 1.0 ) * PING_PONG_STRENGTH );
			sum += ( noise - 0.5 ) * 2.0 * amp;
			amp *= lerp( 1.0, noise, WEIGHTED_STRENGTH );
			x   *= LACUNARITY;
			y   *= LACUNARITY;
			amp *= GAIN;
		}
		return sum * 0.5 + 0.5;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////
// Moon surface noise — hash/fbm/crater field operating on 2D disc UV
////////////////////////////////////////////////////////////////////////////////////////////////////
	float moon_hash( vec2 p )
	{
		vec3 p3 = fract( vec3( p.x, p.y, p.x ) * 0.3183099 + 0.1 );
		p3 *= 17.0;
		return fract( p3.x * p3.y * p3.z * ( p3.x + p3.y + p3.z ) );
	}
	float moon_noise( vec2 p )
	{
		vec2 i = floor( p );
		vec2 f = fract( p );
		f = f * f * ( 3.0 - 2.0 * f );
		return mix(
			mix( moon_hash( i ),                moon_hash( i + vec2(1.0, 0.0) ), f.x ),
			mix( moon_hash( i + vec2(0.0, 1.0) ), moon_hash( i + vec2(1.0, 1.0) ), f.x ),
		f.y );
	}
	float moon_fbm( vec2 p, int octaves )
	{
		float value = 0.0;
		float amp   = 0.5;
		float freq  = 1.0;
		for( int i = 0; i < 5; i++ )
		{
			if( i >= octaves ) break;
			value += amp * moon_noise( p * freq );
			amp   *= 0.5;
			freq  *= 2.0;
		}
		return clamp( value, 0.0, 1.0 );
	}
	float moon_crater_albedo( vec2 uv, float scale )
	{
		vec2  p      = uv * scale;
		vec2  cell   = floor( p );
		vec2  offset = fract( p );
		float result = 1.0;
		for( int i = -1; i <= 1; i++ )
		{
			for( int j = -1; j <= 1; j++ )
			{
				vec2  nb = cell + vec2( float(i), float(j) );
				float h1 = moon_hash( nb );
				float h2 = moon_hash( nb + vec2( 3.7, 8.3 ) );
				float h3 = moon_hash( nb + vec2( 6.1, 2.9 ) );
				float radius   = 0.25 + h3 * 0.35;
				float strength = 0.4  + h1 * 0.6;
				float t = length( offset - vec2( float(i), float(j) ) - vec2( h1, h2 ) ) / radius;
				if( t < 1.2 )
				{
					float bowl = 1.0 - smoothstep( 0.0, 0.85, t );
					float rim  = smoothstep( 0.6, 1.0, t ) * ( 1.0 - smoothstep( 1.0, 1.2, t ) );
					float alb  = 1.0 - bowl * 0.85 * strength + rim * 0.5 * strength;
					result = min( result, alb );
				}
			}
		}
		return result;
	}
////////////////////////////////////////////////////////////////////////////////////////////////////

void sky()
{
	float time = overwritten_time != 0.0 ? overwritten_time : TIME;

	//////////////////// SKY ///////////////////////////////////////////////////////////////////////
	float _eyedir_y = abs( sin( EYEDIR.y * PI * 0.5 ) );

	vec3 _sky_color = mix( day_bottom_color, day_top_color, _eyedir_y );
	_sky_color = mix( _sky_color, vec3(0.0), clamp( (0.7 - clouds_cutoff) * clouds_weight, 0.0, 1.0 ) );

	float _sunset_amount   = clamp( 0.5 - abs( LIGHT0_DIRECTION.y ), 0.0, 0.5 ) * 2.0;
	float _sunset_distance = clamp( 1.0 - pow( distance( EYEDIR, LIGHT0_DIRECTION ), 2.0 ), 0.0, 1.0 );
	vec3  _sky_sunset_color = mix( sunset_bottom_color, sunset_top_color, _eyedir_y + 0.5 );
	_sky_sunset_color = mix( _sky_sunset_color, sunset_bottom_color, _sunset_amount * _sunset_distance );
	_sky_color = mix( _sky_color, _sky_sunset_color, _sunset_amount );

	float _night_amount    = clamp( -LIGHT0_DIRECTION.y + 0.7, 0.0, 1.0 );
	vec3  _sky_night_color = mix( night_bottom_color, night_top_color, _eyedir_y );
	_sky_color = mix( _sky_color, _sky_night_color, _night_amount );

	COLOR = _sky_color;

	//////////////////// HORIZON ///////////////////////////////////////////////////////////////////
	float _horizon_amount = 0.0;
	if( EYEDIR.y < 0.0 )
	{
		_horizon_amount = clamp( abs( EYEDIR.y ) / horizon_blur, 0.0, 1.0 );
		vec3 _horizon_color = mix( horizon_color, _sky_color, _night_amount * 0.9 );
		_horizon_color = mix( _horizon_color, vec3(0.0), (1.0 - clouds_cutoff) * clouds_weight * 0.7 );
		COLOR = mix( COLOR, _horizon_color, _horizon_amount );
	}

	//////////////////// MOON //////////////////////////////////////////////////////////////////////
	// Moon is opposite the sun. Only draw it when:
	//   1. the sun is strictly below the horizon  (LIGHT0_DIRECTION.y < 0)
	//   2. we are looking at the upper hemisphere (EYEDIR.y > 0)
	float _moon_amount = 0.0;
	if( LIGHT0_ENABLED && LIGHT0_DIRECTION.y < 0.0 && EYEDIR.y > 0.0 )
	{
		vec3 _moon_pos = -LIGHT0_DIRECTION;  // always points upward here because LIGHT0_DIRECTION.y < 0

		vec3  _moon_up    = vec3( 0.0, 1.0, 0.0 );
		vec3  _moon_right = normalize( cross( _moon_up, _moon_pos ) );
		_moon_up          = normalize( cross( _moon_pos, _moon_right ) );

		float _u    = dot( EYEDIR - _moon_pos, _moon_right ) / moon_size;
		float _v    = dot( EYEDIR - _moon_pos, _moon_up    ) / moon_size;
		float _disc = length( vec2( _u, _v ) );

		float _disc_mask = 1.0 - smoothstep( 1.0 - moon_blur, 1.0, _disc );

		if( _disc_mask > 0.0 )
		{
			vec2  _moon_uv  = vec2( _u, _v );
			float _craters  = moon_crater_albedo( _moon_uv, moon_crater_scale );
			float _fine     = moon_fbm( _moon_uv * moon_noise_scale, 4 );
			float _surface  = _craters * ( 1.0 - moon_noise_strength * ( 1.0 - _fine ) );
			// Limb darkening
			_surface       *= 1.0 - pow( clamp( _disc, 0.0, 1.0 ), 2.5 ) * 0.35;

			vec3  _moon_color        = mix( moon_dark_color, moon_bright_color, clamp( _surface, 0.0, 1.0 ) );
			// Fade in as sun dips below horizon, full brightness past ~11 degrees
			float _moon_visibility   = clamp( -LIGHT0_DIRECTION.y * 5.0, 0.0, 1.0 );
			// Soft fade at horizon
			float _moon_horizon_fade = clamp( _moon_pos.y / 0.05, 0.0, 1.0 );

			_moon_amount = _disc_mask * _moon_visibility * _moon_horizon_fade;
			COLOR = mix( COLOR, _moon_color, _moon_amount );
		}
	}

	//////////////////// SUN ///////////////////////////////////////////////////////////////////////
	float _sun_distance = 0.0;
	if( LIGHT0_ENABLED )
	{
		_sun_distance = distance( EYEDIR, LIGHT0_DIRECTION );
		float _sun_size   = sun_size + cos( LIGHT0_DIRECTION.y * PI ) * sun_size * 0.25;
		float _sun_amount = clamp( ( 1.0 - _sun_distance / _sun_size ) / sun_blur, 0.0, 1.0 );
		if( _sun_amount > 0.0 )
		{
			float _sunset_amount_sun = 1.0;
			if( LIGHT0_DIRECTION.y > 0.0 )
				_sunset_amount_sun = clamp( cos( LIGHT0_DIRECTION.y * PI ), 0.0, 1.0 );
			vec3 _sun_color = mix( sun_color, sun_sunset_color, _sunset_amount_sun );
			_sun_amount *= 1.0 - _horizon_amount;
			if( _sun_color.r > 1.0 || _sun_color.g > 1.0 || _sun_color.b > 1.0 )
				_sun_color *= _sun_amount;
			COLOR = mix( COLOR, _sun_color, _sun_amount );
		}
	}

	//////////////////// STARS /////////////////////////////////////////////////////////////////
	vec2 _sky_uv = EYEDIR.xz / sqrt( EYEDIR.y );
	if( EYEDIR.y > -0.01 && LIGHT0_DIRECTION.y < 0.0 )
	{
		float _stars_speed_cos = cos( stars_speed * time * 0.005 );
		float _stars_speed_sin = sin( stars_speed * time * 0.005 );
		vec2 _stars_uv = vec2(
			_sky_uv.x * _stars_speed_cos - _sky_uv.y * _stars_speed_sin,
			_sky_uv.x * _stars_speed_sin + _sky_uv.y * _stars_speed_cos
		);
		vec3 _stars_color = texture( stars_texture, _stars_uv ).rgb * -LIGHT0_DIRECTION.y;
		_stars_color *= 1.0 - _moon_amount;
		COLOR += _stars_color;
	}

	//////////////////// CLOUDS ////////////////////////////////////////////////////////////////
	if( EYEDIR.y > 0.0 )
	{
		float _clouds_speed = time * clouds_speed * 0.01;
		float _sin_x = sin( clouds_direction * PI * 2.0 );
		float _cos_y = cos( clouds_direction * PI * 2.0 );

		vec2 _clouds_movement = vec2( _sin_x, _cos_y ) * _clouds_speed;
//		float _noise_top = texture( clouds_top_texture, ( _sky_uv + _clouds_movement ) * clouds_scale ).r;
		float _noise_top = gen_fractal_ping_pong( ( _sky_uv + _clouds_movement ) * clouds_scale, 0, 0.5 );
		_clouds_movement = vec2( _sin_x * 0.97, _cos_y * 1.07 ) * _clouds_speed * 0.89;
//		float _noise_middle = texture( clouds_middle_texture, ( _sky_uv + _clouds_movement ) * clouds_scale ).r;
		float _noise_middle = gen_fractal_ping_pong( ( _sky_uv + _clouds_movement ) * clouds_scale, 1, 0.75 );
		_clouds_movement = vec2( _sin_x * 1.01, _cos_y * 0.89 ) * _clouds_speed * 0.79;
//		float _noise_bottom = texture( clouds_bottom_texture, ( _sky_uv + _clouds_movement ) * clouds_scale ).r;
		float _noise_bottom = gen_fractal_ping_pong( ( _sky_uv + _clouds_movement ) * clouds_scale, 2, 1.0 );

		_noise_bottom = smoothstep( clouds_cutoff, clouds_cutoff + clouds_fuzziness, _noise_bottom );
		_noise_middle = smoothstep( clouds_cutoff, clouds_cutoff + clouds_fuzziness, _noise_middle + _noise_bottom * 0.2 ) * 1.1;
		_noise_top    = smoothstep( clouds_cutoff, clouds_cutoff + clouds_fuzziness, _noise_top    + _noise_middle * 0.4 ) * 1.2;
		float _clouds_amount = clamp( _noise_top + _noise_middle + _noise_bottom, 0.0, 1.0 );
		_clouds_amount *= clamp( abs( EYEDIR.y ) / clouds_blur, 0.0, 1.0 );

		vec3 _clouds_color = mix( vec3(0.0), clouds_top_color, _noise_top );
		_clouds_color = mix( _clouds_color, clouds_middle_color, _noise_middle );
		_clouds_color = mix( _clouds_color, clouds_bottom_color, _noise_bottom );
		_clouds_color = mix( clouds_edge_color, _clouds_color, _noise_top );
		_clouds_color = mix( _clouds_color, clamp( sun_color, 0.0, 1.0 ), pow( 1.0 - clamp( _sun_distance, 0.0, 1.0 ), 5.0 ) );
		_clouds_color = mix( _clouds_color, sunset_bottom_color, _sunset_amount * 0.75 );
		_clouds_color = mix( _clouds_color, _sky_color, clamp( _night_amount, 0.0, 0.98 ) );
		_clouds_color = mix( _clouds_color, vec3(0.0), clouds_weight * 0.9 );
		COLOR = mix( COLOR, _clouds_color, _clouds_amount );
	}
}