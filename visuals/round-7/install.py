#!/usr/bin/env python3
"""Install round-7 header pictures: visuals/round-7/raw/<section>-<name>.png -> site/assets/pages/<section>/<name>.jpg + .webp, alt text into that folder's manifest.json."""
import json, os, subprocess, sys
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
P = json.load(open(os.path.join(ROOT, "visuals/round-7/prompts.json")))
ALTS = json.load(open(os.path.join(ROOT, "visuals/round-7/alts.json")))
for slug, prompt in P.items():
    section, name = slug.split("/")
    raw = os.path.join(ROOT, "visuals/round-7/raw", f"{section}-{name}.png")
    if not os.path.exists(raw):
        print("missing", raw); continue
    outdir = os.path.join(ROOT, "site/assets/pages", section); os.makedirs(outdir, exist_ok=True)
    tmp = os.path.join(outdir, f".{name}.png"); subprocess.run(["cp", raw, tmp], check=True)
    w, h = [int(x) for x in subprocess.run(["sips", "-g", "pixelWidth", "-g", "pixelHeight", tmp], capture_output=True, text=True).stdout.split()[-3::2]]
    if w * 630 >= h * 1200: subprocess.run(["sips", "--resampleHeight", "630", tmp], capture_output=True, check=True)
    else: subprocess.run(["sips", "--resampleWidth", "1200", tmp], capture_output=True, check=True)
    subprocess.run(["sips", "--cropToHeightWidth", "630", "1200", tmp], capture_output=True, check=True)
    jpg = os.path.join(outdir, f"{name}.jpg")
    subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "82", tmp, "--out", jpg], capture_output=True, check=True)
    subprocess.run(["cwebp", "-quiet", "-q", "78", tmp, "-o", os.path.join(outdir, f"{name}.webp")], check=True)
    os.remove(tmp)
    mpath = os.path.join(outdir, "manifest.json")
    m = json.load(open(mpath)) if os.path.exists(mpath) else {"note": "Header pictures for casama.ai written pages (round 7), made with codex/gpt-6-luna: no text, no app screens, no mascot. site/build.mjs shows <name>.jpg under the page title with this alt text.", "images": []}
    m["images"] = [i for i in m["images"] if i["slug"] != name] + [{"slug": name, "alt": ALTS[slug], "prompt": prompt}]
    json.dump(m, open(mpath, "w"), indent=2); open(mpath, "a").write("\n")
    print("ok", slug)
