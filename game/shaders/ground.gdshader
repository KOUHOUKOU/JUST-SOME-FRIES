shader_type spatial;
render_mode ambient_light_disabled, specular_disabled;
// S3: explicit source-colour palette avoids a second sRGB darkening in Compatibility.
uniform sampler2D noise_a : repeat_enable, filter_linear_mipmap;
uniform sampler2D noise_b : repeat_enable, filter_linear_mipmap;
uniform vec4 grass : source_color=vec4(.32,.48,.13,1);
uniform vec4 sand : source_color=vec4(.91,.81,.59,1);
uniform vec4 stone : source_color=vec4(.38,.31,.26,1);
uniform vec4 paving : source_color=vec4(.63,.55,.43,1);
uniform bool headland_shell=false;
varying vec3 wp;
varying float dist;
float kw(float k,float c){return max(0.0,1.0-abs(k-c)/.2);}
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1)).xyz;dist=length((MODELVIEW_MATRIX*vec4(VERTEX,1)).xyz);}
void fragment(){
 if(headland_shell && length(wp.xz-vec2(-102.0,40.0))>24.0 && length(wp.xz-vec2(-102.0,40.0))<40.2 && wp.y>.4){discard;}
 float k=COLOR.a;float n=texture(noise_a,wp.xz*.018).r;float detail=1.0-smoothstep(35.0,100.0,dist);
 float g=kw(k,0.0);float s=kw(k,.2);float p=kw(k,.4);float c=kw(k,.6);float r=kw(k,.8);float f=kw(k,1.0);
 vec3 col=grass.rgb*g+sand.rgb*s+paving.rgb*p+paving.rgb*.90*c+stone.rgb*r+mix(grass.rgb,stone.rgb,.4)*f;
 // Cafe stone warms locally; keep the rest of the island's approved palette.
 float cafe=(1.0-smoothstep(13.0,19.0,abs(wp.x+8.0)))*(1.0-smoothstep(9.0,13.0,abs(wp.z-4.0)));
 col=mix(col,vec3(.72,.43,.255),cafe*p*.48);
 col*=.97+.065*n;
 vec2 tile=wp.xz/1.8;tile.x+=mod(floor(tile.y),2.0)*.5;vec2 uv=fract(tile);
 float edge=min(min(uv.x,1.0-uv.x),min(uv.y,1.0-uv.y));float aa=max(fwidth(tile.x),fwidth(tile.y));
 float joint=1.0-smoothstep(.009-aa,.021+aa,edge);
 float tile_tone=fract(sin(dot(floor(tile),vec2(12.9898,78.233)))*43758.5453);
 col*=1.0+(tile_tone-.5)*.17*p*cafe;
 col*=1.0-joint*.24*p*detail;
 col*=1.0+sin(wp.y*1.1+n*.8)*.065*r;
 // S6 farm furrows and warm retaining masonry. No geometry / collision changes.
 float furrow=smoothstep(.24,.48,abs(sin((wp.z+90.0)*1.0472)));
 col=mix(col,mix(vec3(.39,.29,.15),grass.rgb*.85,furrow),f*.72);
 float town=step(-72.0,wp.x)*step(wp.x,52.0)*step(-75.0,wp.z)*step(wp.z,-25.0);
 vec2 blocks=vec2(wp.x*.6,wp.y*1.1);blocks.x+=mod(floor(blocks.y),2.0)*.5;
 vec2 cell=fract(blocks);float seam=min(min(cell.x,1.0-cell.x),min(cell.y,1.0-cell.y));
 float mortar=1.0-smoothstep(.018,.06,seam);
 col=mix(col,vec3(.48,.37,.255)*(1.0-mortar*.20),r*town*.72);
 // Shallow coloured sand under the existing playground, preserving its footprint.
 vec2 play_q=abs(wp.xz-vec2(32.5,8.0))-vec2(10.5,5.6);
 float play_d=length(max(play_q,vec2(0.0)))+min(max(play_q.x,play_q.y),0.0);
 float play=1.0-smoothstep(-.12,.12,play_d);
 float play_edge=1.0-smoothstep(.15,.40,abs(play_d+.35));
 col=mix(col,mix(vec3(.64,.39,.23),sand.rgb,play_edge*.75),play*s*.28);
 float wet=(1.0-smoothstep(-.6,.15,wp.y))*s;
 col*=1.0-wet*.13;
 ALBEDO=col;ROUGHNESS=1.0;
}
void light(){
 float n=max(dot(NORMAL,LIGHT),0.0);
 if(LIGHT_IS_DIRECTIONAL){
  vec3 hue=LIGHT_COLOR/max(max(LIGHT_COLOR.r,LIGHT_COLOR.g),max(LIGHT_COLOR.b,.001));
  DIFFUSE_LIGHT+=mix(vec3(.17,.23,.37),mix(vec3(1.0),hue,.28),smoothstep(.0,.78,n)*ATTENUATION);
 }
}
