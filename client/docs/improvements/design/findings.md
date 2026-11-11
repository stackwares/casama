# Design findings

Review of the Casama Flutter app (`client/`), 2026-11-11. Every finding below was chosen for a plan; each plan is in `plans/`, named after the last part of its link.

**1. Show what's new after an update**

After an update, users open the app and nothing tells them what's new. The bug you fixed and the feature they asked for go unnoticed. Show them as a list on first open after an update, and the user who reported that bug or asked for that feature knows you listened.

Link: https://flutterpro.design/details/md/in-app-changelog

**2. Don't let the system navigation bar cover the bottom of scrollable lists**

The last item of scrollable lists gets obscured by the system navigation bar. Leave space as tall as that bar at the end of the list so the last item has a breathing room against the bar.

Link: https://flutterpro.design/details/md/safe-area-replacement

**3. Make horizontal lists feel scrollable**

A horizontal scrollable list might not always signal that it's scrollable. Especially when the visible content just fits the view and no item is cut in half. Fading the edge hints users that there's more and they can scroll it.

Link: https://flutterpro.design/details/md/shader-mask

**4. Match text selection to your app's colors**

`MaterialApp` applies default tinted colors for text selection in inputs. Match them to your brand colors instead.

Link: https://flutterpro.design/details/md/selection-color

**5. Load network images smoothly**

Images in Flutter load with no transition, no placeholder and no failure state. They just pop in. Make it calmer: Show a plain grey box until each picture is ready and fade it in. If fails show a subtle broken image icon, never a technical message.

Link: https://flutterpro.design/details/md/smooth-image-loading

**6. Preload images and icons so they don't pop in**

Flutter loads images and icons into memory when a widget first asks for them, and decoding takes time. So they are painted a few frames late. Precache them during splash view so they are ready when painted.

Link: https://flutterpro.design/details/md/precache-icons

**7. Never show "null" on screen**

When a string field comes back `null` or empty from the API and gets displayed directly, the user sees the word "null" or a blank spot on screen. A bad experience, and something they should never see. Instead, gate those values to show "-" or "N/A".

Link: https://flutterpro.design/details/md/never-show-null

**8. Preload Google Fonts so text doesn't swap fonts**

The google_fonts package downloads fonts on first use, so on a fresh install users see text in the default font for a split second before it swaps to yours. Not a good first impression. Preload the fonts during splash and text shows in the right typography from frame one.

Link: https://flutterpro.design/details/md/google-fonts-glitch

**9. Format numbers for user's locale**

A raw `1234567` is hard to read. Users expect numbers the way their region writes them: `1,234,567` in the US, `1.234.567` in Germany. Every count, price and big number should be displayed that way.

Link: https://flutterpro.design/details/md/format-numbers-for-humans

**10. Add haptic feedback to key moments**

The app feels flat when taps and results happen in silence. A subtle haptic vibration on a tab switch, a successful submit or an error makes the app feel responsive in the hand.

Link: https://flutterpro.design/details/md/haptic-feedback

**11. Use tabular figures for changing numbers**

Digits have different widths in most fonts, so a timer or counter jumps around as it changes. Tabular figures make every digit the same width: numbers stay still and line up.

Link: https://flutterpro.design/details/md/tabular-figures

**12. Give Flutter web links a preview card**

Shared in WhatsApp, Slack or X, the app's link shows as a bare URL. It should show a proper preview card with a title, description and image.

Link: https://flutterpro.design/details/md/flutter-web-og-image

**13. Dismiss the keyboard when the user scrolls**

The user finishes typing and scrolls to see the rest, but the keyboard stays covering half the screen. Scrolling means they're done with the field, so close it for them.

Link: https://flutterpro.design/details/md/dismiss-keyboard-on-scroll

**14. Scroll to top when the current bottom nav item is tapped again**

Tapping the bottom nav bar item you're already on should scroll that page to the top. It's muscle memory for native app users, so they'll expect it from your apps too.

Link: https://flutterpro.design/details/md/bottom-nav-reselect

