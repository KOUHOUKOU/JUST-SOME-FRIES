extends Node
# "A day goes by while you hunt" (docs/18 §11.6): the sun sets with progress, windows and lamps light up,
# S2 colour states grow gently richer to a fixed plateau; ending and Gull Sense still override saturation.

var atmosphere
var sun
var env
var sky
var win_mat
var lamp_mat
var beam_mat
var cloud_mat
var storm_mat
var sun_disc = null
var sun_pos = Vector3(0, 110, 170)     # where the sun is in the sky (it is also what the "catch the sun" quest flies to)
var sun_caught = false
const MOON_POS = Vector3(-135.0, 108.0, 118.0)      # the moon hangs out over the western sea (it is as hard to catch as the sun)
var moon_disc = null
var moon_caught = false
var player
var t = 0.0
var target = 0.0
var sat = 1.0
var glow = 0.4
var ending_t = -1.0

func _k3(a, b, c, u):
	if u < 0.55:
		return a.lerp(b, u / 0.55)
	return b.lerp(c, clamp((u - 0.55) / 0.45, 0.0, 1.0))

func compute_target():
	var tt = GS.gull_sense_count * 0.06 + GS.special_count() * 0.052 + min(GS.star_count(), 14) * 0.032
	if GS.ordinary_eaten:
		return t
	return clamp(tt, 0.0, 1.0)

func _process(delta):
	target = compute_target()
	t = move_toward(t, target, delta * 0.05)
	_apply(delta)

func _apply(delta):
	if sun == null:
		return
	var u = clamp(t, 0.0, 1.0)
	var elev = lerp(58.0, 2.0, pow(u, 0.9))
	sun.rotation_degrees = Vector3(-max(elev, 1.5), lerp(-35.0, 15.0, u), 0)
	_place_sun(max(elev, 1.5), lerp(-35.0, 15.0, u))
	# S2 deliberate colour states, without changing progress/time or the catchable sun.
	sun.light_color = _colour(["FFF1DA","FFDFB3","FFC18A","FFB980"],u)
	sun.light_energy = _scalar([.85,.88,.86,.64],u)
	var hz = _colour(["BDD4DE","D3CBCE","E6AC91","D9919A"],u)
	var sun_dir=sun.global_transform.basis.z.normalized()
	sky.set_shader_parameter("zenith",_colour(["467DB3","647EA7","686997","544879"],u))
	sky.set_shader_parameter("middle",_colour(["91B5D3","AAAAC3","A695BC","9A81AE"],u))
	sky.set_shader_parameter("horizon",hz)
	sky.set_shader_parameter("sun_direction",sun_dir)
	sky.set_shader_parameter("dusk",smoothstep(.4,1.0,u))
	env.fog_light_color=hz.lerp(Color("969CC9"),.44)
	env.fog_density=lerp(.00030,.00048,u)
	env.ambient_light_color=_colour(["A5B7DE","A6B0D8","A49DCE","9891C4"],u)
	env.ambient_light_energy=_scalar([.38,.35,.32,.36],u)
	var night=smoothstep(.48,.93,u)
	win_mat.albedo_color=Color("344553").lerp(Color("FFB850"),night)
	win_mat.emission_energy_multiplier=night*.65
	lamp_mat.albedo_color=Color("AAA6A0").lerp(Color("FFD68D"),night)
	lamp_mat.emission_energy_multiplier=night*.48
	if atmosphere!=null:atmosphere.apply(u,hz,sun_dir)
	if beam_mat != null:
		beam_mat.albedo_color.a = smoothstep(0.7, 1.0, u) * 0.22
	if cloud_mat != null:
		cloud_mat.set_shader_parameter("top_col", _colour(["F4F3ED","F4E6DE","F2A190","DF93A6"],u))
		cloud_mat.set_shader_parameter("bottom_col", _colour(["8CABC7","A5A8C1","977694","74638D"],u))
		cloud_mat.set_shader_parameter("glow", lerp(0.42, 0.22, u))
	if storm_mat != null:
		storm_mat.set_shader_parameter("top_col", Color(0.52, 0.56, 0.65).lerp(Color(0.7, 0.45, 0.45), u * 0.7))
		storm_mat.set_shader_parameter("bottom_col", Color(0.24, 0.27, 0.35).lerp(Color(0.3, 0.2, 0.28), u))
		storm_mat.set_shader_parameter("glow", lerp(0.16, 0.1, u))
	if sun_disc != null:
		sun_disc.caught = sun_caught
	if moon_disc != null:
		moon_disc.global_position = MOON_POS
		moon_disc.caught = moon_caught
		var nt = smoothstep(0.35, 0.95, u)
		moon_disc.get_meta("core_mat").albedo_color.a = lerp(0.5, 1.0, nt)
		for hm in moon_disc.get_meta("halo_mats"):
			hm[0].albedo_color = Color(hm[1].r, hm[1].g, hm[1].b, hm[1].a * lerp(0.5, 1.6, nt))
	# colour: richer with every special fry, back to natural at the ending, muted in Gull Sense view
	var sat_t = 1.0 + min(0.012 * GS.special_count(), 0.08)
	if player != null:
		sat_t = lerp(sat_t, 1.0, player.calm)
	if GS.ordinary_eaten:
		sat_t = 0.96
	if GS.sense_active:
		sat_t = 0.35
	var rate = 0.25 if GS.ordinary_eaten else 1.2
	sat = move_toward(sat, sat_t, delta * rate)
	env.adjustment_saturation = sat
	var glow_t = 0.32 + min(0.012 * GS.special_count(), 0.10)
	if GS.ordinary_eaten:
		glow_t = 0.3
	glow = move_toward(glow, glow_t, delta * 0.2)
	env.glow_intensity = glow

# the sun disc hangs where the light comes from: 170 m out over the sea, 90-125 m up (so a strong, fast gull can reach it)
func _place_sun(elev_deg, yaw_deg):
	var yaw = deg_to_rad(yaw_deg)
	var dir = Vector3(sin(yaw), 0.0, cos(yaw))           # the light shines towards -Z, so the sun stands on the +Z (sea) side
	var h = clamp(170.0 * tan(deg_to_rad(elev_deg)), 90.0, 125.0)
	sun_pos = Vector3(0, 0, 10) + dir * 170.0 + Vector3(0, h, 0)
	if sun_disc != null:
		sun_disc.global_position = sun_pos

# Four art keys, separate from the gameplay clock. No new time/progress system.
func _colour(values,u):
	var keys=[0.0,.35,.72,1.0]
	for i in 3:
		if u<=keys[i+1]:return Color(values[i]).lerp(Color(values[i+1]),smoothstep(keys[i],keys[i+1],u))
	return Color(values[3])

func _scalar(values,u):
	var keys=[0.0,.35,.72,1.0]
	for i in 3:
		if u<=keys[i+1]:return lerp(values[i],values[i+1],smoothstep(keys[i],keys[i+1],u))
	return values[3]
