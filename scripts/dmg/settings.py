# dmgbuild settings for Casama's Mac installer (D-379): the app on the left, Applications on the right,
# over a painted background with an arrow between them. scripts/package-macos.sh runs:
#   uvx --from dmgbuild==2.0.0 dmgbuild -s scripts/dmg/settings.py -D app=<Casama.app> \
#     -D background=scripts/dmg/background.tiff Casama <out.dmg>
# dmgbuild writes the Finder window layout itself, so no Finder or screen is needed.
# The background is visuals/render-dmg.sh's output (660x400 with a 2x copy, as one TIFF).
app = defines["app"]  # noqa: F821 (dmgbuild provides `defines`)

format = "UDZO"
files = [(app, "Casama.app")]
symlinks = {"Applications": "/Applications"}
hide_extensions = ["Casama.app"]

background = defines["background"]  # noqa: F821
window_rect = ((200, 140), (660, 400))
default_view = "icon-view"
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
show_icon_preview = False
include_icon_view_settings = True
arrange_by = None
icon_size = 128
text_size = 13
icon_locations = {"Casama.app": (165, 190), "Applications": (495, 190)}
