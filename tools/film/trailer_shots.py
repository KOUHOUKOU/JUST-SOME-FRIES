# The cut of the trailer (read by make_trailer.py).  Times are seconds in the recorded segments (film/segN.avi).
#   SHOTS:  (name, source, in, out, speed, fade-in, fade-out)
#   VOICE_LINES: (shot, seconds after the shot starts, text)
#   MUSIC_CUES:  (shot, offset, file in game/assets/audio/music, start in the file, length, volume, fade-in, fade-out)
#   SFX_CUES:    (shot, offset, file in game/assets/audio/sfx, volume)
#   CARD:        (shot, offset, seconds, text, size, y, color)  text laid over the picture
# No story is told here beyond the first question: the end of the game is not in the trailer.

SHOTS = [
    # --- the question: a four-panel comic (the game begins as one)
    ("title",     "seg1.avi",  0.0,  1.3, 1.0, 0.25, 0.0),
    ("comic1",    "seg1.avi", 21.0, 31.4, 2.0, 0.0, 0.0),
    ("comic2",    "seg1.avi", 32.2, 35.4, 1.0, 0.0, 0.25),
    # --- the flight: TAB, take-off, ice cream, a climb and a second look, the coffee dive, the cocktail, RAINBOW TIME
    ("f_roof",    "seg21.avi", 0.8,  4.4, 1.0, 0.2, 0.0),
    ("f_ice",     "seg21.avi", 4.4,  8.2, 1.0, 0.0, 0.0),
    ("f_climb",   "seg21.avi", 8.2, 10.9, 1.0, 0.0, 0.0),
    ("f_coffee",  "seg21.avi", 10.9, 14.2, 1.0, 0.0, 0.0),
    ("f_cocktail","seg21.avi", 14.2, 17.8, 1.0, 0.0, 0.0),
    ("f_rainbow", "seg21.avi", 18.2, 26.6, 1.0, 0.0, 0.0),
    ("g_fly1",    "seg22.avi",  1.0,  4.6, 1.0, 0.0, 0.0),
    ("g_fly2",    "seg22.avi",  7.0, 10.0, 1.0, 0.0, 0.0),
    ("g_fly3",    "seg22.avi", 10.4, 13.4, 1.0, 0.0, 0.2),
    # --- the sky
    ("k_moon_a",  "seg12.avi",  2.4,  5.9, 1.0, 0.0, 0.0),
    ("k_moon_b",  "seg12.avi", 10.6, 12.8, 1.0, 0.0, 0.0),
    ("k_sun_a",   "seg12.avi", 27.6, 31.6, 1.3, 0.0, 0.0),
    ("k_sun_b",   "seg12.avi", 33.4, 36.2, 1.0, 0.0, 0.0),
    ("k_fry",     "seg12.avi", 47.4, 52.0, 1.0, 0.0, 0.2),
    # --- a fish, because why not
    ("fish",      "seg11.avi",  9.2, 15.4, 1.0, 0.2, 0.2),
    # --- all dressed up, and still on the roof
    ("r_orbit",   "seg13.avi",  3.2, 11.6, 1.0, 0.25, 0.0),
    ("r_rumble",  "seg13.avi", 21.8, 26.0, 1.0, 0.0, 0.3),
    # --- the question comes back
    ("black",     "BLACK",     0.0,  3.4, 1.0, 0.0, 0.0),
    ("end",       "seg1.avi",  0.0,  1.2, 0.3, 0.4, 0.5),
]

VOICE_LINES = [
    ("f_roof",     0.3, "Hold Tab. Find what's worth stealing."),
    ("f_ice",      0.4, "Then go and get it."),
    ("f_rainbow",  0.9, "Drink all three... and nothing can catch you."),
    ("k_moon_a",   0.2, "If it's up there, you can catch it."),
    ("fish",       0.6, "Fish. Why not."),
    ("r_orbit",    0.8, "Hat. Shades. Chain. The whole sky."),
    ("black",      0.6, "You came here for some fries... right?"),
]

MUSIC_CUES = [
    ("title",     0.0, "title.ogg",    0.0, 11.0, 0.85, 0.5, 1.4),
    ("f_roof",    0.0, "cine_joy.ogg", 0.0, 13.0, 0.95, 0.4, 0.6),
    ("f_cocktail",1.0, "star.ogg",     0.0, 44.0, 0.85, 0.6, 1.2),
    ("r_orbit",   0.0, "cine_home.ogg",0.0, 12.0, 0.7, 1.0, 1.2),
    ("end",       0.0, "cine_sun.ogg", 0.0, 6.0,  0.95, 0.2, 1.4),
]

SFX_CUES = []
SFX_VOL = 0.85

CARD = [
    ("end", 0.9, 3.6, "Play it on Windows  -  github.com/KOUHOUKOU/JUST-SOME-FRIES", 30, "h-110", "white"),
]
