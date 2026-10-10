shader_type spatial;
render_mode ambient_light_disabled, specular_disabled;
uniform vec4 wood : source_color=vec4(.76,.445,.19,1);
varying vec3 wp;
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1)).xyz;}
void fragment(){
	vec2 p=wp.xz;float row=floor(p.y/.42);float along=p.x+mod(row,3.0)*1.4;
	float seam=min(fract(p.y/.42),1.0-fract(p.y/.42));
	float end=min(fract(along/4.6),1.0-fract(along/4.6));
	float aa=max(fwidth(p.y/.42),.008);
	float joint=(1.0-smoothstep(.015-aa,.035+aa,seam))*.18+(1.0-smoothstep(.002,.008+fwidth(along/4.6),end))*.09;
	float tone=fract(sin(row*73.13)*142.17);
	ALBEDO=wood.rgb*(.84+.29*tone)*(1.0-joint*1.25);ROUGHNESS=.9;
}
void light(){
 float n=max(dot(NORMAL,LIGHT),0.0);
 if(LIGHT_IS_DIRECTIONAL){
  vec3 hue=LIGHT_COLOR/max(max(LIGHT_COLOR.r,LIGHT_COLOR.g),max(LIGHT_COLOR.b,.001));
  DIFFUSE_LIGHT+=mix(vec3(.17,.23,.37),mix(vec3(1.0),hue,.24),smoothstep(.0,.78,n)*ATTENUATION);
 }
}
