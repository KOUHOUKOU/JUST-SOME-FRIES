shader_type spatial;
render_mode unshaded, cull_back;
// Opaque palette water: no screen/depth texture or reflection pass.
uniform vec4 deep : source_color = vec4(0.09,0.255,0.34,1.0);
uniform vec4 shallow : source_color = vec4(0.12,0.44,0.47,1.0);
uniform vec4 sky_tint : source_color = vec4(0.60,0.71,0.83,1.0);
uniform vec3 sun_direction=vec3(0.0,0.25,1.0);
uniform float day_t=0.0;
uniform bool glitter_enabled=true;
uniform bool headland_foam=false;
varying vec3 wp;
float hash21(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float rect(vec2 p,vec4 b) { return min(min(p.x-b.x,b.y-p.x),min(p.y-b.z,b.w-p.y)); }
float land(vec2 p) {
	float s=clamp(rect(p,vec4(-72,50,-92,27))/7.0,0.0,1.0);
	s=max(s,clamp(rect(p,vec4(8,82,-30,46.0+5.0*sin(p.x*.07)))/8.0,0.0,1.0));
	s=max(s,clamp(rect(p,vec4(50,118,-50,14))/6.0,0.0,1.0));
	s=max(s,clamp(rect(p,vec4(-140,-68,-12,88))/7.0,0.0,1.0));
	s=max(s,clamp(rect(p,vec4(40,118,-94,-44))/7.0,0.0,1.0));
	return max(s,clamp((16.0-length(p-vec2(0,118)))/8.0,0.0,1.0));
}
void vertex() {
	wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	// Flat water silhouette; wave shading below needs no dense displaced grid.
}
void fragment() {
	vec3 view_world=normalize(CAMERA_POSITION_WORLD-wp);
	float s=land(wp.xz);
	float wave=sin(wp.x*.21+wp.z*1.14+TIME*.8+sin(wp.z*.047)*1.6)*sin(wp.z*.74-TIME*.6+sin(wp.x*.08)*2.0);
	wave*=1.0-smoothstep(.40,1.8,fwidth(wp.z)*1.14);
	float horizon=pow(1.0-max(view_world.y,0.0),4.0);
	vec3 col=mix(deep.rgb,shallow.rgb,smoothstep(.06,.72,s)*.78);
	col*=mix(1.0,.80,smoothstep(.65,1.0,day_t));
	col=mix(col,sky_tint.rgb,horizon*.32);
	col+=vec3(.005,.011,.016)*wave*(1.0-horizon);
	float crest=smoothstep(.62,.97,wave)*(.35+.65*pow(max(view_world.y,0.0),.5));
	col=mix(col,shallow.rgb,crest*.12);
	float foam=exp(-pow((s-.73+wave*.012)*46.0,2.0));
	if(headland_foam){
		vec2 q=wp.xz-vec2(-102.0,40.0);float a=atan(q.y,q.x);
		float coast=54.0+3.6*sin(a*3.0+.5)+1.8*sin(a*7.0)-max(0.0,cos(a))*13.0;
		float edge=length(q)-coast;
		float broken=.42+.58*smoothstep(-.5,.6,sin(a*27.0+wave*.4));
		foam=max(foam,exp(-edge*edge/1.5)*broken);
	}
	float pier=abs(abs(wp.x-1.0)-3.7);
	foam=max(foam,(1.0-smoothstep(.06,.38,pier))*step(25.0,wp.z)*step(wp.z,76.0)*(1.0-smoothstep(.16,.55,abs(mod(wp.z-26.0+2.0,4.0)-2.0)))*(.55+.25*wave));
	col=mix(col,vec3(.60,.74,.69),foam*.33);
	if (glitter_enabled) {
		float nx=cos(wp.x*.48+wp.z*.23+TIME*.9)*.055;
		float nz=cos(wp.z*.8+TIME*.7)*.095;
		vec3 n=normalize(vec3(nx,1.0,nz));
		vec3 half_dir=normalize(view_world+sun_direction);
		float glint=pow(max(dot(n,half_dir),0.0),170.0);
		float broken=.25+.75*smoothstep(-.10,.72,wave);
		float strength=mix(.10,.95,smoothstep(.30,.9,day_t));
		// Projected sun azimuth keeps a broken path visible at a very low sun.
		vec2 axis=normalize(sun_direction.xz);
		float along=dot(wp.xz,axis);
		float across=dot(wp.xz,vec2(axis.y,-axis.x));
		float alignment=max(dot(-normalize(view_world.xz),axis),0.0);
		float path=pow(alignment,110.0)*(1.0-smoothstep(.60,.90,view_world.y));
		float ripple=sin(along*2.6+sin(across*.81)*1.5+TIME*.95);
		float aa=max(fwidth(ripple),.06);
		float sparkle=smoothstep(.70-aa,.88+aa,ripple)*(.45+.55*sin(across*1.8+along*.15)*sin(across*1.8+along*.15));
		float variation=hash21(floor(vec2(across*.8,along*1.2)));
		sparkle*=.12+.88*smoothstep(.30,.90,variation);
		float gold=max(glint*broken,path*sparkle)*strength;
		col=mix(col,vec3(1.0,.57,.20),gold);
	}
	ALBEDO=clamp(col,vec3(0),vec3(.97));
}
