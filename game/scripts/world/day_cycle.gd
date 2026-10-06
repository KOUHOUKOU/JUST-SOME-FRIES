extends Node
# "A day goes by while you hunt" (docs/18 §11.6): the sun sets with progress, windows and lamps light up,
# colours grow more saturated with every special fry and fall back to natural at the ending.

var sun
var env
var sky
var win_mat
var lamp_mat
var beam_mat
var cloud_mat
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
	sun.light_color = _k3(Color(1.0, 0.97, 0.9), Color(1.0, 0.78, 0.5), Color(0.95, 0.5, 0.4), u)
	sun.light_energy = _k3(Color(0.9, 0, 0), Color(0.85, 0, 0), Color(0.3, 0, 0), u).r
	sky.sky_top_color = _k3(Color(0.30, 0.52, 0.82), Color(0.38, 0.50, 0.72), Color(0.13, 0.17, 0.36), u)
	var hz = _k3(Color(0.75, 0.86, 0.93), Color(0.98, 0.76, 0.52), Color(0.85, 0.45, 0.42), u)
	sky.sky_horizon_color = hz
	sky.ground_horizon_color = hz
	env.fog_light_color = hz.lerp(Color(1, 1, 1), 0.15)
	env.fog_density = lerp(0.0004, 0.0007, u)
	env.ambient_light_energy = _k3(Color(0.5, 0, 0), Color(0.45, 0, 0), Color(0.35, 0, 0), u).r
	var night = smoothstep(0.6, 0.95, u)
	win_mat.emission_energy_multiplier = night * 2.4
	lamp_mat.emission_energy_multiplier = 0.6 + night * 1.6
	if beam_mat != null:
		beam_mat.albedo_color.a = smoothstep(0.7, 1.0, u) * 0.22
	if cloud_mat != null:
		cloud_mat.albedo_color = Color(1, 1, 1, 0.7).lerp(Color(1.0, 0.72, 0.62, 0.7), u)
	# colour: richer with every special fry, back to natural at the ending, muted in Gull Sense view
	var sat_t = 1.0 + 0.08 * GS.special_count()
	if player != null:
		sat_t = lerp(sat_t, 1.0, player.calm)
	if GS.ordinary_eaten:
		sat_t = 0.96
	if GS.sense_active:
		sat_t = 0.35
	var rate = 0.25 if GS.ordinary_eaten else 1.2
	sat = move_toward(sat, sat_t, delta * rate)
	env.adjustment_saturation = sat
	var glow_t = 0.4 + 0.05 * GS.special_count()
	if GS.ordinary_eaten:
		glow_t = 0.3
	glow = move_toward(glow, glow_t, delta * 0.2)
	env.glow_intensity = glow
