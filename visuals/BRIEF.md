# Brief for every generated image (round 1)

Make exactly ONE image with your built-in image_gen tool (imagegen skill, built-in tool mode), then copy it
to the target path given in your task, sized as below. Copy the exact `savedPath` your image_gen call returned,
never "the newest file" in a folder: many tasks run at once and other sessions write there too. Don't edit,
commit or deploy anything else. Don't touch other files in visuals/round-1/raw/.

Sizing: never squash. Fit by the tighter side, then center-crop:
  W×H target: if src_w*H >= src_h*W: `sips --resampleHeight H f` else `sips --resampleWidth W f`; then `sips --cropToHeightWidth H W f`.
  Square wallpapers: `sips --cropToHeightWidth N N f` with N = the smaller side (don't upscale).
Verify with `sips -g pixelWidth -g pixelHeight f`.

HARD RULES: no text, letters, numbers or logos; no app UI, phones or laptop screens; no characters and no
clouds with faces (our real mascot SVG goes on top later); no photo-realism, neon, circuit boards or AI-brain
clichés. Style: soft, rounded, calm, slightly dreamy illustration. Palette: Casama purple (#6b4fd8 family),
deep plum #24112f, lavender, soft cyan glow, warm blush/peach accents.
Family references: visuals/round-1/raw/og-bg-home-v1.png (share cards), visuals/round-1/raw/wall-cloud-sea.png (wallpapers).

Chat wallpapers (square): shown behind message bubbles, so low contrast and even, no strong focal point in the
middle, soft painted look with gentle paper grain like wall-cloud-sea.png. The palette may follow the scene
(greens for a garden, sand for a dune) as long as it stays soft and pastel or muted; not everything must be purple.

Share cards (1200×630): keep the LEFT 55% calm and fairly dark (white text goes there); leave an open spot right of center (x≈750–1050) for the mascot.

Reply with two lines: the image_gen savedPath, and the target path with its final size.
