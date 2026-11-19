# Brief for round 8: pictures inside the casama.ai showcase scenes (docs/SHOWCASE-PLAN.md)

Make exactly ONE image with your built-in image_gen tool (imagegen skill, built-in tool mode). Copy the exact
`savedPath` your image_gen call returned to the target path in your task, never "the newest file" in a
folder: several tasks run at once. Then size it as given. Don't edit, commit or deploy anything else, and
don't touch other files in visuals/round-8/raw/.

Sizing: never squash. Fit by the tighter side, then center-crop:
  W×H target: if src_w*H >= src_h*W: `sips --resampleHeight H f` else `sips --resampleWidth W f`; then `sips --cropToHeightWidth H W f`.
Verify with `sips -g pixelWidth -g pixelHeight f`.

These pictures appear small inside chat messages that bots send (a restaurant thumbnail, a page header, a
travel photo), so each needs one clear subject that still reads at thumbnail size.

HARD RULES: no text, letters, numbers, signs with writing, or logos; no app UI, phones or screens; no
people's faces up close (small distant figures are fine); no mascots or characters. Style: a soft, warm,
painterly illustration with gentle light and a little paper grain, like a travel or food magazine
illustration. Not photo-realistic, no neon, no AI clichés. Colors follow the subject, kept soft and
slightly muted, with a hint of lavender or blush in the light where it fits.

Reply with two lines: the image_gen savedPath, and the target path with its final size.
