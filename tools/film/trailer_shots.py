# The cut of the trailer (read by make_trailer.py).  Times are seconds in the recorded segments (film/segN.avi).
#   SHOTS:  (name, source, in, out, speed, fade-in, fade-out)
#   VOICE_LINES: (shot, seconds after the shot starts, text)
#   MUSIC_CUES:  (shot, offset, file in game/assets/audio/music, start in the file, length, volume, fade-in, fade-out)
#   SFX_CUES:    (shot, offset, file in game/assets/audio/sfx, volume)
#   CARD:        (shot, offset, seconds, text, size, y, color)  text laid over the picture
# Acts: 1 what is this (cover, the opening, the question)  2 how it plays (the first fry, Gull Sight, one long flight, RAINBOW TIME)
#       3 how far it goes (the sky, a fish, the dressed-up gull)  4 the question comes back.  The end of the game is not in the trailer.

SHOTS = [
    # ---- 1  what is this
    ("title",     "seg1.avi",  0.0,  1.7, 1.0, 0.25, 0.0),
    ("open",      "seg1.avi",  5.2, 10.8, 1.25, 0.0, 0.0),
    ("open_b",    "seg1.avi", 16.4, 20.2, 1.0, 0.0, 0.0),
    ("comic1",    "seg1.avi", 21.0, 31.4, 2.0, 0.0, 0.0),
    ("comic2",    "seg1.avi", 32.2, 35.4, 1.0, 0.0, 0.25),
    # ---- 2  how it plays: the first fry
    ("ff1",       "seg30.avi",  3.0, 10.2, 1.0, 0.2, 0.0),
    ("ff2",       "seg30.avi", 12.2, 14.9, 1.0, 0.0, 0.0),
    ("ff3",       "seg30.avi", 17.2, 20.2, 1.0, 0.0, 0.0),
    ("ff4",       "seg30.avi", 20.4, 23.6, 1.0, 0.0, 0.0),
    # ---- Gull Sight and the long flight
    ("tab",       "seg31.avi",  2.2,  5.0, 1.0, 0.0, 0.0),
    ("fl_ice",    "seg31.avi",  5.2, 13.0, 1.0, 0.0, 0.0),
    ("fl_pier",   "seg31.avi", 13.2, 16.8, 1.0, 0.0, 0.0),
    ("fl_wide",   "seg31.avi", 17.0, 22.0, 1.0, 0.0, 0.0),
    ("fl_blue",   "seg31.avi", 32.4, 36.0, 1.0, 0.0, 0.0),
    ("fl_rb",     "seg31.avi", 41.0, 49.5, 1.0, 0.0, 0.0),
    ("fl_speed",  "seg31.avi", 49.5, 53.0, 1.0, 0.0, 0.2),
    # ---- 3  how far it goes
    ("k_moon_a",  "seg12.avi",  2.4,  5.9, 1.0, 0.0, 0.0),
    ("k_moon_b",  "seg12.avi", 10.6, 12.8, 1.0, 0.0, 0.0),
    ("k_sun_a",   "seg12.avi", 27.6, 31.6, 1.3, 0.0, 0.0),
    ("k_sun_b",   "seg12.avi", 33.4, 36.2, 1.0, 0.0, 0.0),
    ("k_fry",     "seg12.avi", 47.4, 52.0, 1.0, 0.0, 0.2),
    ("fish",      "seg11.avi",  9.2, 15.0, 1.0, 0.2, 0.2),
    ("r_orbit",   "seg13.avi",  3.2, 11.6, 1.0, 0.25, 0.0),
    ("r_rumble",  "seg13.avi", 21.8, 26.0, 1.0, 0.0, 0.3),
    # ---- 4  the question comes back
    ("black",     "BLACK",     0.0,  3.4, 1.0, 0.0, 0.0),
    ("end",       "seg1.avi",  0.0,  1.2, 0.3, 0.4, 0.5),
]

VOICE_LINES = [
    ("title",     0.15, "Just Some Fries."),
    ("open",      1.2,  "A sleepy island. A cafe. One fry nobody notices... and one very hungry seagull."),
    ("ff1",       1.9,  "Dive. Lock on. When the world slows down, find the rhythm."),
    ("ff2",       0.2,  "Steal one. Then the next."),
    ("tab",       0.1,  "Hold Tab. The island shows you everything worth stealing."),
    ("fl_ice",    1.2,  "Dive. Grab. Don't stop."),
    ("fl_rb",     1.6,  "Coffee. A cocktail. Ice cream. All three... and nothing can catch you."),
    ("k_moon_a",  0.2,  "Then go higher. The moon. The sun."),
    ("fish",      0.6,  "Fish. Why not."),
    ("r_orbit",   0.8,  "Hat. Shades. Chain. The whole sky."),
    ("black",     0.6,  "You came here for some fries... right?"),
]

MUSIC_CUES = [
    ("title",     0.0, "title.ogg",    0.0, "to:ff1",     0.85, 0.5, 1.5),
    ("ff1",       0.0, "cine_joy.ogg", 0.0, 7.6,   0.95, 0.4, 0.5),
    ("ff2",      -0.2, "star.ogg",     0.0, "to:r_orbit", 0.85, 0.6, 1.4),
    ("r_orbit",   0.0, "cine_home.ogg",0.0, 12.0,  0.7, 1.0, 1.2),
    ("end",       0.0, "cine_sun.ogg", 0.0, 6.0,   0.95, 0.2, 1.4),
]

SFX_CUES = []
SFX_VOL = 0.85

CARD = [
    ("end", 0.9, 3.6, "Play it on Windows  -  github.com/KOUHOUKOU/JUST-SOME-FRIES", 30, "h-110", "white"),
]
