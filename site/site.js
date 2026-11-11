(function () {
  "use strict";

  var root = document.documentElement;
  var storageKey = "casama-site-theme";

  // ---------------------------------------------------------------------------
  // 1. Wallpaper Doodle Patterns & Palettes (from client/lib/theme/wallpaper.dart & gallery.js)
  // ---------------------------------------------------------------------------
  var PATTERNS = {
    clouds: ["cloud", "cloud-sun", "star", "sparkle", "cloud-moon", "moon", "sparkles", "orbit", "rainbow"],
    doodles: ["message-circle", "heart", "star", "smile", "coffee", "music", "rocket", "gift", "sun", "cat", "bot", "pencil", "camera", "umbrella", "headphones", "gamepad-2"],
    treats: ["ice-cream-cone", "cake", "candy", "popsicle", "cookie", "donut", "lollipop", "croissant", "cherry", "citrus", "coffee", "heart"],
    garden: ["leaf", "flower", "flower-2", "sprout", "sun", "cherry", "trees", "bug", "clover", "snail", "feather"],
    space: ["rocket", "orbit", "moon", "star", "sparkles", "satellite", "telescope", "earth", "sparkle", "ghost"],
    pets: ["cat", "dog", "paw-print", "bone", "fish", "heart", "bird", "rabbit", "turtle", "squirrel"],
    sea: ["shell", "waves", "sailboat", "anchor", "fish", "tree-palm", "sun", "umbrella", "cloud"],
    tech: ["bot", "monitor", "laptop", "terminal", "cpu", "code", "cloud", "zap", "wifi", "mouse-pointer-2", "keyboard", "server"]
  };

  var ICONS = {
    "anchor": [["path",{"d":"M12 6v16"}],["path",{"d":"m19 13 2-1a9 9 0 0 1-18 0l2 1"}],["path",{"d":"M9 11h6"}],["circle",{"cx":"12","cy":"4","r":"2"}]],
    "bird": [["path",{"d":"M16 7h.01"}],["path",{"d":"M3.4 18H12a8 8 0 0 0 8-8V7a4 4 0 0 0-7.28-2.3L2 20"}],["path",{"d":"m20 7 2 .5-2 .5"}],["path",{"d":"M10 18v3"}],["path",{"d":"M14 17.75V21"}],["path",{"d":"M7 18a6 6 0 0 0 3.84-10.61"}]],
    "bone": [["path",{"d":"M17 10c.7-.7 1.69 0 2.5 0a2.5 2.5 0 1 0 0-5 .5.5 0 0 1-.5-.5 2.5 2.5 0 1 0-5 0c0 .81.7 1.8 0 2.5l-7 7c-.7.7-1.69 0-2.5 0a2.5 2.5 0 0 0 0 5c.28 0 .5.22.5.5a2.5 2.5 0 1 0 5 0c0-.81-.7-1.8 0-2.5Z"}]],
    "bot": [["path",{"d":"M12 8V4H8"}],["rect",{"width":"16","height":"12","x":"4","y":"8","rx":"2"}],["path",{"d":"M2 14h2"}],["path",{"d":"M20 14h2"}],["path",{"d":"M15 13v2"}],["path",{"d":"M9 13v2"}]],
    "bug": [["path",{"d":"M12 20v-9"}],["path",{"d":"M14 7a4 4 0 0 1 4 4v3a6 6 0 0 1-12 0v-3a4 4 0 0 1 4-4z"}],["path",{"d":"M14.12 3.88 16 2"}],["path",{"d":"M21 21a4 4 0 0 0-3.81-4"}],["path",{"d":"M21 5a4 4 0 0 1-3.55 3.97"}],["path",{"d":"M22 13h-4"}],["path",{"d":"M3 21a4 4 0 0 1 3.81-4"}],["path",{"d":"M3 5a4 4 0 0 0 3.55 3.97"}],["path",{"d":"M6 13H2"}],["path",{"d":"m8 2 1.88 1.88"}],["path",{"d":"M9 7.13V6a3 3 0 1 1 6 0v1.13"}]],
    "cake": [["path",{"d":"M20 21v-8a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8"}],["path",{"d":"M4 16s.5-1 2-1 2.5 2 4 2 2.5-2 4-2 2.5 2 4 2 2-1 2-1"}],["path",{"d":"M2 21h20"}],["path",{"d":"M7 8v3"}],["path",{"d":"M12 8v3"}],["path",{"d":"M17 8v3"}],["path",{"d":"M7 4h.01"}],["path",{"d":"M12 4h.01"}],["path",{"d":"M17 4h.01"}]],
    "camera": [["path",{"d":"M13.997 4a2 2 0 0 1 1.76 1.05l.486.9A2 2 0 0 0 18.003 7H20a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2h1.997a2 2 0 0 0 1.759-1.048l.489-.904A2 2 0 0 1 10.004 4z"}],["circle",{"cx":"12","cy":"13","r":"3"}]],
    "candy": [["path",{"d":"M10 7v10.9"}],["path",{"d":"M14 6.1V17"}],["path",{"d":"M16 7V3a1 1 0 0 1 1.707-.707 2.5 2.5 0 0 0 2.152.717 1 1 0 0 1 1.131 1.131 2.5 2.5 0 0 0 .717 2.152A1 1 0 0 1 21 8h-4"}],["path",{"d":"M16.536 7.465a5 5 0 0 0-7.072 0l-2 2a5 5 0 0 0 0 7.07 5 5 0 0 0 7.072 0l2-2a5 5 0 0 0 0-7.07"}],["path",{"d":"M8 17v4a1 1 0 0 1-1.707.707 2.5 2.5 0 0 0-2.152-.717 1 1 0 0 1-1.131-1.131 2.5 2.5 0 0 0-.717-2.152A1 1 0 0 1 3 16h4"}]],
    "cat": [["path",{"d":"M12 5c.67 0 1.35.09 2 .26 1.78-2 5.03-2.84 6.42-2.26 1.4.58-.42 7-.42 7 .57 1.07 1 2.24 1 3.44C21 17.9 16.97 21 12 21s-9-3-9-7.56c0-1.25.5-2.4 1-3.44 0 0-1.89-6.42-.5-7 1.39-.58 4.72.23 6.5 2.23A9.04 9.04 0 0 1 12 5Z"}],["path",{"d":"M8 14v.5"}],["path",{"d":"M16 14v.5"}],["path",{"d":"M11.25 16.25h1.5L12 17l-.75-.75Z"}]],
    "cherry": [["path",{"d":"M2 17a5 5 0 0 0 10 0c0-2.76-2.5-5-5-3-2.5-2-5 .24-5 3Z"}],["path",{"d":"M12 17a5 5 0 0 0 10 0c0-2.76-2.5-5-5-3-2.5-2-5 .24-5 3Z"}],["path",{"d":"M7 14c3.22-2.91 4.29-8.75 5-12 1.66 2.38 4.94 9 5 12"}],["path",{"d":"M22 9c-4.29 0-7.14-2.33-10-7 5.71 0 10 4.67 10 7Z"}]],
    "citrus": [["path",{"d":"M21.66 17.67a1.08 1.08 0 0 1-.04 1.6A12 12 0 0 1 4.73 2.38a1.1 1.1 0 0 1 1.61-.04z"}],["path",{"d":"M19.65 15.66A8 8 0 0 1 8.35 4.34"}],["path",{"d":"m14 10-5.5 5.5"}],["path",{"d":"M14 17.85V10H6.15"}]],
    "cloud": [["path",{"d":"M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z"}]],
    "cloud-moon": [["path",{"d":"M13 16a3 3 0 0 1 0 6H7a5 5 0 1 1 4.9-6z"}],["path",{"d":"M18.376 14.512a6 6 0 0 0 3.461-4.127c.148-.625-.659-.97-1.248-.714a4 4 0 0 1-5.259-5.26c.255-.589-.09-1.395-.716-1.248a6 6 0 0 0-4.594 5.36"}]],
    "cloud-sun": [["path",{"d":"M12 2v2"}],["path",{"d":"m4.93 4.93 1.41 1.41"}],["path",{"d":"M20 12h2"}],["path",{"d":"m19.07 4.93-1.41 1.41"}],["path",{"d":"M15.947 12.65a4 4 0 0 0-5.925-4.128"}],["path",{"d":"M13 22H7a5 5 0 1 1 4.9-6H13a3 3 0 0 1 0 6Z"}]],
    "clover": [["path",{"d":"M16.17 7.83 2 22"}],["path",{"d":"M4.02 12a2.827 2.827 0 1 1 3.81-4.17A2.827 2.827 0 1 1 12 4.02a2.827 2.827 0 1 1 4.17 3.81A2.827 2.827 0 1 1 19.98 12a2.827 2.827 0 1 1-3.81 4.17A2.827 2.827 0 1 1 12 19.98a2.827 2.827 0 1 1-4.17-3.81A1 1 0 1 1 4 12"}],["path",{"d":"m7.83 7.83 8.34 8.34"}]],
    "code": [["path",{"d":"m16 18 6-6-6-6"}],["path",{"d":"m8 6-6 6 6 6"}]],
    "coffee": [["path",{"d":"M10 2v2"}],["path",{"d":"M14 2v2"}],["path",{"d":"M16 8a1 1 0 0 1 1 1v8a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4V9a1 1 0 0 1 1-1h14a4 4 0 1 1 0 8h-1"}],["path",{"d":"M6 2v2"}]],
    "cookie": [["path",{"d":"M11 17h.01"}],["path",{"d":"M11.496 2c.324-.016.558.292.529.615a4 4 0 004.235 4.368.713.713 0 01.758.757 4 4 0 004.366 4.237c.323-.03.63.204.614.527a10 10 0 01-2.915 6.566A1 1 0 114.93 4.918 10 10 0 0111.496 2"}],["path",{"d":"M12 12h.01"}],["path",{"d":"M16 16h.01"}],["path",{"d":"M7 14h.01"}],["path",{"d":"M9 8h.01"}]],
    "cpu": [["path",{"d":"M12 20v2"}],["path",{"d":"M12 2v2"}],["path",{"d":"M17 20v2"}],["path",{"d":"M17 2v2"}],["path",{"d":"M2 12h2"}],["path",{"d":"M2 17h2"}],["path",{"d":"M2 7h2"}],["path",{"d":"M20 12h2"}],["path",{"d":"M20 17h2"}],["path",{"d":"M20 7h2"}],["path",{"d":"M7 20v2"}],["path",{"d":"M7 2v2"}],["rect",{"x":"4","y":"4","width":"16","height":"16","rx":"2"}],["rect",{"x":"8","y":"8","width":"8","height":"8","rx":"1"}]],
    "croissant": [["path",{"d":"M10.2 18H4.774a1.5 1.5 0 0 1-1.352-.97 11 11 0 0 1 .132-6.487"}],["path",{"d":"M18 10.2V4.774a1.5 1.5 0 0 0-.97-1.352 11 11 0 0 0-6.486.132"}],["path",{"d":"M18 5a4 3 0 0 1 4 3 2 2 0 0 1-2 2 10 10 0 0 0-5.139 1.42"}],["path",{"d":"M5 18a3 4 0 0 0 3 4 2 2 0 0 0 2-2 10 10 0 0 1 1.42-5.14"}],["path",{"d":"M8.709 2.554a10 10 0 0 0-6.155 6.155 1.5 1.5 0 0 0 .676 1.626l9.807 5.42a2 2 0 0 0 2.718-2.718l-5.42-9.807a1.5 1.5 0 0 0-1.626-.676"}]],
    "dog": [["path",{"d":"M11.25 16.25h1.5L12 17z"}],["path",{"d":"M16 14v.5"}],["path",{"d":"M4.42 11.247A13.152 13.152 0 0 0 4 14.556C4 18.728 7.582 21 12 21s8-2.272 8-6.444a11.702 11.702 0 0 0-.493-3.309"}],["path",{"d":"M8 14v.5"}],["path",{"d":"M8.5 8.5c-.384 1.05-1.083 2.028-2.344 2.5-1.931.722-3.576-.297-3.656-1-.113-.994 1.177-6.53 4-7 1.923-.321 3.651.845 3.651 2.235A7.497 7.497 0 0 1 14 5.277c0-1.39 1.844-2.598 3.767-2.277 2.823.47 4.113 6.006 4 7-.08.703-1.725 1.722-3.656 1-1.261-.472-1.855-1.45-2.239-2.5"}]],
    "donut": [["path",{"d":"M20.5 10a2.5 2.5 0 0 1-2.4-3H18a2.95 2.95 0 0 1-2.6-4.4 10 10 0 1 0 6.3 7.1c-.3.2-.8.3-1.2.3"}],["circle",{"cx":"12","cy":"12","r":"3"}]],
    "earth": [["path",{"d":"M21.54 15H17a2 2 0 0 0-2 2v4.54"}],["path",{"d":"M7 3.34V5a3 3 0 0 0 3 3a2 2 0 0 1 2 2c0 1.1.9 2 2 2a2 2 0 0 0 2-2c0-1.1.9-2 2-2h3.17"}],["path",{"d":"M11 21.95V18a2 2 0 0 0-2-2a2 2 0 0 1-2-2v-1a2 2 0 0 0-2-2H2.05"}],["circle",{"cx":"12","cy":"12","r":"10"}]],
    "feather": [["path",{"d":"M14.086 18.412A2 2 0 0112.67 19H5v-7.672a2 2 0 01.586-1.414L11.75 3.75a6 6 0 118.49 8.49z"}],["path",{"d":"M16 8 2 22"}],["path",{"d":"M17.488 15H9"}]],
    "fish": [["path",{"d":"M6.5 12c.94-3.46 4.94-6 8.5-6 3.56 0 6.06 2.54 7 6-.94 3.47-3.44 6-7 6s-7.56-2.53-8.5-6Z"}],["path",{"d":"M18 12v.5"}],["path",{"d":"M16 17.93a9.77 9.77 0 0 1 0-11.86"}],["path",{"d":"M7 10.67C7 8 5.58 5.97 2.73 5.5c-1 1.5-1 5 .23 6.5-1.24 1.5-1.24 5-.23 6.5C5.58 18.03 7 16 7 13.33"}]],
    "flower": [["circle",{"cx":"12","cy":"12","r":"3"}],["path",{"d":"M12 16.5A4.5 4.5 0 1 1 7.5 12 4.5 4.5 0 1 1 12 7.5a4.5 4.5 0 1 1 4.5 4.5 4.5 4.5 0 1 1-4.5 4.5"}]],
    "flower-2": [["path",{"d":"M12 5a3 3 0 1 1 3 3m-3-3a3 3 0 1 0-3 3m3-3v1M9 8a3 3 0 1 0 3 3M9 8h1m5 0a3 3 0 1 1-3 3m3-3h-1m-2 3v-1"}],["circle",{"cx":"12","cy":"8","r":"2"}],["path",{"d":"M12 10v12"}],["path",{"d":"M12 22c4.2 0 7-1.667 7-5-4.2 0-7 1.667-7 5Z"}],["path",{"d":"M12 22c-4.2 0-7-1.667-7-5 4.2 0 7 1.667 7 5Z"}]],
    "gamepad-2": [["line",{"x1":"6","x2":"10","y1":"11","y2":"11"}],["line",{"x1":"8","x2":"8","y1":"9","y2":"13"}],["line",{"x1":"15","x2":"15.01","y1":"12","y2":"12"}],["line",{"x1":"18","x2":"18.01","y1":"10","y2":"10"}],["path",{"d":"M17.32 5H6.68a4 4 0 0 0-3.978 3.59c-.006.052-.01.101-.017.152C2.604 9.416 2 14.456 2 16a3 3 0 0 0 3 3c1 0 1.5-.5 2-1l1.414-1.414A2 2 0 0 1 9.828 16h4.344a2 2 0 0 1 1.414.586L17 18c.5.5 1 1 2 1a3 3 0 0 0 3-3c0-1.545-.604-6.584-.685-7.258-.007-.05-.011-.1-.017-.151A4 4 0 0 0 17.32 5z"}]],
    "ghost": [["path",{"d":"M15 10v1"}],["path",{"d":"M7.528 20.472a1.6 1.6 0 012.277 0l1.057 1.056a1.6 1.6 0 002.276 0l1.057-1.056a1.6 1.6 0 012.277 0l1.114 1.114a1.4 1.4 0 002.414-1V10a8 8 0 00-16 0v10.586a1.4 1.4 0 002.414 1z"}],["path",{"d":"M9 10v1"}]],
    "gift": [["path",{"d":"M12 7v14"}],["path",{"d":"M20 11v8a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2v-8"}],["path",{"d":"M7.5 7a1 1 0 0 1 0-5A4.8 8 0 0 1 12 7a4.8 8 0 0 1 4.5-5 1 1 0 0 1 0 5"}],["rect",{"x":"3","y":"7","width":"18","height":"4","rx":"1"}]],
    "headphones": [["path",{"d":"M3 14h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-7a9 9 0 0 1 18 0v7a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3"}]],
    "heart": [["path",{"d":"M2 9.5a5.5 5.5 0 0 1 9.591-3.676.56.56 0 0 0 .818 0A5.49 5.49 0 0 1 22 9.5c0 2.29-1.5 4-3 5.5l-5.492 5.313a2 2 0 0 1-3 .019L5 15c-1.5-1.5-3-3.2-3-5.5"}]],
    "ice-cream-cone": [["path",{"d":"m7 11 4.08 10.35a1 1 0 0 0 1.84 0L17 11"}],["path",{"d":"M17 7A5 5 0 0 0 7 7"}],["path",{"d":"M17 7a2 2 0 0 1 0 4H7a2 2 0 0 1 0-4"}]],
    "keyboard": [["path",{"d":"M10 8h.01"}],["path",{"d":"M12 12h.01"}],["path",{"d":"M14 8h.01"}],["path",{"d":"M16 12h.01"}],["path",{"d":"M18 8h.01"}],["path",{"d":"M6 8h.01"}],["path",{"d":"M7 16h10"}],["path",{"d":"M8 12h.01"}],["rect",{"width":"20","height":"16","x":"2","y":"4","rx":"2"}]],
    "laptop": [["path",{"d":"M18 5a2 2 0 0 1 2 2v8.526a2 2 0 0 0 .212.897l1.068 2.127a1 1 0 0 1-.9 1.45H3.62a1 1 0 0 1-.9-1.45l1.068-2.127A2 2 0 0 0 4 15.526V7a2 2 0 0 1 2-2z"}],["path",{"d":"M20.054 15.987H3.946"}]],
    "leaf": [["path",{"d":"M11 20a10 10 0 0010-10 25.9 25.9 0 00-1.04-7.281 1 1 0 00-1.755-.325C15.833 5.5 13 5.5 9.8 6.1A7 7 0 0011 20"}],["path",{"d":"M2 21a5 5 0 012.911-4.544C7.613 15.212 8.351 15.24 11 13"}]],
    "lollipop": [["circle",{"cx":"11","cy":"11","r":"8"}],["path",{"d":"m21 21-4.3-4.3"}],["path",{"d":"M11 11a2 2 0 0 0 4 0 4 4 0 0 0-8 0 6 6 0 0 0 12 0"}]],
    "message-circle": [["path",{"d":"M2.992 16.342a2 2 0 0 1 .094 1.167l-1.065 3.29a1 1 0 0 0 1.236 1.168l3.413-.998a2 2 0 0 1 1.099.092 10 10 0 1 0-4.777-4.719"}]],
    "monitor": [["rect",{"width":"20","height":"14","x":"2","y":"3","rx":"2"}],["line",{"x1":"8","x2":"16","y1":"21","y2":"21"}],["line",{"x1":"12","x2":"12","y1":"17","y2":"21"}]],
    "moon": [["path",{"d":"M20.985 12.486a9 9 0 1 1-9.473-9.472c.405-.022.617.46.402.803a6 6 0 0 0 8.268 8.268c.344-.215.825-.004.803.401"}]],
    "mouse-pointer-2": [["path",{"d":"M4.037 4.688a.495.495 0 0 1 .651-.651l16 6.5a.5.5 0 0 1-.063.947l-6.124 1.58a2 2 0 0 0-1.438 1.435l-1.579 6.126a.5.5 0 0 1-.947.063z"}]],
    "music": [["path",{"d":"M21 16V3a1 1 0 0 0-1.28-.96l-10 2.917a1 1 0 0 0-.72.96V19"}],["circle",{"cx":"18","cy":"16","r":"3"}],["circle",{"cx":"6","cy":"19","r":"3"}]],
    "orbit": [["path",{"d":"M20.341 6.484A10 10 0 0 1 10.266 21.85"}],["path",{"d":"M3.659 17.516A10 10 0 0 1 13.74 2.152"}],["circle",{"cx":"12","cy":"12","r":"3"}],["circle",{"cx":"19","cy":"5","r":"2"}],["circle",{"cx":"5","cy":"19","r":"2"}]],
    "paw-print": [["circle",{"cx":"11","cy":"4","r":"2"}],["circle",{"cx":"18","cy":"8","r":"2"}],["circle",{"cx":"20","cy":"16","r":"2"}],["path",{"d":"M9 10a5 5 0 0 1 5 5v3.5a3.5 3.5 0 0 1-6.84 1.045Q6.52 17.48 4.46 16.84A3.5 3.5 0 0 1 5.5 10Z"}]],
    "pencil": [["path",{"d":"M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z"}],["path",{"d":"m15 5 4 4"}]],
    "popsicle": [["path",{"d":"M18.6 14.4c.8-.8.8-2 0-2.8l-8.1-8.1a4.95 4.95 0 1 0-7.1 7.1l8.1 8.1c.9.7 2.1.7 2.9-.1Z"}],["path",{"d":"m22 22-5.5-5.5"}]],
    "rabbit": [["path",{"d":"M13 16a3 3 0 0 1 2.24 5"}],["path",{"d":"M18 12h.01"}],["path",{"d":"M18 21h-8a4 4 0 0 1-4-4 7 7 0 0 1 7-7h.2L9.6 6.4a1 1 0 1 1 2.8-2.8L15.8 7h.2c3.3 0 6 2.7 6 6v1a2 2 0 0 1-2 2h-1a3 3 0 0 0-3 3"}],["path",{"d":"M20 8.54V4a2 2 0 1 0-4 0v3"}],["path",{"d":"M7.612 12.524a3 3 0 1 0-1.6 4.3"}]],
    "rainbow": [["path",{"d":"M22 17a10 10 0 0 0-20 0"}],["path",{"d":"M6 17a6 6 0 0 1 12 0"}],["path",{"d":"M10 17a2 2 0 0 1 4 0"}]],
    "rocket": [["path",{"d":"M12 15v5s3.03-.55 4-2c1.08-1.62 0-5 0-5"}],["path",{"d":"M4.5 16.5c-1.5 1.26-2 5-2 5s3.74-.5 5-2c.71-.84.7-2.13-.09-2.91a2.18 2.18 0 0 0-2.91-.09"}],["path",{"d":"M9 12a22 22 0 0 1 2-3.95A12.88 12.88 0 0 1 22 2c0 2.72-.78 7.5-6 11a22.4 22.4 0 0 1-4 2z"}],["path",{"d":"M9 12H4s.55-3.03 2-4c1.62-1.08 5 .05 5 .05"}]],
    "sailboat": [["path",{"d":"M10 2v15"}],["path",{"d":"M7 22a4 4 0 0 1-4-4 1 1 0 0 1 1-1h16a1 1 0 0 1 1 1 4 4 0 0 1-4 4z"}],["path",{"d":"M9.159 2.46a1 1 0 0 1 1.521-.193l9.977 8.98A1 1 0 0 1 20 13H4a1 1 0 0 1-.824-1.567z"}]],
    "satellite": [["path",{"d":"m13.5 6.5-3.148-3.148a1.205 1.205 0 0 0-1.704 0L6.352 5.648a1.205 1.205 0 0 0 0 1.704L9.5 10.5"}],["path",{"d":"M16.5 7.5 19 5"}],["path",{"d":"m17.5 10.5 3.148 3.148a1.205 1.205 0 0 1 0 1.704l-2.296 2.296a1.205 1.205 0 0 1-1.704 0L13.5 14.5"}],["path",{"d":"M9 21a6 6 0 0 0-6-6"}],["path",{"d":"M9.352 10.648a1.205 1.205 0 0 0 0 1.704l2.296 2.296a1.205 1.205 0 0 0 1.704 0l4.296-4.296a1.205 1.205 0 0 0 0-1.704l-2.296-2.296a1.205 1.205 0 0 0-1.704 0z"}]],
    "server": [["rect",{"width":"20","height":"8","x":"2","y":"2","rx":"2","ry":"2"}],["rect",{"width":"20","height":"8","x":"2","y":"14","rx":"2","ry":"2"}],["line",{"x1":"6","x2":"6.01","y1":"6","y2":"6"}],["line",{"x1":"6","x2":"6.01","y1":"18","y2":"18"}]],
    "shell": [["path",{"d":"M14 11a2 2 0 1 1-4 0 4 4 0 0 1 8 0 6 6 0 0 1-12 0 8 8 0 0 1 16 0 10 10 0 1 1-20 0 11.93 11.93 0 0 1 2.42-7.22 2 2 0 1 1 3.16 2.44"}]],
    "smile": [["path",{"d":"M15 10V9"}],["path",{"d":"M16.472 15a6 6 0 01-8.943 0"}],["path",{"d":"M9 10V9"}],["circle",{"cx":"12","cy":"12","r":"10"}]],
    "snail": [["path",{"d":"M2 13a6 6 0 1 0 12 0 4 4 0 1 0-8 0 2 2 0 0 0 4 0"}],["circle",{"cx":"10","cy":"13","r":"8"}],["path",{"d":"M2 21h12c4.4 0 8-3.6 8-8V7a2 2 0 1 0-4 0v6"}],["path",{"d":"M18 3 19.1 5.2"}],["path",{"d":"M22 3 20.9 5.2"}]],
    "sparkle": [["path",{"d":"M11.017 2.814a1 1 0 0 1 1.966 0l1.051 5.558a2 2 0 0 0 1.594 1.594l5.558 1.051a1 1 0 0 1 0 1.966l-5.558 1.051a2 2 0 0 0-1.594 1.594l-1.051 5.558a1 1 0 0 1-1.966 0l-1.051-5.558a2 2 0 0 0-1.594-1.594l-5.558-1.051a1 1 0 0 1 0-1.966l5.558-1.051a2 2 0 0 0 1.594-1.594z"}]],
    "sparkles": [["path",{"d":"M11.017 2.814a1 1 0 0 1 1.966 0l1.051 5.558a2 2 0 0 0 1.594 1.594l5.558 1.051a1 1 0 0 1 0 1.966l-5.558 1.051a2 2 0 0 0-1.594 1.594l-1.051 5.558a1 1 0 0 1-1.966 0l-1.051-5.558a2 2 0 0 0-1.594-1.594l-5.558-1.051a1 1 0 0 1 0-1.966l5.558-1.051a2 2 0 0 0 1.594-1.594z"}],["path",{"d":"M20 2v4"}],["path",{"d":"M22 4h-4"}],["circle",{"cx":"4","cy":"20","r":"2"}]],
    "sprout": [["path",{"d":"M14 9.536V7a4 4 0 0 1 4-4h1.5a.5.5 0 0 1 .5.5V5a4 4 0 0 1-4 4 4 4 0 0 0-4 4c0 2 1 3 1 5a5 5 0 0 1-1 3"}],["path",{"d":"M4 9a5 5 0 0 1 8 4 5 5 0 0 1-8-4"}],["path",{"d":"M5 21h14"}]],
    "squirrel": [["path",{"d":"M15.236 22a3 3 0 0 0-2.2-5"}],["path",{"d":"M16 20a3 3 0 0 1 3-3h1a2 2 0 0 0 2-2v-2a4 4 0 0 0-4-4V4"}],["path",{"d":"M18 13h.01"}],["path",{"d":"M18 6a4 4 0 0 0-4 4 7 7 0 0 0-7 7c0-5 4-5 4-10.5a4.5 4.5 0 1 0-9 0 2.5 2.5 0 0 0 5 0C7 10 3 11 3 17c0 2.8 2.2 5 5 5h10"}]],
    "star": [["path",{"d":"M11.525 2.295a.53.53 0 0 1 .95 0l2.31 4.679a2.123 2.123 0 0 0 1.595 1.16l5.166.756a.53.53 0 0 1 .294.904l-3.736 3.638a2.123 2.123 0 0 0-.611 1.878l.882 5.14a.53.53 0 0 1-.771.56l-4.618-2.428a2.122 2.122 0 0 0-1.973 0L6.396 21.01a.53.53 0 0 1-.77-.56l.881-5.139a2.122 2.122 0 0 0-.611-1.879L2.16 9.795a.53.53 0 0 1 .294-.906l5.165-.755a2.122 2.122 0 0 0 1.597-1.16z"}]],
    "sun": [["circle",{"cx":"12","cy":"12","r":"4"}],["path",{"d":"M12 2v2"}],["path",{"d":"M12 20v2"}],["path",{"d":"m4.93 4.93 1.41 1.41"}],["path",{"d":"m17.66 17.66 1.41 1.41"}],["path",{"d":"M2 12h2"}],["path",{"d":"M20 12h2"}],["path",{"d":"m6.34 17.66-1.41 1.41"}],["path",{"d":"m19.07 4.93-1.41 1.41"}]],
    "telescope": [["path",{"d":"m10.065 12.493-6.18 1.318a.934.934 0 0 1-1.108-.702l-.537-2.15a1.07 1.07 0 0 1 .691-1.265l13.504-4.44"}],["path",{"d":"m13.56 11.747 4.332-.924"}],["path",{"d":"m16 21-3.105-6.21"}],["path",{"d":"M16.485 5.94a2 2 0 0 1 1.455-2.425l1.09-.272a1 1 0 0 1 1.212.727l1.515 6.06a1 1 0 0 1-.727 1.213l-1.09.272a2 2 0 0 1-2.425-1.455z"}],["path",{"d":"m6.158 8.633 1.114 4.456"}],["path",{"d":"m8 21 3.105-6.21"}],["circle",{"cx":"12","cy":"13","r":"2"}]],
    "terminal": [["path",{"d":"M12 19h8"}],["path",{"d":"m4 17 6-6-6-6"}]],
    "tree-palm": [["path",{"d":"M13 8c0-2.76-2.46-5-5.5-5S2 5.24 2 8h2l1-1 1 1h4"}],["path",{"d":"M13 7.14A5.82 5.82 0 0 1 16.5 6c3.04 0 5.5 2.24 5.5 5h-3l-1-1-1 1h-3"}],["path",{"d":"M5.89 9.71c-2.15 2.15-2.3 5.47-.35 7.43l4.24-4.25.7-.7.71-.71 2.12-2.12c-1.95-1.96-5.27-1.8-7.42.35"}],["path",{"d":"M11 15.5c.5 2.5-.17 4.5-1 6.5h4c2-5.5-.5-12-1-14"}]],
    "trees": [["path",{"d":"M10 10v.2A3 3 0 0 1 8.9 16H5a3 3 0 0 1-1-5.8V10a3 3 0 0 1 6 0Z"}],["path",{"d":"M7 16v6"}],["path",{"d":"M13 19v3"}],["path",{"d":"M12 19h8.3a1 1 0 0 0 .7-1.7L18 14h.3a1 1 0 0 0 .7-1.7L16 9h.2a1 1 0 0 0 .8-1.7L13 3l-1.4 1.5"}]],
    "turtle": [["path",{"d":"m12 10 2 4v3a1 1 0 0 0 1 1h2a1 1 0 0 0 1-1v-3a8 8 0 1 0-16 0v3a1 1 0 0 0 1 1h2a1 1 0 0 0 1-1v-3l2-4h4Z"}],["path",{"d":"M4.82 7.9 8 10"}],["path",{"d":"M15.18 7.9 12 10"}],["path",{"d":"M16.93 10H20a2 2 0 0 1 0 4H2"}]],
    "umbrella": [["path",{"d":"M12 13v7a2 2 0 0 0 4 0"}],["path",{"d":"M12 2v2"}],["path",{"d":"M20.992 13a1 1 0 0 0 .97-1.274 10.284 10.284 0 0 0-19.923 0A1 1 0 0 0 3 13z"}]],
    "waves": [["path",{"d":"M2 12q2.5 2 5 0t5 0 5 0 5 0"}],["path",{"d":"M2 19q2.5 2 5 0t5 0 5 0 5 0"}],["path",{"d":"M2 5q2.5 2 5 0t5 0 5 0 5 0"}]],
    "wifi": [["path",{"d":"M12 20h.01"}],["path",{"d":"M2 8.82a15 15 0 0 1 20 0"}],["path",{"d":"M5 12.859a10 10 0 0 1 14 0"}],["path",{"d":"M8.5 16.429a5 5 0 0 1 7 0"}]],
    "zap": [["path",{"d":"M15.914 4a1.5 1.5 0 00-2.474-1.561l-9 9A1.5 1.5 0 005.5 14h4.002a.5.5 0 01.471.666L8.086 20a1.5 1.5 0 002.475 1.56l9-9A1.5 1.5 0 0018.5 10h-3.997a.5.5 0 01-.472-.667z"}]]
  };

  function nodeMarkup(name) {
    return (ICONS[name] || []).map(function (node) {
      return "<" + node[0] + " " + Object.keys(node[1]).map(function (k) { return k + "='" + node[1][k] + "'"; }).join(" ") + "/>";
    }).join("");
  }

  function rng(seed) {
    return function () {
      seed |= 0; seed = (seed + 0x6d2b79f5) | 0;
      var t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }

  var patternCache = {};
  function patternTile(name, ink, alpha) {
    if (!name || name === "none") return "none";
    var key = name + ink + alpha;
    if (patternCache[key]) return patternCache[key];
    var glyphs = PATTERNS[name] || PATTERNS.clouds;
    var order = Object.keys(PATTERNS);
    var rand = rng(order.indexOf(name) * 7919 + 17);
    var cells = 4, tile = 260, cell = tile / cells, out = [];
    for (var row = 0; row < cells; row++) {
      for (var col = 0; col < cells; col++) {
        var glyph = glyphs[Math.floor(rand() * glyphs.length)];
        var size = 17 + rand() * 10;
        var x = (col + 0.5 + (row % 2 ? 0.5 : 0)) * cell + (rand() - 0.5) * cell * 0.35;
        var y = (row + 0.5) * cell + (rand() - 0.5) * cell * 0.35;
        var angle = (rand() - 0.5) * 0.7 * 57.2958;
        [0, -tile, tile].forEach(function (dx) {
          [0, -tile, tile].forEach(function (dy) {
            var px = x + dx, py = y + dy;
            if (px < -size || px > tile + size || py < -size || py > tile + size) return;
            out.push("<g transform='translate(" + px.toFixed(1) + " " + py.toFixed(1) + ") rotate(" + angle.toFixed(1) + ") scale(" + (size / 24).toFixed(3) + ") translate(-12 -12)'>" + nodeMarkup(glyph) + "</g>");
          });
        });
      }
    }
    var svg = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 260 260' width='260' height='260'><g fill='none' stroke='" + ink + "' stroke-opacity='" + alpha.toFixed(3) + "' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'>" + out.join("") + "</g></svg>";
    return (patternCache[key] = 'url("data:image/svg+xml,' + encodeURIComponent(svg) + '")');
  }

  // Client App Built-in Presets (client/lib/theme/presets.dart)
  var PRESETS = {
    casama: {
      name: "Casama",
      pattern: "clouds",
      paletteLabel: "Casama",
      headingFont: '"Libre Baskerville", Georgia, serif',
      bodyFont: '"Lato", -apple-system, sans-serif',
      fontLabel: "Libre Baskerville + Lato",
      light: { accent: "#7a3fa8", accentInk: "#ffffff", pc: "#f1e2fc", onPc: "#2e004e", bg: "#fcf3fb", card: "#fcfafd", ink: "#1e1a20",       wall: ["#eee2fb", "#fbe3ee", "#dde9ff", "#ddf7f5"], patInk: "#5b2f7e" },
      dark:  { accent: "#d9b6f7", accentInk: "#25102f", pc: "#5a1f6e", onPc: "#f2daff", bg: "#1e1a22", card: "#19151c", ink: "#e9e0e8", wall: ["#25102f", "#34123a", "#151f3f", "#0f292e"], patInk: "#e6cff9" },
      intensity: 0.5
    },
    editorial: {
      name: "Editorial",
      pattern: "none",
      paletteLabel: "Peach",
      headingFont: '"Fraunces", Georgia, serif',
      bodyFont: '"Figtree", -apple-system, sans-serif',
      fontLabel: "Fraunces + Figtree",
      light: { accent: "#7c4a2d", accentInk: "#ffffff", pc: "#f9e3d4", onPc: "#381c0a", bg: "#fdf6f0", card: "#fffcf9", ink: "#241b16",       wall: ["#ffe3d3", "#ffd6df", "#fff0d4", "#ffe2ea"], patInk: "#5d3721" },
      dark:  { accent: "#e8b698", accentInk: "#2b160a", pc: "#56321d", onPc: "#f9e3d4", bg: "#1e1815", card: "#181310", ink: "#eee4de", wall: ["#281c16", "#2a181e", "#262014", "#281a20"], patInk: "#f0cbb5" },
      intensity: 0.3
    },
    ocean: {
      name: "Ocean",
      pattern: "sea",
      paletteLabel: "Ocean",
      headingFont: '"Libre Baskerville", Georgia, serif',
      bodyFont: '"Lato", -apple-system, sans-serif',
      fontLabel: "Libre Baskerville + Lato",
      light: { accent: "#175e96", accentInk: "#ffffff", pc: "#d5e8ff", onPc: "#062745", bg: "#f2f8ff", card: "#fafdff", ink: "#14202b", wall: ["#d4eaff", "#cff1f8", "#dde3ff", "#c9e8ff"], patInk: "#114670" },
      dark:  { accent: "#91c8ff", accentInk: "#072742", pc: "#124670", onPc: "#d5e8ff", bg: "#111b24", card: "#0d151d", ink: "#e0ebf5", wall: ["#102030", "#0e262c", "#141c30", "#0e2232"], patInk: "#b5daff" }
    },
    forest: {
      name: "Forest",
      pattern: "garden",
      paletteLabel: "Forest",
      headingFont: '"Libre Baskerville", Georgia, serif',
      bodyFont: '"Lato", -apple-system, sans-serif',
      fontLabel: "Libre Baskerville + Lato",
      light: { accent: "#1d6b42", accentInk: "#ffffff", pc: "#d2f2df", onPc: "#062e18", bg: "#f3faf5", card: "#fbfefc", ink: "#16221b", wall: ["#ddedd2", "#cfe8d7", "#ecf2d0", "#d6ece3"], patInk: "#155031" },
      dark:  { accent: "#82d9a8", accentInk: "#072916", pc: "#154f30", onPc: "#d2f2df", bg: "#121d16", card: "#0e1711", ink: "#e1efe6", wall: ["#162418", "#12241b", "#1c2214", "#13241e"], patInk: "#a8e6c3" }
    },
    sakura: {
      name: "Sakura",
      pattern: "treats",
      paletteLabel: "Cotton candy",
      headingFont: '"Libre Baskerville", Georgia, serif',
      bodyFont: '"Lato", -apple-system, sans-serif',
      fontLabel: "Libre Baskerville + Lato",
      light: { accent: "#b33668", accentInk: "#ffffff", pc: "#ffdbe8", onPc: "#450922", bg: "#fff5f9", card: "#fffbfd", ink: "#24161c", wall: ["#ffddeb", "#e1e4ff", "#ffe9f2", "#dcefff"], patInk: "#86284e" },
      dark:  { accent: "#f9a8c7", accentInk: "#3d0a1f", pc: "#6e1f40", onPc: "#ffdbe8", bg: "#21151a", card: "#1a1014", ink: "#f2e2e8", wall: ["#2d1622", "#181c30", "#2b1824", "#14222e"], patInk: "#fbc4d9" }
    },
    sunset: {
      name: "Sunset",
      pattern: "doodles",
      paletteLabel: "Sunset",
      headingFont: '"Fraunces", Georgia, serif',
      bodyFont: '"Lato", -apple-system, sans-serif',
      fontLabel: "Fraunces + Lato",
      light: { accent: "#bf5215", accentInk: "#ffffff", pc: "#ffe1cf", onPc: "#421700", bg: "#fff7f2", card: "#fffcfa", ink: "#241914", wall: ["#ffd9bf", "#ffc9d6", "#f2d3ff", "#ffe6c2"], patInk: "#8f3d10" },
      dark:  { accent: "#f9b389", accentInk: "#3b1502", pc: "#6e2e0b", onPc: "#ffe1cf", bg: "#211814", card: "#1a120f", ink: "#f2e5df", wall: ["#2e1c12", "#2e1620", "#24162e", "#2b2012"], patInk: "#fcccb0" }
    },
    cosmos: {
      name: "Cosmos",
      pattern: "space",
      paletteLabel: "Lavender",
      headingFont: '"Libre Baskerville", Georgia, serif',
      bodyFont: '"Lato", -apple-system, sans-serif',
      fontLabel: "Libre Baskerville + Lato",
      light: { accent: "#5138a8", accentInk: "#ffffff", pc: "#e5deff", onPc: "#190752", bg: "#f6f3ff", card: "#fcfaff", ink: "#1b1826", wall: ["#e7deff", "#f3e6ff", "#dcd3ff", "#fbefff"], patInk: "#3d2a7e" },
      dark:  { accent: "#c4b5fd", accentInk: "#1b0e4f", pc: "#39257a", onPc: "#e5deff", bg: "#171424", card: "#120f1d", ink: "#e6e2f5", wall: ["#1d1633", "#251633", "#181430", "#26182e"], patInk: "#d7cdfe" },
      intensity: 0.5
    },
    graphite: {
      name: "Graphite",
      pattern: "tech",
      paletteLabel: "Graphite",
      headingFont: '"Google Sans", -apple-system, sans-serif',
      bodyFont: '"Lato", -apple-system, sans-serif',
      fontLabel: "Google Sans + Lato",
      light: { accent: "#363b44", accentInk: "#ffffff", pc: "#e3e6ec", onPc: "#14171c", bg: "#f4f6f8", card: "#fcfdfe", ink: "#181b20",       wall: ["#e9ebef", "#e1e4ea", "#eef0f3", "#dde1e7"], patInk: "#282c33" },
      dark:  { accent: "#c8cdd6", accentInk: "#171a20", pc: "#343942", onPc: "#e3e6ec", bg: "#15171b", card: "#101215", ink: "#e4e7ec", wall: ["#1c1e24", "#181b20", "#1e2026", "#16191e"], patInk: "#dcdfe6" },
      intensity: 0.35
    }
  };

  var currentPresetId = "casama";
  var currentPattern = "clouds";

  function isDarkActive() {
    var explicit = root.getAttribute("data-theme");
    if (explicit === "dark") return true;
    if (explicit === "light") return false;
    return window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches;
  }

  function renderWallpaperAndPreset() {
    var dark = isDarkActive();
    var preset = PRESETS[currentPresetId] || PRESETS.casama;
    var modeColors = dark ? preset.dark : preset.light;
    var intensity = preset.intensity == null ? 0.5 : preset.intensity;
    var alpha = (dark ? 0.16 : 0.22) * intensity;
    var tileUrl = patternTile(currentPattern, modeColors.patInk, alpha);

    // Update full-page wallpaper pattern
    var sitePatternEl = document.getElementById("site-wallpaper-pattern");
    if (sitePatternEl) {
      sitePatternEl.style.backgroundImage = tileUrl;
    }

    // Update CSS custom properties so the whole page reflects the chosen client preset
    root.style.setProperty("--wall-c0", modeColors.wall[0]);
    root.style.setProperty("--wall-c1", modeColors.wall[1]);
    root.style.setProperty("--wall-c2", modeColors.wall[2]);
    root.style.setProperty("--wall-c3", modeColors.wall[3]);
    root.style.setProperty("--accent", modeColors.accent);
    root.style.setProperty("--accent-ink", modeColors.accentInk);
    root.style.setProperty("--primary-container", modeColors.pc);
    root.style.setProperty("--on-primary-container", modeColors.onPc);
    root.style.setProperty("--font-display", preset.headingFont);
    root.style.setProperty("--font-sans", preset.bodyFont);

    // Also update the interactive Gallery / Appearance preview window if present
    var previewStage = document.getElementById("gallery-preview-stage") || document.getElementById("mini-gallery-stage");
    var previewPattern = document.getElementById("gallery-preview-pattern") || document.getElementById("mini-gallery-pattern");
    if (previewStage) {
      previewStage.style.setProperty("--gp-c0", modeColors.wall[0]);
      previewStage.style.setProperty("--gp-c1", modeColors.wall[1]);
      previewStage.style.setProperty("--gp-c2", modeColors.wall[2]);
      previewStage.style.setProperty("--gp-c3", modeColors.wall[3]);
      previewStage.style.setProperty("--gp-card", modeColors.card);
      previewStage.style.setProperty("--gp-ink", modeColors.ink);
      previewStage.style.setProperty("--gp-accent", modeColors.accent);
      previewStage.style.setProperty("--gp-accent-ink", modeColors.accentInk);
      previewStage.style.setProperty("--gp-pc", modeColors.pc);
      previewStage.style.setProperty("--gp-on-pc", modeColors.onPc);
    }
    if (previewPattern) {
      previewPattern.style.backgroundImage = patternTile(currentPattern, modeColors.patInk, Math.min(alpha + 0.04, 0.28));
    }
    var miniName = document.getElementById("mini-gallery-name");
    var miniLink = document.getElementById("mini-gallery-link");
    if (miniName) miniName.textContent = preset.name;
    if (miniLink) miniLink.href = "https://gallery.casama.ai/#theme/" + currentPresetId;

    var nameLabel = document.getElementById("gp-theme-name");
    var fontLabel = document.getElementById("gp-font-label");
    var patternLabel = document.getElementById("gp-pattern-label");
    if (nameLabel) nameLabel.textContent = preset.name + " (" + preset.paletteLabel + ")";
    if (fontLabel) fontLabel.textContent = preset.fontLabel;
    if (patternLabel) patternLabel.textContent = currentPattern === "none" ? "Plain" : (currentPattern.charAt(0).toUpperCase() + currentPattern.slice(1));
  }

  // ---------------------------------------------------------------------------
  // 2. Theme Toggle (Light / Dark)
  // ---------------------------------------------------------------------------
  function applyTheme(theme) {
    if (theme === "dark" || theme === "light") {
      root.setAttribute("data-theme", theme);
    } else {
      root.removeAttribute("data-theme");
    }
    renderWallpaperAndPreset();
  }

  try {
    var saved = localStorage.getItem(storageKey);
    if (saved === "dark" || saved === "light") {
      root.setAttribute("data-theme", saved);
    }
  } catch (e) {}

  renderWallpaperAndPreset();

  if (window.matchMedia) {
    try {
      window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", function () {
        renderWallpaperAndPreset();
      });
    } catch (e) {}
  }

  var toggleBtn = document.getElementById("theme-toggle");
  if (toggleBtn) {
    toggleBtn.addEventListener("click", function () {
      var next = isDarkActive() ? "light" : "dark";
      applyTheme(next);
      try {
        localStorage.setItem(storageKey, next);
      } catch (e) {}
    });
  }

  // ---------------------------------------------------------------------------
  // 3. Random CasamaMark in Header (matches client/lib/ui/casama_mark.dart)
  // ---------------------------------------------------------------------------
  var brandMascots = [
    "/assets/bots/casama-winky-animated.svg",
    "/assets/bots/casama-giggly-animated.svg",
    "/assets/bots/casama-thinker-animated.svg",
    "/assets/bots/casama-wow-animated.svg",
    "/assets/bots/casama-brand-animated.svg"
  ];
  var picked = brandMascots[Math.floor(Math.random() * brandMascots.length)];
  document.querySelectorAll(".brand-mark img").forEach(function (img) {
    img.src = picked;
  });

  // ---------------------------------------------------------------------------
  // 4. Rotating WelcomeTagline (matches client/lib/features/auth/sign_in_screen.dart)
  // ---------------------------------------------------------------------------
  var taglineEl = document.getElementById("rotating-welcome-tagline");
  if (taglineEl) {
    var taglines = [
      "Teammates that keep working after you close the app.",
      "Meet your AI crew.",
      "AI that doesn't just talk. It gets things done.",
      "Capable teammates that ask before they act.",
      "Hand it off. Come back to it done."
    ];
    var tIdx = 0;
    if (window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    setInterval(function () {
      tIdx = (tIdx + 1) % taglines.length;
      taglineEl.style.opacity = "0";
      setTimeout(function () {
        taglineEl.textContent = taglines[tIdx];
        taglineEl.style.opacity = "1";
      }, 220);
    }, 4200);
  }

  // ---------------------------------------------------------------------------
  // 5. Interactive Hero Install Command Switcher + Copy Button
  // ---------------------------------------------------------------------------
  var cmdTabs = document.querySelectorAll("[data-install-tab], .install-tab[data-install-cmd]");
  var cmdCode = document.getElementById("install-command-code") || document.getElementById("install-code");
  var cmdHint = document.getElementById("install-command-hint") || document.getElementById("install-note");
  var copyBtn = document.getElementById("copy-install-btn");
  var copyLabel = document.getElementById("copy-install-label");

  cmdTabs.forEach(function (tab) {
    tab.addEventListener("click", function () {
      cmdTabs.forEach(function (t) {
        t.classList.remove("is-active");
        t.classList.remove("active");
        t.setAttribute("aria-selected", "false");
      });
      tab.classList.add("is-active");
      tab.classList.add("active");
      tab.setAttribute("aria-selected", "true");
      var cmd = tab.dataset.cmd || tab.dataset.installCmd;
      var hint = tab.dataset.hint || tab.dataset.installNote;
      if (cmdCode && cmd) cmdCode.textContent = cmd;
      if (cmdHint && hint) cmdHint.textContent = hint;
    });
  });

  if (copyBtn && cmdCode) {
    copyBtn.addEventListener("click", function () {
      var text = cmdCode.textContent.trim();
      if (!navigator.clipboard) return;
      navigator.clipboard.writeText(text).then(function () {
        if (copyLabel) {
          var prev = copyLabel.textContent;
          copyLabel.textContent = "Copied!";
          copyBtn.classList.add("is-copied");
          setTimeout(function () {
            copyLabel.textContent = prev;
            copyBtn.classList.remove("is-copied");
          }, 1800);
        }
      });
    });
  }

  // ---------------------------------------------------------------------------
  // 6. Interactive Mascot Crew Bar & Bot Workspace Showcase Tabs
  // ---------------------------------------------------------------------------
  var botTabs = document.querySelectorAll("[data-bot-tab], [data-bot-target]");
  var botPanels = document.querySelectorAll("[data-bot-panel]");

  function botTabId(tab) {
    return tab.dataset.botTab || tab.dataset.botTarget;
  }

  function activateBotTab(targetId) {
    botTabs.forEach(function (t) {
      var active = botTabId(t) === targetId;
      t.classList.toggle("is-active", active);
      t.classList.toggle("active", active);
      t.setAttribute("aria-selected", active ? "true" : "false");
    });
    botPanels.forEach(function (panel) {
      var match = panel.dataset.botPanel === targetId;
      panel.classList.toggle("is-active", match);
      if (match) {
        panel.removeAttribute("hidden");
      } else {
        panel.setAttribute("hidden", "");
      }
    });
  }

  botTabs.forEach(function (tab) {
    tab.addEventListener("click", function () {
      activateBotTab(botTabId(tab));
    });
    tab.addEventListener("keydown", function (e) {
      if (e.key !== "ArrowRight" && e.key !== "ArrowLeft") return;
      e.preventDefault();
      var list = Array.prototype.slice.call(botTabs);
      var idx = list.indexOf(tab);
      var nextIdx = e.key === "ArrowRight" ? (idx + 1) % list.length : (idx - 1 + list.length) % list.length;
      list[nextIdx].focus();
      list[nextIdx].click();
    });
  });

  // Mascot crew pills can also jump to or highlight the active mascot expression
  var mascotCrewCards = document.querySelectorAll("[data-mascot-card]");
  var inspectorMascotPreview = document.getElementById("active-mascot-spotlight-img");
  var inspectorMascotName = document.getElementById("active-mascot-spotlight-name");
  var inspectorMascotDesc = document.getElementById("active-mascot-spotlight-desc");

  mascotCrewCards.forEach(function (card) {
    card.addEventListener("click", function () {
      mascotCrewCards.forEach(function (c) { c.classList.remove("is-active"); });
      card.classList.add("is-active");
      if (inspectorMascotPreview && card.dataset.mascotSvg) {
        inspectorMascotPreview.src = card.dataset.mascotSvg;
      }
      if (inspectorMascotName && card.dataset.mascotTitle) {
        inspectorMascotName.textContent = card.dataset.mascotTitle;
      }
      if (inspectorMascotDesc && card.dataset.mascotBio) {
        inspectorMascotDesc.textContent = card.dataset.mascotBio;
      }
      if (card.dataset.linkedBot) {
        activateBotTab(card.dataset.linkedBot);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // 7. Interactive Approval Gate & Checkpoint Rollback Demo
  // ---------------------------------------------------------------------------
  var approveBtn = document.getElementById("demo-approve-btn");
  var rollbackBtn = document.getElementById("demo-rollback-btn");
  var approvalCard = document.getElementById("demo-approval-card");
  var approvalStateText = document.getElementById("demo-approval-state");

  if (approveBtn && approvalCard && approvalStateText) {
    approveBtn.addEventListener("click", function () {
      var approved = approvalCard.classList.toggle("is-approved");
      if (approved) {
        approvalStateText.textContent = "Approved · Step 04 executed in 410ms · Checkpoint #c8a2 saved";
        approveBtn.textContent = "Reset approval demo";
      } else {
        approvalStateText.textContent = "Paused · Waiting for your approval (high-risk command)";
        approveBtn.textContent = "Approve command";
      }
    });
  }

  if (rollbackBtn && approvalCard && approvalStateText) {
    rollbackBtn.addEventListener("click", function () {
      approvalCard.classList.remove("is-approved");
      approvalStateText.textContent = "Restored to Checkpoint #c8a1 · Filesystem & Postgres state rolled back";
      if (approveBtn) approveBtn.textContent = "Approve command";
    });
  }

  // ---------------------------------------------------------------------------
  // 8. Interactive Client Preset & Wallpaper Pattern Switchers
  // ---------------------------------------------------------------------------
  var presetSwatches = document.querySelectorAll("[data-gallery-theme]");
  var patternSwatches = document.querySelectorAll("[data-wallpaper-pattern]");

  presetSwatches.forEach(function (swatch) {
    swatch.addEventListener("click", function () {
      var id = swatch.dataset.galleryTheme;
      if (!PRESETS[id]) return;
      currentPresetId = id;
      currentPattern = PRESETS[id].pattern;
      presetSwatches.forEach(function (s) {
        s.classList.remove("is-active");
        s.classList.remove("active");
        s.setAttribute("aria-pressed", "false");
      });
      swatch.classList.add("is-active");
      swatch.setAttribute("aria-pressed", "true");
      patternSwatches.forEach(function (p) {
        var on = p.dataset.wallpaperPattern === currentPattern;
        p.classList.toggle("is-active", on);
        p.setAttribute("aria-pressed", on ? "true" : "false");
      });
      renderWallpaperAndPreset();
    });
  });

  patternSwatches.forEach(function (patBtn) {
    patBtn.addEventListener("click", function () {
      currentPattern = patBtn.dataset.wallpaperPattern || "clouds";
      patternSwatches.forEach(function (p) {
        p.classList.remove("is-active");
        p.setAttribute("aria-pressed", "false");
      });
      patBtn.classList.add("is-active");
      patBtn.setAttribute("aria-pressed", "true");
      renderWallpaperAndPreset();
    });
  });
})();
