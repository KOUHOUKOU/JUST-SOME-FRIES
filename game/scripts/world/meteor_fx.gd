extends RefCounted
# the pieces a shooting star is made of (see meteors.gd): a cone-shaped tail with a fade, a soft additive glow, a billboard

static var _tail_mesh = {}
static var _tail_mat = null

static func tail_mesh(length, radius):
	var key = "%d_%d" % [int(length), int(radius * 10.0)]
	if _tail_mesh.has(key):
		return _tail_mesh[key]
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n = 10
	for i in n:
		var a0 = TAU * i / n
		var a1 = TAU * (i + 1) / n
		var p0 = Vector3(cos(a0) * radius, sin(a0) * radius, 0.0)
		var p1 = Vector3(cos(a1) * radius, sin(a1) * radius, 0.0)
		var tip = Vector3(0, 0, length)
		st.set_uv(Vector2(0, 1))
		st.add_vertex(p0)
		st.set_uv(Vector2(0, 0))
		st.add_vertex(tip)
		st.set_uv(Vector2(0, 1))
		st.add_vertex(p1)
	var m = st.commit()
	_tail_mesh[key] = m
	return m

static func tail_material():
	if _tail_mat == null:
		var sh = Shader.new()
		sh.code = """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec4 col_head : source_color = vec4(1.0, 0.95, 0.75, 1.0);
uniform vec4 col_tail : source_color = vec4(0.45, 0.8, 1.0, 1.0);
uniform float power = 1.7;
uniform float strength = 1.0;
void fragment() {
	float k = clamp(UV.y, 0.0, 1.0);
	ALBEDO = mix(col_tail.rgb, col_head.rgb, pow(k, 0.6));
	ALPHA = pow(k, power) * strength;
}
"""
		_tail_mat = ShaderMaterial.new()
		_tail_mat.shader = sh
	return _tail_mat

static func glow_mat(tex, col):
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = tex
	m.albedo_color = col
	m.no_depth_test = false
	m.disable_receive_shadows = true
	return m

static func billboard(size, tex, col):
	var mi = MeshInstance3D.new()
	var q = QuadMesh.new()
	q.size = Vector2(size, size)
	mi.mesh = q
	mi.material_override = glow_mat(tex, col)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

