# Round 15 - the last content pass (2026-10-11)

Director's list of 13 points, all done. Tests: `--r15a` (board, TAB lesson, drinks, rainbow time, worn sky things), `--r15b` (the five sky catches + feedback), `--r15n` (stranger with a cup, puppy), `--r15g` (hero gull / big brother close-ups), `--r15u` (title screen, gallery, late big-brother talk), `--r8e` (the ending, gap check 3.1 m). Regression: `--r7` all PASS.

## 1  Gull Sight (TAB) is taught by doing
`main._tab_lesson_tick`, `hud.TabLesson`. From the moment the third fry opens Gull Sight, a big TAB keycap presses itself at the bottom of the screen with "HOLD TAB / GULL SIGHT: SEE EVERYTHING WORTH STEALING". When the key is held the line changes with the seconds of holding (THE WORLD SLOWS DOWN -> EVERYTHING THAT GLOWS IS A FRY TO STEAL -> THE NUMBER = THE SPEED YOU NEED), a ring closes, and after ~3.4 s the card says GOOD. TAB IS YOURS and leaves for good (saved: `GS.tab_lesson`, `GS.sight_time`). Ignored, the card shrinks but stays. Old saves with 10+ fries skip it.

## 2-3  Quest board, drinks, RAINBOW TIME
* Board: `RAINBOW TIME: ALL THREE DRINKS AT ONCE` is first; "all accessories" and "taste all three" are gone; five lines shown. The four old sky quests (cloud, star, sun, rainbow) are one: `SKY HIGH! CLOUD, STAR, MOON, SUN, RAINBOW  n / 5`.
* Colours: coffee = brown (heartbeat-jitter glow + brown steam), cocktail = gold (lazy sway glow + rising bubbles), ice cream = cool mint-blue (slow breathing glow + drifting frost crystals; no longer rainbow). STARLIGHT is now called RAINBOW TIME and is stronger: fatter rainbow wing ribbons, a coloured ring of light leaving the gull every 1.25 s, more sparkles, rainbow running down both screen edges.

## 4  Big brother
`big_bro._next_chat`: he gives the NEWEST talk the gull has earned (3 / 10 / 18 / 24 fries) and the older ones count as heard; after the whole sky is caught he has one more. New lines (short, dry, cool).

## 5-6  Body and clothes
`tools/blender/hero_gull.py`: head radius .26 -> .188 (a friendly, balanced head), longer slimmer hands (the soaring look), glide pose with straighter wings. `tools/blender/wardrobe.py`: hats / glasses / shades / pipe / bow tie / scarf / necklace re-tailored to the new head; shirts and coats are now SHELLS that follow the real body + chest (a few mm outside), with the neck hole cut where the head comes out, and every pattern is a function of (band along the body, sector around it): sailor stripes are rings, the flower shirt a lattice of flowers, the coat a plaid, the big brother's coat pinstripes. Backups of the previous models: `backup/pre_r15_models/`.

## 7  What the sky leaves on the gull (`world/aura_fx.gd`)
Sun: pale-gold holy light over the upper body, a slow halo, golden sparkles. Moon (new): pale-blue light under the body, moon dust. Rainbow: a bright translucent arch round the gull. Cloud: a thin cloud under the gull (only in the air); rain cloud (new) with a drizzle. All see-through and fading out near the lens.
New catchable things: the MOON (same judgement and speed as the sun, hangs over the western sea, pale by day and bright at night) and a RAIN CLOUD (225, same as the cloud). Catching both clouds = an achievement.

## 8  A warm town
* Nobody attacks a gull the crowd is not watching: grumpy swings, shouting kids and hostile dogs need `GS.watch >= 1.6`. Below that, kids run up with a heart and say hello, the grumpy ones wave, dogs run happy circles round the gull with hearts.
* More to meet while resting (first one after 3 s, then every ~9-14 s): another gull, a kid with a rainbow fry, a STRANGER WITH A CUP ("this might suit a gull." - a coffee / cocktail / ice cream is set in front of the gull and sipped), a PUPPY. The hostile dog only comes when the crowd is wary.
* Heat melts quicker: still on the ground and bothering nobody = x5, high and far = x9 and the target goes to zero.

## 9  Comic panels redrawn (Codex image generation, ~3 pictures sheets)
`game/assets/ui/comics/*.png` (384 px): the original 18 + gift, friend, puppy, calm, cloud, raincloud, star, moon, sun, rainbow. Prompts: `art_src/r15/prompt_sheets.txt`; cut by `tools/cut_art_sheets.py`.

## 10  Catching a thing of the sky: no camera games
The film moments for cloud / star / sun / rainbow are gone. Now: two rings of light leave the gull, a sparkle burst, a note that climbs with every new one, the little comic panel in the lower left, and a word + five pips at the top. The gull keeps flying and nothing slows down.

## 11  The ending
After the bite and the memories: the old man drops another fry, the little gull takes it up to the roof. Everything on ONE flat roof, side-on camera, both gulls on one line 3.1 m apart, nothing between the lens and their faces. Big brother: "...You brought it all the way up here. / The coat. The hat. The chain. I got everything. / ...and you're the one who looks full." The gull puts the fry down: "...it's just a fry. ...just some fries." Its finery falls away, he takes his shades off: "...same." He eats it: "...warm." - "...yeah." Both turn to the sea; "nothing shiny. nothing fast. / just a fry, and somebody to eat it with." Then the lettering and the credits as before.

## 12  Achievements + gallery
24 achievements (`GS.ACH`), each with a name, what-to-do, the game's opinion, an icon (Codex sheet, `game/assets/ui/achv/`) and the date it was obtained. They live in the player's profile (`user://achievements.json`), not in a run. Title screen: ACHIEVEMENTS (4th word); pause menu: ACHIEVEMENTS. Test runs never touch the real profile.

## Numbers
MOON_NEED 244 (= sun), RAINCLOUD_NEED 225 (= cloud). Watch thresholds: hostile >= 1.6, friendly < 1.6.