**15. Show the app version in settings**

When a user reports a bug, the first question is which version they're on, and the app has no place to answer it.

Link: https://flutterpro.design/details/md/show-app-version

**16. Don't use mobile page transitions on web and desktop**

Web and desktop are click and open. Mobile slide and zoom transitions between pages look cheap there, so pages should switch with no transition.

Link: https://flutterpro.design/details/md/web-page-transitions

**17. Scroll the tapped tab fully into view**

In a tab bar, when the user taps a tab that's only half visible, it should scroll fully into view.

Link: https://flutterpro.design/details/md/tab-visibility

**18. Show scrollbars on vertical scrollables**

A scrollbar shows the user where they are in the list and how much is left.

Link: https://flutterpro.design/details/md/scrollbars

**19. Format dates for user's locale**

`2016-06-24 14:44:00.000` is what `DateTime` prints, and no user should read a date like that. Show `24 July 2016, 14:44` instead, in the user's language.

Link: https://flutterpro.design/details/md/format-date-times

**20. Keep statusbar tap scrolling to top on iOS**

Tapping the statusbar scrolls the page to the top; it's native to iOS and users expect it. It works out of the box, but a custom `ScrollController` silently breaks it.

Link: https://flutterpro.design/details/md/statusbar-tap-scroll

**21. Limit text scaling so layouts don't break**

Some users increase their device's text size for accessibility, and at high scales layouts overflow and break. After the fix, run the app at the capped scale yourself to confirm nothing breaks.

Link: https://flutterpro.design/details/md/text-scale-factor

**22. Fade scrolling content under the status bar**

On pages with no app bar, scrolling content runs behind the status bar and collides with the clock and battery. A progressive fade at the top dissolves it as it slides under.

Link: https://flutterpro.design/details/md/progressive-fade

**23. Let horizontal lists reach the screen edges**

When the page's scrollable has horizontal padding, horizontal lists inside get clipped at the edges instead of sliding past them. The list should reach the edges and carry its own padding.

Link: https://flutterpro.design/details/md/horizontal-list-padding

**24. Update the browser tab title per page**

The tab title shows in the browser tab, history and bookmarks, and when it's the same on every page, a user with several tabs open can't tell them apart. Each page should say what it is.

Link: https://flutterpro.design/details/md/browser-tab-title

**25. Unfocus the text field before opening a modal**

Opening a modal while a text field is focused brings the keyboard back when the modal closes, even though the user was done typing. Unfocus before opening and it stays away.

Link: https://flutterpro.design/details/md/unfocus-before-modal

**26. Show a friendly view when a widget breaks**

When a widget fails to build, users see an empty grey box in release. Show a friendly "Something went wrong" in the app's own colors instead.

Link: https://flutterpro.design/details/md/friendly-error-view

**27. Format phone numbers**

A phone number shown or typed as one long run of digits is hard to read and easy to mistype. It should be formatted everywhere the user sees one, including while they type to a text field.

Link: https://flutterpro.design/details/md/format-phone-numbers

**28. Give every text field the right keyboard action**

Users should be able to fill a form and submit it with the keyboard's action key alone: it moves them to the next field, and on the last one, submits. No tapping each field by hand.

Link: https://flutterpro.design/details/md/text-input-action

**29. Make bottom sheets smooth and draggable**

Material's `showModalBottomSheet` opens and closes with a mechanical, soulless motion. Bottom sheets should respond to drags smoothly.

Link: https://flutterpro.design/details/md/smooth-draggable-bottom-sheets

**30. Give full-screen modals the modern sheet look**

Full-screen modals that open from the bottom either use the iOS 13 sheet style, which looks dated now, or just slide up mechanically. Make them modern and smooth, closing with a pull down from the top.

Link: https://flutterpro.design/details/md/adaptive-sheet-route

**31. Report real screen names to analytics**

Analytics sees a Flutter app as one native view, so every page gets reported as `FlutterViewController`. You can't tell which screens users spend time.

Link: https://flutterpro.design/details/md/analytics-screen-names
