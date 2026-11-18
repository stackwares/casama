**1. Make horizontal lists feel scrollable**

A horizontal scrollable list might not always signal that it's scrollable. Especially when the visible content just fits the view and no item is cut in half. Fading the edge hints users that there's more and they can scroll it.

Link: https://flutterpro.design/details/md/shader-mask

**2. Load network images smoothly**

Images in Flutter load with no transition, no placeholder and no failure state. They just pop in. Make it calmer: Show a plain grey box until each picture is ready and fade it in. If fails show a subtle broken image icon, never a technical message.

Link: https://flutterpro.design/details/md/smooth-image-loading

**3. Scroll the tapped tab fully into view**

In a tab bar, when the user taps a tab that's only half visible, it should scroll fully into view.

Link: https://flutterpro.design/details/md/tab-visibility

**4. Keep statusbar tap scrolling to top on iOS**

Tapping the statusbar scrolls the page to the top; it's native to iOS and users expect it. It works out of the box, but a custom `ScrollController` silently breaks it.

Link: https://flutterpro.design/details/md/statusbar-tap-scroll
