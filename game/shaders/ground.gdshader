shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
// The ground of the town. The vertex colour is the base colour, its ALPHA says what kind of ground it is:
//   0.0 grass   0.2 sand   0.4 paving   0.6 concrete   0.8 rock   1.0 farmland
// Everything else (patches, blades, flowers, ripples, flagstones, furrows, grit) is made here from two noise images and a little maths,
// fades out with distance, and nudges the normal a little so the light has something to catch.

uniform sampler2D noise_a : repeat_enable, filter_linear_mipmap;
uniform sampler2D noise_b : repeat_enable, filter_linear_mipmap;

varying vec3 wpos;
varying float dist;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float kindw(float a, float c) {
	return clamp(1.0 - abs(a - c) / 0.2, 0.0, 1.0);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	dist = length((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
}

void fragment() {
	vec3 base = mix(pow((COLOR.rgb + vec3(0.055)) / 1.055, vec3(2.4)), COLOR.rgb / 12.92, vec3(lessThan(COLOR.rgb, vec3(0.04045))));   // vertex colours are sRGB
	float k = COLOR.a;
	vec2 p = wpos.xz;
	float detail = 1.0 - smoothstep(60.0, 170.0, dist);
	float wg = kindw(k, 0.0);
	float ws = kindw(k, 0.2);
	float wp = kindw(k, 0.4);
	float wc = kindw(k, 0.6);
	float wr = kindw(k, 0.8);
	float wf = kindw(k, 1.0);
	float wsum = max(wg + ws + wp + wc + wr + wf, 0.001);
	wg /= wsum; ws /= wsum; wp /= wsum; wc /= wsum; wr /= wsum; wf /= wsum;

	float big = texture(noise_a, p * 0.012).r;                   // broad patches
	float mid = texture(noise_a, p * 0.07 + 3.1).r;
	float cel = texture(noise_b, p * 0.55).r;                    // fine cells
	float cel2 = texture(noise_b, p * 1.9 + 7.7).r;
	vec3 col = base;
	float bump = 0.0;

	// ---- grass: lighter and darker patches, mown stripes, blade streaks, the odd flower
	if (wg > 0.01) {
		vec3 g = base * 1.16 * (0.88 + 0.34 * big);
		g *= 0.94 + 0.12 * mid;
		g = mix(g, g * vec3(1.12, 1.08, 0.78), smoothstep(0.62, 0.9, mid) * 0.5);   // dry yellowish patches
		float blades = texture(noise_b, vec2(p.x * 2.6, p.y * 0.55)).r;
		g *= 1.0 + (blades - 0.5) * 0.28 * detail;
		g *= 1.0 + (cel2 - 0.5) * 0.22 * detail;
		vec2 fc = floor(p * 1.1);
		float fr = hash21(fc);
		vec2 off = vec2(hash21(fc + 3.3), hash21(fc + 9.1));
		float d = length(fract(p * 1.1) - (0.2 + 0.6 * off));
		float fl = step(0.955, fr) * (1.0 - smoothstep(0.07, 0.1, d)) * detail;
		vec3 fcol = vec3(1.0, 0.45 + 0.5 * hash21(fc + 1.7), 0.6 + 0.3 * hash21(fc + 5.5));
		if (hash21(fc + 2.2) > 0.6) fcol = vec3(1.0, 0.92, 0.35);
		if (hash21(fc + 8.8) > 0.8) fcol = vec3(1.0);
		g = mix(g, fcol, fl);
		col = mix(col, g, wg);
		bump += (blades - 0.5) * 0.5 * wg;
	}
	// ---- sand: ripples, shells, grit, wet darker band near the water
	if (ws > 0.01) {
		float rip = sin((p.x * 0.7 + p.y * 1.3) * 1.6 + mid * 6.0);
		vec3 s = base * 1.6 * (0.93 + 0.12 * big);
		s = mix(s, vec3(dot(s, vec3(0.33))) * vec3(1.05, 1.0, 0.9), 0.25);
		s *= 1.0 + rip * 0.045 * detail;
		s *= 1.0 + (cel2 - 0.5) * 0.18 * detail;
		vec2 sc = p * 2.3;
		float shell = step(0.985, hash21(floor(sc))) * (1.0 - smoothstep(0.08, 0.16, length(fract(sc) - 0.5))) * detail;
		s = mix(s, vec3(0.97, 0.9, 0.84), shell * 0.8);
		float wet = 1.0 - smoothstep(-0.5, 0.35, wpos.y);
		s = mix(s, s * vec3(0.78, 0.74, 0.7), wet);
		col = mix(col, s, ws);
		bump += rip * 0.18 * ws * detail;
	}
	// ---- paving: flagstones with joints, every stone its own tone, a little moss in the joints
	if (wp > 0.01) {
		vec2 tp = p / 1.8;
		vec2 row = vec2(floor(tp.y), 0.0);
		tp.x += mod(row.x, 2.0) * 0.5;                          // brick bond
		vec2 f = fract(tp);
		vec2 id = floor(tp);
		float e = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y));
		float joint = 1.0 - smoothstep(0.0, 0.045, e);
		float tone = hash21(id);
		vec3 s2 = base * 1.35 * (0.9 + 0.2 * tone);
		s2 *= 0.96 + 0.1 * big;
		s2 *= 1.0 + (cel2 - 0.5) * 0.16 * detail;
		s2 = mix(s2, vec3(0.78, 0.71, 0.60) * (0.9 + 0.15 * tone), step(0.86, hash21(id + 4.4)) * 0.35);   // warm stones
		vec3 jc = mix(s2 * 0.55, vec3(0.34, 0.42, 0.26), smoothstep(0.55, 0.8, mid) * 0.7);
		s2 = mix(s2, jc, joint * (0.35 + 0.65 * detail));
		col = mix(col, s2, wp);
		bump -= joint * 0.5 * wp * detail;
	}
	// ---- concrete: big slabs with thin cracks and oil stains
	if (wc > 0.01) {
		vec2 tp2 = p / 4.5;
		vec2 f2 = fract(tp2);
		float e2 = min(min(f2.x, 1.0 - f2.x), min(f2.y, 1.0 - f2.y));
		float joint2 = 1.0 - smoothstep(0.0, 0.02, e2);
		vec3 c = base * 1.3 * (0.9 + 0.2 * big);
		c *= 1.0 + (cel - 0.5) * 0.12 * detail;
		c = mix(c, c * 0.62, joint2);
		c = mix(c, c * 0.8, smoothstep(0.72, 0.9, mid) * 0.5);
		col = mix(col, c, wc);
		bump -= joint2 * 0.4 * wc * detail;
	}
	// ---- rock: strata and grit
	if (wr > 0.01) {
		float strata = sin(wpos.y * 3.1 + mid * 5.0);
		vec3 r = base * 1.7 * (0.85 + 0.25 * big);
		r = mix(r, r * vec3(1.15, 1.0, 0.8), smoothstep(0.4, 0.8, mid) * 0.5);
		r *= 1.0 + strata * 0.07;
		r *= 1.0 + (cel - 0.5) * 0.3 * detail;
		col = mix(col, r, wr);
		bump += (cel - 0.5) * 0.8 * wr * detail;
	}
	// ---- farmland: furrows
	if (wf > 0.01) {
		float fur = sin(p.y * 2.2);
		vec3 fm = base * (0.92 + 0.14 * mid);
		fm *= 1.0 + fur * 0.09 * detail;
		fm *= 1.0 + (cel2 - 0.5) * 0.2 * detail;
		col = mix(col, fm, wf);
		bump += fur * 0.25 * wf * detail;
	}

	ALBEDO = col;
	ROUGHNESS = 1.0;
	// a gentle bump from the screen-space slope of the detail
	vec3 n = NORMAL;
	n.x += clamp(dFdx(bump) * 14.0, -0.3, 0.3) * detail;
	n.y += clamp(dFdy(bump) * 14.0, -0.3, 0.3) * detail;
	NORMAL = normalize(n);
}
