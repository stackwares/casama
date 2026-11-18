# Brief: light/dark twins of the gallery wallpapers (round 6)

Every gallery theme has a light and a dark color scheme, but its painted wallpaper had only one version.
Each task here makes the missing twin of ONE existing painting: a night version of a light painting, or a
day version of a night painting.

Make exactly ONE image with your built-in image_gen tool (imagegen skill, built-in tool mode). Give it the
source painting named in your task as a reference image and ask for the SAME scene: same composition, same
objects in the same places, same soft painted style and paper grain. Only the time of day and light change.
Then copy the exact `savedPath` your image_gen call returned (never "the newest file" in a folder: many
tasks run at once) to the target path in your task, center-cropped to a square:
`sips --cropToHeightWidth N N f` with N = the smaller side (don't upscale). Check with
`sips -g pixelWidth -g pixelHeight f`.

Night version (the app's dark mode): deep, quiet and fairly dark overall, roughly the darkness of
visuals/round-2/raw/wall-starlit-lake.png. Muted deep blues, plums, inky greens, with a few soft warm or
cool glows (moonlight, lamps, stars) that fit the scene. Low contrast: chat bubbles with light text sit on
top, so no bright patches, no hard white highlights.

Day version (the app's light mode): bright, airy, soft pastel daylight or early morning, roughly the
brightness of visuals/round-1/raw/wall-tea-morning.png. Low contrast: chat bubbles with dark text sit on top,
so no deep shadows or dark patches.

HARD RULES: no text, letters, numbers or logos; no app UI, phones or screens; no people and no faces on
anything (animals already in the painting may stay); no photo-realism or neon. Even, calm, no strong focal
point in the middle. Don't edit, commit or deploy anything else; touch only your target file.

Reply with two lines: the image_gen savedPath, and the target path with its final size.
