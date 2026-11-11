/*!
 * Casama gallery previews (D-184). Draws a gallery item the way the app does: a small chat in the
 * item's colors, fonts and background, a color scheme as fields of its colors, or a wallpaper.
 * Used by gallery.casama.ai and by the item pages on casama.ai.
 * Icons: Lucide v1.65.0, ISC License, Copyright (c) 2026 Lucide Icons and Contributors.
 */
(function () {
  "use strict";

  // Images come from wherever this script was served: the gallery itself, or a local copy.
  var HOST = (function () {
    try { return new URL(".", new URL(document.currentScript.src, location.href)).href.replace(/\/$/, ""); } catch (e) { return "https://gallery.casama.ai"; }
  })();
  var DATA = {"patterns":{"clouds":["cloud","cloud-sun","star","sparkle","cloud-moon","moon","sparkles","orbit","rainbow"],"doodles":["message-circle","heart","star","smile","coffee","music","rocket","gift","sun","cat","bot","pencil","camera","umbrella","headphones","gamepad-2"],"treats":["ice-cream-cone","cake","candy","popsicle","cookie","donut","lollipop","croissant","cherry","citrus","coffee","heart"],"garden":["leaf","flower","flower-2","sprout","sun","cherry","trees","bug","clover","snail","feather"],"space":["rocket","orbit","moon","star","sparkles","satellite","telescope","earth","sparkle","ghost"],"pets":["cat","dog","paw-print","bone","fish","heart","bird","rabbit","turtle","squirrel"],"sea":["shell","waves","sailboat","anchor","fish","tree-palm","sun","umbrella","cloud"],"tech":["bot","monitor","laptop","terminal","cpu","code","cloud","zap","wifi","mouse-pointer-2","keyboard","server"]},"icons":{"anchor":[["path",{"d":"M12 6v16"}],["path",{"d":"m19 13 2-1a9 9 0 0 1-18 0l2 1"}],["path",{"d":"M9 11h6"}],["circle",{"cx":"12","cy":"4","r":"2"}]],"app-window":[["rect",{"x":"2","y":"4","width":"20","height":"16","rx":"2"}],["path",{"d":"M10 4v4"}],["path",{"d":"M2 8h20"}],["path",{"d":"M6 4v4"}]],"arrow-up":[["path",{"d":"m5 12 7-7 7 7"}],["path",{"d":"M12 19V5"}]],"badge-check":[["path",{"d":"M3.85 8.62a4 4 0 0 1 4.78-4.77 4 4 0 0 1 6.74 0 4 4 0 0 1 4.78 4.78 4 4 0 0 1 0 6.74 4 4 0 0 1-4.77 4.78 4 4 0 0 1-6.75 0 4 4 0 0 1-4.78-4.77 4 4 0 0 1 0-6.76Z"}],["path",{"d":"m16 9-5.5 5.5L8 12"}]],"binoculars":[["path",{"d":"M10 10h4"}],["path",{"d":"M19 7V4a1 1 0 0 0-1-1h-2a1 1 0 0 0-1 1v3"}],["path",{"d":"M20 21a2 2 0 0 0 2-2v-3.851c0-1.39-2-2.962-2-4.829V8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v11a2 2 0 0 0 2 2z"}],["path",{"d":"M 22 16 L 2 16"}],["path",{"d":"M4 21a2 2 0 0 1-2-2v-3.851c0-1.39 2-2.962 2-4.829V8a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v11a2 2 0 0 1-2 2z"}],["path",{"d":"M9 7V4a1 1 0 0 0-1-1H6a1 1 0 0 0-1 1v3"}]],"bird":[["path",{"d":"M16 7h.01"}],["path",{"d":"M3.4 18H12a8 8 0 0 0 8-8V7a4 4 0 0 0-7.28-2.3L2 20"}],["path",{"d":"m20 7 2 .5-2 .5"}],["path",{"d":"M10 18v3"}],["path",{"d":"M14 17.75V21"}],["path",{"d":"M7 18a6 6 0 0 0 3.84-10.61"}]],"bone":[["path",{"d":"M17 10c.7-.7 1.69 0 2.5 0a2.5 2.5 0 1 0 0-5 .5.5 0 0 1-.5-.5 2.5 2.5 0 1 0-5 0c0 .81.7 1.8 0 2.5l-7 7c-.7.7-1.69 0-2.5 0a2.5 2.5 0 0 0 0 5c.28 0 .5.22.5.5a2.5 2.5 0 1 0 5 0c0-.81-.7-1.8 0-2.5Z"}]],"book-open":[["path",{"d":"M12 5v16"}],["path",{"d":"M20.001 19A2 2 0 0022 17V5a2 2 0 00-1.999-2L16 3.002A5 5 0 0012 5a5 5 0 00-4-2H4a2 2 0 00-2 2v12a2 2 0 001.999 2H8a5 5 0 014 2 5 5 0 014-2z"}]],"bot":[["path",{"d":"M12 8V4H8"}],["rect",{"width":"16","height":"12","x":"4","y":"8","rx":"2"}],["path",{"d":"M2 14h2"}],["path",{"d":"M20 14h2"}],["path",{"d":"M15 13v2"}],["path",{"d":"M9 13v2"}]],"briefcase":[["path",{"d":"M16 20V4a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"}],["rect",{"width":"20","height":"14","x":"2","y":"6","rx":"2"}]],"bug":[["path",{"d":"M12 20v-9"}],["path",{"d":"M14 7a4 4 0 0 1 4 4v3a6 6 0 0 1-12 0v-3a4 4 0 0 1 4-4z"}],["path",{"d":"M14.12 3.88 16 2"}],["path",{"d":"M21 21a4 4 0 0 0-3.81-4"}],["path",{"d":"M21 5a4 4 0 0 1-3.55 3.97"}],["path",{"d":"M22 13h-4"}],["path",{"d":"M3 21a4 4 0 0 1 3.81-4"}],["path",{"d":"M3 5a4 4 0 0 0 3.55 3.97"}],["path",{"d":"M6 13H2"}],["path",{"d":"m8 2 1.88 1.88"}],["path",{"d":"M9 7.13V6a3 3 0 1 1 6 0v1.13"}]],"cake":[["path",{"d":"M20 21v-8a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8"}],["path",{"d":"M4 16s.5-1 2-1 2.5 2 4 2 2.5-2 4-2 2.5 2 4 2 2-1 2-1"}],["path",{"d":"M2 21h20"}],["path",{"d":"M7 8v3"}],["path",{"d":"M12 8v3"}],["path",{"d":"M17 8v3"}],["path",{"d":"M7 4h.01"}],["path",{"d":"M12 4h.01"}],["path",{"d":"M17 4h.01"}]],"calendar-check":[["path",{"d":"M8 2v3"}],["path",{"d":"M16 2v3"}],["rect",{"x":"3","y":"3","width":"18","height":"18","rx":"2"}],["path",{"d":"M3 9h18"}],["path",{"d":"m9 15 2 2 4-4"}]],"calendar-clock":[["path",{"d":"M16 14v2.2l1.6 1"}],["path",{"d":"M16 2v3"}],["path",{"d":"M21 7.338V5a2 2 0 00-2-2H5a2 2 0 00-2 2v14a2 2 0 002 2h2.338"}],["path",{"d":"M3 9h5.859"}],["path",{"d":"M8 2v3"}],["circle",{"cx":"16","cy":"16","r":"6"}]],"camera":[["path",{"d":"M13.997 4a2 2 0 0 1 1.76 1.05l.486.9A2 2 0 0 0 18.003 7H20a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2h1.997a2 2 0 0 0 1.759-1.048l.489-.904A2 2 0 0 1 10.004 4z"}],["circle",{"cx":"12","cy":"13","r":"3"}]],"candy":[["path",{"d":"M10 7v10.9"}],["path",{"d":"M14 6.1V17"}],["path",{"d":"M16 7V3a1 1 0 0 1 1.707-.707 2.5 2.5 0 0 0 2.152.717 1 1 0 0 1 1.131 1.131 2.5 2.5 0 0 0 .717 2.152A1 1 0 0 1 21 8h-4"}],["path",{"d":"M16.536 7.465a5 5 0 0 0-7.072 0l-2 2a5 5 0 0 0 0 7.07 5 5 0 0 0 7.072 0l2-2a5 5 0 0 0 0-7.07"}],["path",{"d":"M8 17v4a1 1 0 0 1-1.707.707 2.5 2.5 0 0 0-2.152-.717 1 1 0 0 1-1.131-1.131 2.5 2.5 0 0 0-.717-2.152A1 1 0 0 1 3 16h4"}]],"cat":[["path",{"d":"M12 5c.67 0 1.35.09 2 .26 1.78-2 5.03-2.84 6.42-2.26 1.4.58-.42 7-.42 7 .57 1.07 1 2.24 1 3.44C21 17.9 16.97 21 12 21s-9-3-9-7.56c0-1.25.5-2.4 1-3.44 0 0-1.89-6.42-.5-7 1.39-.58 4.72.23 6.5 2.23A9.04 9.04 0 0 1 12 5Z"}],["path",{"d":"M8 14v.5"}],["path",{"d":"M16 14v.5"}],["path",{"d":"M11.25 16.25h1.5L12 17l-.75-.75Z"}]],"chart-line":[["path",{"d":"M3 3v16a2 2 0 0 0 2 2h16"}],["path",{"d":"m19 9-5 5-4-4-3 3"}]],"check":[["path",{"d":"M20 6 9 17l-5-5"}]],"cherry":[["path",{"d":"M2 17a5 5 0 0 0 10 0c0-2.76-2.5-5-5-3-2.5-2-5 .24-5 3Z"}],["path",{"d":"M12 17a5 5 0 0 0 10 0c0-2.76-2.5-5-5-3-2.5-2-5 .24-5 3Z"}],["path",{"d":"M7 14c3.22-2.91 4.29-8.75 5-12 1.66 2.38 4.94 9 5 12"}],["path",{"d":"M22 9c-4.29 0-7.14-2.33-10-7 5.71 0 10 4.67 10 7Z"}]],"chevron-right":[["path",{"d":"m9 18 6-6-6-6"}]],"citrus":[["path",{"d":"M21.66 17.67a1.08 1.08 0 0 1-.04 1.6A12 12 0 0 1 4.73 2.38a1.1 1.1 0 0 1 1.61-.04z"}],["path",{"d":"M19.65 15.66A8 8 0 0 1 8.35 4.34"}],["path",{"d":"m14 10-5.5 5.5"}],["path",{"d":"M14 17.85V10H6.15"}]],"clipboard-list":[["rect",{"width":"8","height":"4","x":"8","y":"2","rx":"1","ry":"1"}],["path",{"d":"M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"}],["path",{"d":"M12 11h4"}],["path",{"d":"M12 16h4"}],["path",{"d":"M8 11h.01"}],["path",{"d":"M8 16h.01"}]],"cloud":[["path",{"d":"M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z"}]],"cloud-moon":[["path",{"d":"M13 16a3 3 0 0 1 0 6H7a5 5 0 1 1 4.9-6z"}],["path",{"d":"M18.376 14.512a6 6 0 0 0 3.461-4.127c.148-.625-.659-.97-1.248-.714a4 4 0 0 1-5.259-5.26c.255-.589-.09-1.395-.716-1.248a6 6 0 0 0-4.594 5.36"}]],"cloud-off":[["path",{"d":"M10.94 5.274A7 7 0 0 1 15.71 10h1.79a4.5 4.5 0 0 1 4.222 6.057"}],["path",{"d":"M18.796 18.81A4.5 4.5 0 0 1 17.5 19H9A7 7 0 0 1 5.79 5.78"}],["path",{"d":"m2 2 20 20"}]],"cloud-sun":[["path",{"d":"M12 2v2"}],["path",{"d":"m4.93 4.93 1.41 1.41"}],["path",{"d":"M20 12h2"}],["path",{"d":"m19.07 4.93-1.41 1.41"}],["path",{"d":"M15.947 12.65a4 4 0 0 0-5.925-4.128"}],["path",{"d":"M13 22H7a5 5 0 1 1 4.9-6H13a3 3 0 0 1 0 6Z"}]],"clover":[["path",{"d":"M16.17 7.83 2 22"}],["path",{"d":"M4.02 12a2.827 2.827 0 1 1 3.81-4.17A2.827 2.827 0 1 1 12 4.02a2.827 2.827 0 1 1 4.17 3.81A2.827 2.827 0 1 1 19.98 12a2.827 2.827 0 1 1-3.81 4.17A2.827 2.827 0 1 1 12 19.98a2.827 2.827 0 1 1-4.17-3.81A1 1 0 1 1 4 12"}],["path",{"d":"m7.83 7.83 8.34 8.34"}]],"code":[["path",{"d":"m16 18 6-6-6-6"}],["path",{"d":"m8 6-6 6 6 6"}]],"coffee":[["path",{"d":"M10 2v2"}],["path",{"d":"M14 2v2"}],["path",{"d":"M16 8a1 1 0 0 1 1 1v8a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4V9a1 1 0 0 1 1-1h14a4 4 0 1 1 0 8h-1"}],["path",{"d":"M6 2v2"}]],"coins":[["path",{"d":"M13.744 17.736a6 6 0 1 1-7.48-7.48"}],["path",{"d":"M15 6h1v4"}],["path",{"d":"m6.134 14.768.866-.5 2 3.464"}],["circle",{"cx":"16","cy":"8","r":"6"}]],"columns-3":[["rect",{"width":"18","height":"18","x":"3","y":"3","rx":"2"}],["path",{"d":"M9 3v18"}],["path",{"d":"M15 3v18"}]],"compass":[["circle",{"cx":"12","cy":"12","r":"10"}],["path",{"d":"m16.24 7.76-1.804 5.411a2 2 0 0 1-1.265 1.265L7.76 16.24l1.804-5.411a2 2 0 0 1 1.265-1.265z"}]],"cookie":[["path",{"d":"M11 17h.01"}],["path",{"d":"M11.496 2c.324-.016.558.292.529.615a4 4 0 004.235 4.368.713.713 0 01.758.757 4 4 0 004.366 4.237c.323-.03.63.204.614.527a10 10 0 01-2.915 6.566A1 1 0 114.93 4.918 10 10 0 0111.496 2"}],["path",{"d":"M12 12h.01"}],["path",{"d":"M16 16h.01"}],["path",{"d":"M16 3h.01"}],["path",{"d":"M21 4h.01"}],["path",{"d":"M21 8h.01"}],["path",{"d":"M7 14h.01"}],["path",{"d":"M9 8h.01"}]],"cpu":[["path",{"d":"M12 20v2"}],["path",{"d":"M12 2v2"}],["path",{"d":"M17 20v2"}],["path",{"d":"M17 2v2"}],["path",{"d":"M2 12h2"}],["path",{"d":"M2 17h2"}],["path",{"d":"M2 7h2"}],["path",{"d":"M20 12h2"}],["path",{"d":"M20 17h2"}],["path",{"d":"M20 7h2"}],["path",{"d":"M7 20v2"}],["path",{"d":"M7 2v2"}],["rect",{"x":"4","y":"4","width":"16","height":"16","rx":"2"}],["rect",{"x":"8","y":"8","width":"8","height":"8","rx":"1"}]],"croissant":[["path",{"d":"M10.2 18H4.774a1.5 1.5 0 0 1-1.352-.97 11 11 0 0 1 .132-6.487"}],["path",{"d":"M18 10.2V4.774a1.5 1.5 0 0 0-.97-1.352 11 11 0 0 0-6.486.132"}],["path",{"d":"M18 5a4 3 0 0 1 4 3 2 2 0 0 1-2 2 10 10 0 0 0-5.139 1.42"}],["path",{"d":"M5 18a3 4 0 0 0 3 4 2 2 0 0 0 2-2 10 10 0 0 1 1.42-5.14"}],["path",{"d":"M8.709 2.554a10 10 0 0 0-6.155 6.155 1.5 1.5 0 0 0 .676 1.626l9.807 5.42a2 2 0 0 0 2.718-2.718l-5.42-9.807a1.5 1.5 0 0 0-1.626-.676"}]],"database":[["ellipse",{"cx":"12","cy":"5","rx":"9","ry":"3"}],["path",{"d":"M3 5V19A9 3 0 0 0 21 19V5"}],["path",{"d":"M3 12A9 3 0 0 0 21 12"}]],"dog":[["path",{"d":"M11.25 16.25h1.5L12 17z"}],["path",{"d":"M16 14v.5"}],["path",{"d":"M4.42 11.247A13.152 13.152 0 0 0 4 14.556C4 18.728 7.582 21 12 21s8-2.272 8-6.444a11.702 11.702 0 0 0-.493-3.309"}],["path",{"d":"M8 14v.5"}],["path",{"d":"M8.5 8.5c-.384 1.05-1.083 2.028-2.344 2.5-1.931.722-3.576-.297-3.656-1-.113-.994 1.177-6.53 4-7 1.923-.321 3.651.845 3.651 2.235A7.497 7.497 0 0 1 14 5.277c0-1.39 1.844-2.598 3.767-2.277 2.823.47 4.113 6.006 4 7-.08.703-1.725 1.722-3.656 1-1.261-.472-1.855-1.45-2.239-2.5"}]],"donut":[["path",{"d":"M20.5 10a2.5 2.5 0 0 1-2.4-3H18a2.95 2.95 0 0 1-2.6-4.4 10 10 0 1 0 6.3 7.1c-.3.2-.8.3-1.2.3"}],["circle",{"cx":"12","cy":"12","r":"3"}]],"download":[["path",{"d":"M12 15V3"}],["path",{"d":"M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"}],["path",{"d":"m7 10 5 5 5-5"}]],"dumbbell":[["path",{"d":"M17.596 12.768a2 2 0 1 0 2.829-2.829l-1.768-1.767a2 2 0 0 0 2.828-2.829l-2.828-2.828a2 2 0 0 0-2.829 2.828l-1.767-1.768a2 2 0 1 0-2.829 2.829z"}],["path",{"d":"m2.5 21.5 1.4-1.4"}],["path",{"d":"m20.1 3.9 1.4-1.4"}],["path",{"d":"M5.343 21.485a2 2 0 1 0 2.829-2.828l1.767 1.768a2 2 0 1 0 2.829-2.829l-6.364-6.364a2 2 0 1 0-2.829 2.829l1.768 1.767a2 2 0 0 0-2.828 2.829z"}],["path",{"d":"m9.6 14.4 4.8-4.8"}]],"earth":[["path",{"d":"M21.54 15H17a2 2 0 0 0-2 2v4.54"}],["path",{"d":"M7 3.34V5a3 3 0 0 0 3 3a2 2 0 0 1 2 2c0 1.1.9 2 2 2a2 2 0 0 0 2-2c0-1.1.9-2 2-2h3.17"}],["path",{"d":"M11 21.95V18a2 2 0 0 0-2-2a2 2 0 0 1-2-2v-1a2 2 0 0 0-2-2H2.05"}],["circle",{"cx":"12","cy":"12","r":"10"}]],"external-link":[["path",{"d":"M15 3h6v6"}],["path",{"d":"M10 14 21 3"}],["path",{"d":"M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"}]],"feather":[["path",{"d":"M14.086 18.412A2 2 0 0112.67 19H5v-7.672a2 2 0 01.586-1.414L11.75 3.75a6 6 0 118.49 8.49z"}],["path",{"d":"M16 8 2 22"}],["path",{"d":"M17.488 15H9"}]],"file-pen":[["path",{"d":"M12.659 22H18a2 2 0 0 0 2-2V8a2.4 2.4 0 0 0-.706-1.706l-3.588-3.588A2.4 2.4 0 0 0 14 2H6a2 2 0 0 0-2 2v9.34"}],["path",{"d":"M14 2v5a1 1 0 0 0 1 1h5"}],["path",{"d":"M10.378 12.622a1 1 0 0 1 3 3.003L8.36 20.637a2 2 0 0 1-.854.506l-2.867.837a.5.5 0 0 1-.62-.62l.836-2.869a2 2 0 0 1 .506-.853z"}]],"file-search":[["path",{"d":"M6 22a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h8a2.4 2.4 0 0 1 1.704.706l3.588 3.588A2.4 2.4 0 0 1 20 8v12a2 2 0 0 1-2 2z"}],["path",{"d":"M14 2v5a1 1 0 0 0 1 1h5"}],["circle",{"cx":"11.5","cy":"14.5","r":"2.5"}],["path",{"d":"M13.3 16.3 15 18"}]],"file-text":[["path",{"d":"M6 22a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h8a2.4 2.4 0 0 1 1.704.706l3.588 3.588A2.4 2.4 0 0 1 20 8v12a2 2 0 0 1-2 2z"}],["path",{"d":"M14 2v5a1 1 0 0 0 1 1h5"}],["path",{"d":"M10 9H8"}],["path",{"d":"M16 13H8"}],["path",{"d":"M16 17H8"}]],"fish":[["path",{"d":"M6.5 12c.94-3.46 4.94-6 8.5-6 3.56 0 6.06 2.54 7 6-.94 3.47-3.44 6-7 6s-7.56-2.53-8.5-6Z"}],["path",{"d":"M18 12v.5"}],["path",{"d":"M16 17.93a9.77 9.77 0 0 1 0-11.86"}],["path",{"d":"M7 10.67C7 8 5.58 5.97 2.73 5.5c-1 1.5-1 5 .23 6.5-1.24 1.5-1.24 5-.23 6.5C5.58 18.03 7 16 7 13.33"}],["path",{"d":"M10.46 7.26C10.2 5.88 9.17 4.24 8 3h5.8a2 2 0 0 1 1.98 1.67l.23 1.4"}],["path",{"d":"m16.01 17.93-.23 1.4A2 2 0 0 1 13.8 21H9.5a5.96 5.96 0 0 0 1.49-3.98"}]],"flag":[["path",{"d":"M4 22V4a1 1 0 0 1 .4-.8A6 6 0 0 1 8 2c3 0 5 2 7.333 2q2 0 3.067-.8A1 1 0 0 1 20 4v10a1 1 0 0 1-.4.8A6 6 0 0 1 16 16c-3 0-5-2-8-2a6 6 0 0 0-4 1.528"}]],"flower":[["circle",{"cx":"12","cy":"12","r":"3"}],["path",{"d":"M12 16.5A4.5 4.5 0 1 1 7.5 12 4.5 4.5 0 1 1 12 7.5a4.5 4.5 0 1 1 4.5 4.5 4.5 4.5 0 1 1-4.5 4.5"}],["path",{"d":"M12 7.5V9"}],["path",{"d":"M7.5 12H9"}],["path",{"d":"M16.5 12H15"}],["path",{"d":"M12 16.5V15"}],["path",{"d":"m8 8 1.88 1.88"}],["path",{"d":"M14.12 9.88 16 8"}],["path",{"d":"m8 16 1.88-1.88"}],["path",{"d":"M14.12 14.12 16 16"}]],"flower-2":[["path",{"d":"M12 5a3 3 0 1 1 3 3m-3-3a3 3 0 1 0-3 3m3-3v1M9 8a3 3 0 1 0 3 3M9 8h1m5 0a3 3 0 1 1-3 3m3-3h-1m-2 3v-1"}],["circle",{"cx":"12","cy":"8","r":"2"}],["path",{"d":"M12 10v12"}],["path",{"d":"M12 22c4.2 0 7-1.667 7-5-4.2 0-7 1.667-7 5Z"}],["path",{"d":"M12 22c-4.2 0-7-1.667-7-5 4.2 0 7 1.667 7 5Z"}]],"gamepad-2":[["line",{"x1":"6","x2":"10","y1":"11","y2":"11"}],["line",{"x1":"8","x2":"8","y1":"9","y2":"13"}],["line",{"x1":"15","x2":"15.01","y1":"12","y2":"12"}],["line",{"x1":"18","x2":"18.01","y1":"10","y2":"10"}],["path",{"d":"M17.32 5H6.68a4 4 0 0 0-3.978 3.59c-.006.052-.01.101-.017.152C2.604 9.416 2 14.456 2 16a3 3 0 0 0 3 3c1 0 1.5-.5 2-1l1.414-1.414A2 2 0 0 1 9.828 16h4.344a2 2 0 0 1 1.414.586L17 18c.5.5 1 1 2 1a3 3 0 0 0 3-3c0-1.545-.604-6.584-.685-7.258-.007-.05-.011-.1-.017-.151A4 4 0 0 0 17.32 5z"}]],"ghost":[["path",{"d":"M15 10v1"}],["path",{"d":"M7.528 20.472a1.6 1.6 0 012.277 0l1.057 1.056a1.6 1.6 0 002.276 0l1.057-1.056a1.6 1.6 0 012.277 0l1.114 1.114a1.4 1.4 0 002.414-1V10a8 8 0 00-16 0v10.586a1.4 1.4 0 002.414 1z"}],["path",{"d":"M9 10v1"}]],"gift":[["path",{"d":"M12 7v14"}],["path",{"d":"M20 11v8a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2v-8"}],["path",{"d":"M7.5 7a1 1 0 0 1 0-5A4.8 8 0 0 1 12 7a4.8 8 0 0 1 4.5-5 1 1 0 0 1 0 5"}],["rect",{"x":"3","y":"7","width":"18","height":"4","rx":"1"}]],"git-fork":[["circle",{"cx":"12","cy":"18","r":"3"}],["circle",{"cx":"6","cy":"6","r":"3"}],["circle",{"cx":"18","cy":"6","r":"3"}],["path",{"d":"M18 9v2c0 .6-.4 1-1 1H7c-.6 0-1-.4-1-1V9"}],["path",{"d":"M12 12v3"}]],"git-pull-request":[["circle",{"cx":"18","cy":"18","r":"3"}],["circle",{"cx":"6","cy":"6","r":"3"}],["path",{"d":"M13 6h3a2 2 0 0 1 2 2v7"}],["line",{"x1":"6","x2":"6","y1":"9","y2":"21"}]],"graduation-cap":[["path",{"d":"M21.42 10.922a1 1 0 0 0-.019-1.838L12.83 5.18a2 2 0 0 0-1.66 0L2.6 9.08a1 1 0 0 0 0 1.832l8.57 3.908a2 2 0 0 0 1.66 0z"}],["path",{"d":"M22 10v6"}],["path",{"d":"M6 12.5V16a6 3 0 0 0 12 0v-3.5"}]],"headphones":[["path",{"d":"M3 14h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-7a9 9 0 0 1 18 0v7a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3"}]],"heart":[["path",{"d":"M2 9.5a5.5 5.5 0 0 1 9.591-3.676.56.56 0 0 0 .818 0A5.49 5.49 0 0 1 22 9.5c0 2.29-1.5 4-3 5.5l-5.492 5.313a2 2 0 0 1-3 .019L5 15c-1.5-1.5-3-3.2-3-5.5"}]],"ice-cream-cone":[["path",{"d":"m7 11 4.08 10.35a1 1 0 0 0 1.84 0L17 11"}],["path",{"d":"M17 7A5 5 0 0 0 7 7"}],["path",{"d":"M17 7a2 2 0 0 1 0 4H7a2 2 0 0 1 0-4"}]],"image":[["rect",{"width":"18","height":"18","x":"3","y":"3","rx":"2","ry":"2"}],["circle",{"cx":"9","cy":"9","r":"2"}],["path",{"d":"m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"}]],"inbox":[["polyline",{"points":"22 12 16 12 14 15 10 15 8 12 2 12"}],["path",{"d":"M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"}]],"keyboard":[["path",{"d":"M10 8h.01"}],["path",{"d":"M12 12h.01"}],["path",{"d":"M14 8h.01"}],["path",{"d":"M16 12h.01"}],["path",{"d":"M18 8h.01"}],["path",{"d":"M6 8h.01"}],["path",{"d":"M7 16h10"}],["path",{"d":"M8 12h.01"}],["rect",{"width":"20","height":"16","x":"2","y":"4","rx":"2"}]],"laptop":[["path",{"d":"M18 5a2 2 0 0 1 2 2v8.526a2 2 0 0 0 .212.897l1.068 2.127a1 1 0 0 1-.9 1.45H3.62a1 1 0 0 1-.9-1.45l1.068-2.127A2 2 0 0 0 4 15.526V7a2 2 0 0 1 2-2z"}],["path",{"d":"M20.054 15.987H3.946"}]],"layout-dashboard":[["rect",{"width":"7","height":"9","x":"3","y":"3","rx":"1"}],["rect",{"width":"7","height":"5","x":"14","y":"3","rx":"1"}],["rect",{"width":"7","height":"9","x":"14","y":"12","rx":"1"}],["rect",{"width":"7","height":"5","x":"3","y":"16","rx":"1"}]],"leaf":[["path",{"d":"M11 20a10 10 0 0010-10 25.9 25.9 0 00-1.04-7.281 1 1 0 00-1.755-.325C15.833 5.5 13 5.5 9.8 6.1A7 7 0 0011 20"}],["path",{"d":"M2 21a5 5 0 012.911-4.544C7.613 15.212 8.351 15.24 11 13"}]],"link":[["path",{"d":"M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"}],["path",{"d":"M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"}]],"list-tree":[["path",{"d":"M8 5h13"}],["path",{"d":"M13 12h8"}],["path",{"d":"M13 19h8"}],["path",{"d":"M3 10a2 2 0 0 0 2 2h3"}],["path",{"d":"M3 5v12a2 2 0 0 0 2 2h3"}]],"lollipop":[["circle",{"cx":"11","cy":"11","r":"8"}],["path",{"d":"m21 21-4.3-4.3"}],["path",{"d":"M11 11a2 2 0 0 0 4 0 4 4 0 0 0-8 0 6 6 0 0 0 12 0"}]],"mail":[["path",{"d":"m22 7-8.991 5.727a2 2 0 0 1-2.009 0L2 7"}],["rect",{"x":"2","y":"4","width":"20","height":"16","rx":"2"}]],"megaphone":[["path",{"d":"M11 6a13 13 0 0 0 8.4-2.8A1 1 0 0 1 21 4v12a1 1 0 0 1-1.6.8A13 13 0 0 0 11 14H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2z"}],["path",{"d":"M6 14a12 12 0 0 0 2.4 7.2 2 2 0 0 0 3.2-2.4A8 8 0 0 1 10 14"}],["path",{"d":"M8 6v8"}]],"message-circle":[["path",{"d":"M2.992 16.342a2 2 0 0 1 .094 1.167l-1.065 3.29a1 1 0 0 0 1.236 1.168l3.413-.998a2 2 0 0 1 1.099.092 10 10 0 1 0-4.777-4.719"}]],"monitor":[["rect",{"width":"20","height":"14","x":"2","y":"3","rx":"2"}],["line",{"x1":"8","x2":"16","y1":"21","y2":"21"}],["line",{"x1":"12","x2":"12","y1":"17","y2":"21"}]],"moon":[["path",{"d":"M20.985 12.486a9 9 0 1 1-9.473-9.472c.405-.022.617.46.402.803a6 6 0 0 0 8.268 8.268c.344-.215.825-.004.803.401"}]],"mouse-pointer-2":[["path",{"d":"M4.037 4.688a.495.495 0 0 1 .651-.651l16 6.5a.5.5 0 0 1-.063.947l-6.124 1.58a2 2 0 0 0-1.438 1.435l-1.579 6.126a.5.5 0 0 1-.947.063z"}]],"newspaper":[["path",{"d":"M15 18h-5"}],["path",{"d":"M18 14h-8"}],["path",{"d":"M4 22h16a2 2 0 0 0 2-2V4a2 2 0 0 0-2-2H8a2 2 0 0 0-2 2v16a2 2 0 0 1-4 0v-9a2 2 0 0 1 2-2h2"}],["rect",{"width":"8","height":"4","x":"10","y":"6","rx":"1"}]],"notebook-pen":[["path",{"d":"M13.4 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-7.4"}],["path",{"d":"M2 6h4"}],["path",{"d":"M2 10h4"}],["path",{"d":"M2 14h4"}],["path",{"d":"M2 18h4"}],["path",{"d":"M21.378 5.626a1 1 0 1 0-3.004-3.004l-5.01 5.012a2 2 0 0 0-.506.854l-.837 2.87a.5.5 0 0 0 .62.62l2.87-.837a2 2 0 0 0 .854-.506z"}]],"orbit":[["path",{"d":"M20.341 6.484A10 10 0 0 1 10.266 21.85"}],["path",{"d":"M3.659 17.516A10 10 0 0 1 13.74 2.152"}],["circle",{"cx":"12","cy":"12","r":"3"}],["circle",{"cx":"19","cy":"5","r":"2"}],["circle",{"cx":"5","cy":"19","r":"2"}]],"palette":[["path",{"d":"M12 22a1 1 0 0 1 0-20 10 9 0 0 1 10 9 5 5 0 0 1-5 5h-2.25a1.75 1.75 0 0 0-1.4 2.8l.3.4a1.75 1.75 0 0 1-1.4 2.8z"}],["circle",{"cx":"13.5","cy":"6.5","r":".5","fill":"currentColor"}],["circle",{"cx":"17.5","cy":"10.5","r":".5","fill":"currentColor"}],["circle",{"cx":"6.5","cy":"12.5","r":".5","fill":"currentColor"}],["circle",{"cx":"8.5","cy":"7.5","r":".5","fill":"currentColor"}]],"paw-print":[["circle",{"cx":"11","cy":"4","r":"2"}],["circle",{"cx":"18","cy":"8","r":"2"}],["circle",{"cx":"20","cy":"16","r":"2"}],["path",{"d":"M9 10a5 5 0 0 1 5 5v3.5a3.5 3.5 0 0 1-6.84 1.045Q6.52 17.48 4.46 16.84A3.5 3.5 0 0 1 5.5 10Z"}]],"pen-line":[["path",{"d":"M13 21h8"}],["path",{"d":"M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z"}]],"pencil":[["path",{"d":"M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z"}],["path",{"d":"m15 5 4 4"}]],"plane":[["path",{"d":"M17.8 19.2 16 11l3.5-3.5C21 6 21.5 4 21 3c-1-.5-3 0-4.5 1.5L13 8 4.8 6.2c-.5-.1-.9.1-1.1.5l-.3.5c-.2.5-.1 1 .3 1.3L9 12l-2 3H4l-1 1 3 2 2 3 1-1v-3l3-2 3.5 5.3c.3.4.8.5 1.3.3l.5-.2c.4-.3.6-.7.5-1.2z"}]],"popsicle":[["path",{"d":"M18.6 14.4c.8-.8.8-2 0-2.8l-8.1-8.1a4.95 4.95 0 1 0-7.1 7.1l8.1 8.1c.9.7 2.1.7 2.9-.1Z"}],["path",{"d":"m22 22-5.5-5.5"}]],"presentation":[["path",{"d":"M2 3h20"}],["path",{"d":"M21 3v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V3"}],["path",{"d":"m7 21 5-5 5 5"}]],"rabbit":[["path",{"d":"M13 16a3 3 0 0 1 2.24 5"}],["path",{"d":"M18 12h.01"}],["path",{"d":"M18 21h-8a4 4 0 0 1-4-4 7 7 0 0 1 7-7h.2L9.6 6.4a1 1 0 1 1 2.8-2.8L15.8 7h.2c3.3 0 6 2.7 6 6v1a2 2 0 0 1-2 2h-1a3 3 0 0 0-3 3"}],["path",{"d":"M20 8.54V4a2 2 0 1 0-4 0v3"}],["path",{"d":"M7.612 12.524a3 3 0 1 0-1.6 4.3"}]],"rainbow":[["path",{"d":"M22 17a10 10 0 0 0-20 0"}],["path",{"d":"M6 17a6 6 0 0 1 12 0"}],["path",{"d":"M10 17a2 2 0 0 1 4 0"}]],"receipt":[["path",{"d":"M12 17V7"}],["path",{"d":"M16 8h-6a2 2 0 0 0 0 4h4a2 2 0 0 1 0 4H8"}],["path",{"d":"M4 3a1 1 0 0 1 1-1 1.3 1.3 0 0 1 .7.2l.933.6a1.3 1.3 0 0 0 1.4 0l.934-.6a1.3 1.3 0 0 1 1.4 0l.933.6a1.3 1.3 0 0 0 1.4 0l.933-.6a1.3 1.3 0 0 1 1.4 0l.934.6a1.3 1.3 0 0 0 1.4 0l.933-.6A1.3 1.3 0 0 1 19 2a1 1 0 0 1 1 1v18a1 1 0 0 1-1 1 1.3 1.3 0 0 1-.7-.2l-.933-.6a1.3 1.3 0 0 0-1.4 0l-.934.6a1.3 1.3 0 0 1-1.4 0l-.933-.6a1.3 1.3 0 0 0-1.4 0l-.933.6a1.3 1.3 0 0 1-1.4 0l-.934-.6a1.3 1.3 0 0 0-1.4 0l-.933.6a1.3 1.3 0 0 1-.7.2 1 1 0 0 1-1-1z"}]],"rocket":[["path",{"d":"M12 15v5s3.03-.55 4-2c1.08-1.62 0-5 0-5"}],["path",{"d":"M4.5 16.5c-1.5 1.26-2 5-2 5s3.74-.5 5-2c.71-.84.7-2.13-.09-2.91a2.18 2.18 0 0 0-2.91-.09"}],["path",{"d":"M9 12a22 22 0 0 1 2-3.95A12.88 12.88 0 0 1 22 2c0 2.72-.78 7.5-6 11a22.4 22.4 0 0 1-4 2z"}],["path",{"d":"M9 12H4s.55-3.03 2-4c1.62-1.08 5 .05 5 .05"}]],"sailboat":[["path",{"d":"M10 2v15"}],["path",{"d":"M7 22a4 4 0 0 1-4-4 1 1 0 0 1 1-1h16a1 1 0 0 1 1 1 4 4 0 0 1-4 4z"}],["path",{"d":"M9.159 2.46a1 1 0 0 1 1.521-.193l9.977 8.98A1 1 0 0 1 20 13H4a1 1 0 0 1-.824-1.567z"}]],"satellite":[["path",{"d":"m13.5 6.5-3.148-3.148a1.205 1.205 0 0 0-1.704 0L6.352 5.648a1.205 1.205 0 0 0 0 1.704L9.5 10.5"}],["path",{"d":"M16.5 7.5 19 5"}],["path",{"d":"m17.5 10.5 3.148 3.148a1.205 1.205 0 0 1 0 1.704l-2.296 2.296a1.205 1.205 0 0 1-1.704 0L13.5 14.5"}],["path",{"d":"M9 21a6 6 0 0 0-6-6"}],["path",{"d":"M9.352 10.648a1.205 1.205 0 0 0 0 1.704l2.296 2.296a1.205 1.205 0 0 0 1.704 0l4.296-4.296a1.205 1.205 0 0 0 0-1.704l-2.296-2.296a1.205 1.205 0 0 0-1.704 0z"}]],"scale":[["path",{"d":"M12 3v18"}],["path",{"d":"m19 8 3 8a5 5 0 0 1-6 0zV7"}],["path",{"d":"M3 7h1a17 17 0 0 0 8-2 17 17 0 0 0 8 2h1"}],["path",{"d":"m5 8 3 8a5 5 0 0 1-6 0zV7"}],["path",{"d":"M7 21h10"}]],"search":[["path",{"d":"m21 21-4.34-4.34"}],["circle",{"cx":"11","cy":"11","r":"8"}]],"search-x":[["path",{"d":"m13.5 8.5-5 5"}],["path",{"d":"m8.5 8.5 5 5"}],["circle",{"cx":"11","cy":"11","r":"8"}],["path",{"d":"m21 21-4.3-4.3"}]],"server":[["rect",{"width":"20","height":"8","x":"2","y":"2","rx":"2","ry":"2"}],["rect",{"width":"20","height":"8","x":"2","y":"14","rx":"2","ry":"2"}],["line",{"x1":"6","x2":"6.01","y1":"6","y2":"6"}],["line",{"x1":"6","x2":"6.01","y1":"18","y2":"18"}]],"share":[["path",{"d":"M12 2v13"}],["path",{"d":"m16 6-4-4-4 4"}],["path",{"d":"M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"}]],"sheet":[["rect",{"width":"18","height":"18","x":"3","y":"3","rx":"2","ry":"2"}],["line",{"x1":"3","x2":"21","y1":"9","y2":"9"}],["line",{"x1":"3","x2":"21","y1":"15","y2":"15"}],["line",{"x1":"9","x2":"9","y1":"9","y2":"21"}],["line",{"x1":"15","x2":"15","y1":"9","y2":"21"}]],"shell":[["path",{"d":"M14 11a2 2 0 1 1-4 0 4 4 0 0 1 8 0 6 6 0 0 1-12 0 8 8 0 0 1 16 0 10 10 0 1 1-20 0 11.93 11.93 0 0 1 2.42-7.22 2 2 0 1 1 3.16 2.44"}]],"sigma":[["path",{"d":"M18 7V5a1 1 0 0 0-1-1H6.5a.5.5 0 0 0-.4.8l4.5 6a2 2 0 0 1 0 2.4l-4.5 6a.5.5 0 0 0 .4.8H17a1 1 0 0 0 1-1v-2"}]],"snail":[["path",{"d":"M2 13a6 6 0 1 0 12 0 4 4 0 1 0-8 0 2 2 0 0 0 4 0"}],["circle",{"cx":"10","cy":"13","r":"8"}],["path",{"d":"M2 21h12c4.4 0 8-3.6 8-8V7a2 2 0 1 0-4 0v6"}],["path",{"d":"M18 3 19.1 5.2"}],["path",{"d":"M22 3 20.9 5.2"}]],"sparkle":[["path",{"d":"M11.017 2.814a1 1 0 0 1 1.966 0l1.051 5.558a2 2 0 0 0 1.594 1.594l5.558 1.051a1 1 0 0 1 0 1.966l-5.558 1.051a2 2 0 0 0-1.594 1.594l-1.051 5.558a1 1 0 0 1-1.966 0l-1.051-5.558a2 2 0 0 0-1.594-1.594l-5.558-1.051a1 1 0 0 1 0-1.966l5.558-1.051a2 2 0 0 0 1.594-1.594z"}]],"sparkles":[["path",{"d":"M11.017 2.814a1 1 0 0 1 1.966 0l1.051 5.558a2 2 0 0 0 1.594 1.594l5.558 1.051a1 1 0 0 1 0 1.966l-5.558 1.051a2 2 0 0 0-1.594 1.594l-1.051 5.558a1 1 0 0 1-1.966 0l-1.051-5.558a2 2 0 0 0-1.594-1.594l-5.558-1.051a1 1 0 0 1 0-1.966l5.558-1.051a2 2 0 0 0 1.594-1.594z"}],["path",{"d":"M20 2v4"}],["path",{"d":"M22 4h-4"}],["circle",{"cx":"4","cy":"20","r":"2"}]],"spell-check":[["path",{"d":"m20 15-5.5 5.5L12 18"}],["path",{"d":"m4 16 6-12 5.115 10.23"}],["path",{"d":"M6 12h8"}]],"sprout":[["path",{"d":"M14 9.536V7a4 4 0 0 1 4-4h1.5a.5.5 0 0 1 .5.5V5a4 4 0 0 1-4 4 4 4 0 0 0-4 4c0 2 1 3 1 5a5 5 0 0 1-1 3"}],["path",{"d":"M4 9a5 5 0 0 1 8 4 5 5 0 0 1-8-4"}],["path",{"d":"M5 21h14"}]],"squirrel":[["path",{"d":"M15.236 22a3 3 0 0 0-2.2-5"}],["path",{"d":"M16 20a3 3 0 0 1 3-3h1a2 2 0 0 0 2-2v-2a4 4 0 0 0-4-4V4"}],["path",{"d":"M18 13h.01"}],["path",{"d":"M18 6a4 4 0 0 0-4 4 7 7 0 0 0-7 7c0-5 4-5 4-10.5a4.5 4.5 0 1 0-9 0 2.5 2.5 0 0 0 5 0C7 10 3 11 3 17c0 2.8 2.2 5 5 5h10"}]],"star":[["path",{"d":"M11.525 2.295a.53.53 0 0 1 .95 0l2.31 4.679a2.123 2.123 0 0 0 1.595 1.16l5.166.756a.53.53 0 0 1 .294.904l-3.736 3.638a2.123 2.123 0 0 0-.611 1.878l.882 5.14a.53.53 0 0 1-.771.56l-4.618-2.428a2.122 2.122 0 0 0-1.973 0L6.396 21.01a.53.53 0 0 1-.77-.56l.881-5.139a2.122 2.122 0 0 0-.611-1.879L2.16 9.795a.53.53 0 0 1 .294-.906l5.165-.755a2.122 2.122 0 0 0 1.597-1.16z"}]],"sun":[["circle",{"cx":"12","cy":"12","r":"4"}],["path",{"d":"M12 2v2"}],["path",{"d":"M12 20v2"}],["path",{"d":"m4.93 4.93 1.41 1.41"}],["path",{"d":"m17.66 17.66 1.41 1.41"}],["path",{"d":"M2 12h2"}],["path",{"d":"M20 12h2"}],["path",{"d":"m6.34 17.66-1.41 1.41"}],["path",{"d":"m19.07 4.93-1.41 1.41"}]],"table-2":[["path",{"d":"M3 9h18"}],["path",{"d":"M9 3v18"}],["rect",{"x":"3","y":"3","width":"18","height":"18","rx":"2"}]],"telescope":[["path",{"d":"m10.065 12.493-6.18 1.318a.934.934 0 0 1-1.108-.702l-.537-2.15a1.07 1.07 0 0 1 .691-1.265l13.504-4.44"}],["path",{"d":"m13.56 11.747 4.332-.924"}],["path",{"d":"m16 21-3.105-6.21"}],["path",{"d":"M16.485 5.94a2 2 0 0 1 1.455-2.425l1.09-.272a1 1 0 0 1 1.212.727l1.515 6.06a1 1 0 0 1-.727 1.213l-1.09.272a2 2 0 0 1-2.425-1.455z"}],["path",{"d":"m6.158 8.633 1.114 4.456"}],["path",{"d":"m8 21 3.105-6.21"}],["circle",{"cx":"12","cy":"13","r":"2"}]],"terminal":[["path",{"d":"M12 19h8"}],["path",{"d":"m4 17 6-6-6-6"}]],"tree-palm":[["path",{"d":"M13 8c0-2.76-2.46-5-5.5-5S2 5.24 2 8h2l1-1 1 1h4"}],["path",{"d":"M13 7.14A5.82 5.82 0 0 1 16.5 6c3.04 0 5.5 2.24 5.5 5h-3l-1-1-1 1h-3"}],["path",{"d":"M5.89 9.71c-2.15 2.15-2.3 5.47-.35 7.43l4.24-4.25.7-.7.71-.71 2.12-2.12c-1.95-1.96-5.27-1.8-7.42.35"}],["path",{"d":"M11 15.5c.5 2.5-.17 4.5-1 6.5h4c2-5.5-.5-12-1-14"}]],"trees":[["path",{"d":"M10 10v.2A3 3 0 0 1 8.9 16H5a3 3 0 0 1-1-5.8V10a3 3 0 0 1 6 0Z"}],["path",{"d":"M7 16v6"}],["path",{"d":"M13 19v3"}],["path",{"d":"M12 19h8.3a1 1 0 0 0 .7-1.7L18 14h.3a1 1 0 0 0 .7-1.7L16 9h.2a1 1 0 0 0 .8-1.7L13 3l-1.4 1.5"}]],"turtle":[["path",{"d":"m12 10 2 4v3a1 1 0 0 0 1 1h2a1 1 0 0 0 1-1v-3a8 8 0 1 0-16 0v3a1 1 0 0 0 1 1h2a1 1 0 0 0 1-1v-3l2-4h4Z"}],["path",{"d":"M4.82 7.9 8 10"}],["path",{"d":"M15.18 7.9 12 10"}],["path",{"d":"M16.93 10H20a2 2 0 0 1 0 4H2"}]],"type":[["path",{"d":"M12 4v16"}],["path",{"d":"M4 7V5a1 1 0 0 1 1-1h14a1 1 0 0 1 1 1v2"}],["path",{"d":"M9 20h6"}]],"umbrella":[["path",{"d":"M12 13v7a2 2 0 0 0 4 0"}],["path",{"d":"M12 2v2"}],["path",{"d":"M20.992 13a1 1 0 0 0 .97-1.274 10.284 10.284 0 0 0-19.923 0A1 1 0 0 0 3 13z"}]],"utensils":[["path",{"d":"M3 2v7c0 1.1.9 2 2 2h4a2 2 0 0 0 2-2V2"}],["path",{"d":"M7 2v20"}],["path",{"d":"M21 15V2a5 5 0 0 0-5 5v6c0 1.1.9 2 2 2h3Zm0 0v7"}]],"wallet":[["path",{"d":"M19 7V4a1 1 0 0 0-1-1H5a2 2 0 0 0 0 4h15a1 1 0 0 1 1 1v4h-3a2 2 0 0 0 0 4h3a1 1 0 0 0 1-1v-2a1 1 0 0 0-1-1"}],["path",{"d":"M3 5v14a2 2 0 0 0 2 2h15a1 1 0 0 0 1-1v-4"}]],"wand-sparkles":[["path",{"d":"m21.64 3.64-1.28-1.28a1.21 1.21 0 0 0-1.72 0L2.36 18.64a1.21 1.21 0 0 0 0 1.72l1.28 1.28a1.2 1.2 0 0 0 1.72 0L21.64 5.36a1.2 1.2 0 0 0 0-1.72"}],["path",{"d":"m14 7 3 3"}],["path",{"d":"M5 6v4"}],["path",{"d":"M19 14v4"}],["path",{"d":"M10 2v2"}],["path",{"d":"M7 8H3"}],["path",{"d":"M21 16h-4"}],["path",{"d":"M11 3H9"}]],"wifi":[["path",{"d":"M12 20h.01"}],["path",{"d":"M2 8.82a15 15 0 0 1 20 0"}],["path",{"d":"M5 12.859a10 10 0 0 1 14 0"}],["path",{"d":"M8.5 16.429a5 5 0 0 1 7 0"}]],"x":[["path",{"d":"M18 6 6 18"}],["path",{"d":"m6 6 12 12"}]],"zap":[["path",{"d":"M15.914 4a1.5 1.5 0 00-2.474-1.561l-9 9A1.5 1.5 0 005.5 14h4.002a.5.5 0 01.471.666L8.086 20a1.5 1.5 0 002.475 1.56l9-9A1.5 1.5 0 0018.5 10h-3.997a.5.5 0 01-.472-.667z"}]],"music":[["path",{"d":"M21 16V3a1 1 0 0 0-1.28-.96l-10 2.917a1 1 0 0 0-.72.96V19"}],["circle",{"cx":"18","cy":"16","r":"3"}],["circle",{"cx":"6","cy":"19","r":"3"}]],"smile":[["path",{"d":"M15 10V9"}],["path",{"d":"M16.472 15a6 6 0 01-8.943 0"}],["path",{"d":"M9 10V9"}],["circle",{"cx":"12","cy":"12","r":"10"}]],"waves":[["path",{"d":"M2 12q2.5 2 5 0t5 0 5 0 5 0"}],["path",{"d":"M2 19q2.5 2 5 0t5 0 5 0 5 0"}],["path",{"d":"M2 5q2.5 2 5 0t5 0 5 0 5 0"}]]}};
  var ICONS = DATA.icons;
  var PATTERNS = DATA.patterns;
  var SVG = "http://www.w3.org/2000/svg";

  // Wallpaper palettes, as the app draws them (client/lib/theme/wallpaper.dart).
  var PALETTES = {
    casama: { light: ["#EEE2FB", "#FBE3EE", "#DDE9FF", "#DDF7F5"], dark: ["#25102F", "#34123A", "#151F3F", "#0F292E"] },
    lavender: { light: ["#E7DEFF", "#F3E6FF", "#DCD3FF", "#FBEFFF"] },
    cotton: { light: ["#FFDDEB", "#E1E4FF", "#FFE9F2", "#DCEFFF"] },
    peach: { light: ["#FFE3D3", "#FFD6DF", "#FFF0D4", "#FFE2EA"] },
    sunset: { light: ["#FFD9BF", "#FFC9D6", "#F2D3FF", "#FFE6C2"] },
    mint: { light: ["#D5F5E7", "#E3FAF3", "#CDEFDE", "#EDFBEF"] },
    ocean: { light: ["#D4EAFF", "#CFF1F8", "#DDE3FF", "#C9E8FF"] },
    forest: { light: ["#DDEDD2", "#CFE8D7", "#ECF2D0", "#D6ECE3"] },
    graphite: { light: ["#E9EBEF", "#E1E4EA", "#EEF0F3", "#DDE1E7"] },
  };
  var PATTERN_LABELS = { none: "Plain", clouds: "Clouds", doodles: "Doodles", treats: "Treats", garden: "Garden", space: "Space", pets: "Pets", sea: "Seaside", tech: "Tech" };
  var PALETTE_LABELS = { theme: "Theme", casama: "Casama", lavender: "Lavender", cotton: "Cotton candy", peach: "Peach", sunset: "Sunset", mint: "Mint", ocean: "Ocean", forest: "Forest", graphite: "Graphite" };

  // The app's own scheme, exactly as it renders (light and dark).
  var CASAMA = {
    light: { p: "#7a3fa8", onP: "#ffffff", pc: "#f2daff", onPc: "#2e004e", s: "#3b78db", onS: "#ffffff", t: "#0e8f9a", onT: "#ffffff", surf: "#fcf3fb", onSurf: "#1e1a20", high: "#ebe2eb", lowest: "#fcfafd", cont: "#f1e8f1", outline: "#cfc2d4", onSurfVar: "#4c4452" },
    dark: { p: "#d9b6f7", onP: "#000000", pc: "#563a70", onPc: "#f2daff", s: "#9dc3ff", onS: "#000000", t: "#7feae4", onT: "#000000", surf: "#1e1a22", onSurf: "#e9e0e8", high: "#343037", lowest: "#19151c", cont: "#2b252e", outline: "#4c4452", onSurfVar: "#cfc2d4" },
  };
  var DEFAULT_LOOK = { scheme: null, headingFont: "Libre Baskerville", bodyFont: "Lato", wallpaper: { kind: "pattern", pattern: "clouds", palette: "theme", intensity: 0.5 } };

  // ---------------------------------------------------------------- color
  function rgb(hex) {
    var n = parseInt(hex.slice(1), 16);
    return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
  }
  function hex(c) {
    return "#" + c.map(function (v) { return Math.round(Math.max(0, Math.min(255, v))).toString(16).padStart(2, "0"); }).join("");
  }
  function mix(a, b, t) {
    var x = rgb(a), y = rgb(b);
    return hex([0, 1, 2].map(function (i) { return x[i] + (y[i] - x[i]) * t; }));
  }
  function toHsl(h) {
    var c = rgb(h).map(function (v) { return v / 255; });
    var max = Math.max.apply(null, c), min = Math.min.apply(null, c), l = (max + min) / 2, s = 0, hue = 0;
    if (max !== min) {
      var d = max - min;
      s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
      hue = max === c[0] ? (c[1] - c[2]) / d + (c[1] < c[2] ? 6 : 0) : max === c[1] ? (c[2] - c[0]) / d + 2 : (c[0] - c[1]) / d + 4;
      hue *= 60;
    }
    return [hue, s * 100, l * 100];
  }
  function fromHsl(h, s, l) {
    s = Math.max(0, Math.min(100, s)) / 100;
    l = Math.max(0, Math.min(100, l)) / 100;
    var k = function (n) { return (n + h / 30) % 12; };
    var a = s * Math.min(l, 1 - l);
    var f = function (n) { return l - a * Math.max(-1, Math.min(k(n) - 3, Math.min(9 - k(n), 1))); };
    return hex([f(0) * 255, f(8) * 255, f(4) * 255]);
  }
  function lum(h) {
    return rgb(h).map(function (v) { v /= 255; return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); })
      .reduce(function (acc, v, i) { return acc + v * [0.2126, 0.7152, 0.0722][i]; }, 0);
  }
  function on(h) {
    return lum(h) > 0.32 ? "#000000" : "#ffffff";
  }

  /** The scheme the app builds from a gallery seed (an approximation of its tonal palettes). */
  function scheme(seeds, dark) {
    if (!seeds || !seeds.light || !seeds.dark) return CASAMA[dark ? "dark" : "light"];
    var p = (dark ? seeds.dark : seeds.light).seed;
    var hsl = toHsl(p), h = hsl[0], s = hsl[1], l = hsl[2];
    if (!dark) {
      var pc = fromHsl(h, Math.max(s, 60) + 20, 90);
      var sec = mix(p, "#ffffff", 0.19);
      var ter = fromHsl(h, s, l + 14);
      return {
        p: p, onP: on(p), pc: pc, onPc: fromHsl(h, 90, 10), s: sec, onS: on(sec), t: ter, onT: on(ter),
        surf: mix("#ffffff", p, 0.05), onSurf: mix("#1b1b1f", p, 0.06), high: mix("#e5e5ea", p, 0.05),
        lowest: mix("#ffffff", p, 0.015), cont: mix("#eaeaef", p, 0.05), outline: mix("#c5c6d0", p, 0.06), onSurfVar: mix("#45464f", p, 0.08),
      };
    }
    var pcD = fromHsl(h, 50, 30);
    var secD = fromHsl(h, s, l + 5);
    var terD = fromHsl(h, s, l + 12);
    return {
      p: p, onP: on(p), pc: pcD, onPc: fromHsl(h, 90, 90), s: secD, onS: on(secD), t: terD, onT: on(terD),
      surf: fromHsl(h, 16, 11), onSurf: "#e2e2e7", high: fromHsl(h, 9, 20), lowest: fromHsl(h, 18, 8),
      cont: fromHsl(h, 12, 16), outline: fromHsl(h, 7, 28), onSurfVar: "#c4c6cf",
    };
  }

  function palette(name, c, dark) {
    if (name === "theme" || !PALETTES[name]) {
      var to = dark ? "#0C0B11" : "#ffffff", k = dark ? 0 : 0.04;
      return [mix(c.p, to, 0.84 + k), mix(c.t, to, 0.82 + k), mix(c.s, to, 0.84 + k), mix(c.p, to, 0.9 + k)];
    }
    var pal = PALETTES[name];
    if (!dark) return pal.light;
    return pal.dark || pal.light.map(function (x) { return mix(x, "#0C0B11", 0.86); });
  }

  // ---------------------------------------------------------------- icons
  function icon(name, opts) {
    opts = opts || {};
    var svg = document.createElementNS(SVG, "svg");
    svg.setAttribute("viewBox", "0 0 24 24");
    svg.setAttribute("fill", "none");
    svg.setAttribute("stroke", "currentColor");
    svg.setAttribute("stroke-width", opts.stroke || 2);
    svg.setAttribute("stroke-linecap", "round");
    svg.setAttribute("stroke-linejoin", "round");
    svg.setAttribute("aria-hidden", "true");
    if (opts.size) {
      svg.setAttribute("width", opts.size);
      svg.setAttribute("height", opts.size);
    }
    (ICONS[name] || ICONS["book-open"]).forEach(function (node) {
      var el = document.createElementNS(SVG, node[0]);
      Object.keys(node[1]).forEach(function (k) { el.setAttribute(k, node[1][k]); });
      svg.appendChild(el);
    });
    return svg;
  }

  function nodeMarkup(name) {
    return (ICONS[name] || []).map(function (node) {
      return "<" + node[0] + " " + Object.keys(node[1]).map(function (k) { return k + "='" + node[1][k] + "'"; }).join(" ") + "/>";
    }).join("");
  }

  // A seeded random like the app's, so a pattern draws the same way every time.
  function rng(seed) {
    return function () {
      seed |= 0; seed = (seed + 0x6d2b79f5) | 0;
      var t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }
  var patternCache = {};
  /** The repeating tile of a pattern: 4 × 4 glyphs on a 260-unit square, as in the app. */
  function patternTile(name, ink, alpha) {
    var key = name + ink + alpha;
    if (patternCache[key]) return patternCache[key];
    var glyphs = PATTERNS[name] || [];
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

  // ---------------------------------------------------------------- fonts
  var loadedFonts = {};
  var SYSTEM = { "Google Sans": true };
  /** Loads Google Fonts for previews; a family without a 600 weight is loaded at its one weight. */
  function ensureFonts(families) {
    families.forEach(function (family) {
      if (!family || loadedFonts[family] || SYSTEM[family]) return;
      loadedFonts[family] = true;
      var q = family.replace(/ /g, "+");
      var link = document.createElement("link");
      link.rel = "stylesheet";
      link.href = "https://fonts.googleapis.com/css2?family=" + q + ":wght@400;600&display=swap";
      link.onerror = function () { link.href = "https://fonts.googleapis.com/css2?family=" + q + "&display=swap"; link.onerror = null; };
      document.head.appendChild(link);
    });
  }

  // ---------------------------------------------------------------- items
  function wallpaperOf(item) {
    var doc = item.document || {};
    if (item.type === "wallpaper") return doc;
    if (item.type === "theme") return doc.wallpaper || null;
    return null;
  }
  function imageUrl(item, doc, thumb) {
    var file = thumb ? doc.thumb || doc.file : doc.file;
    return HOST + "/wallpapers/" + item.id + "/" + file;
  }

  /** What a screen looks like with this item; with alone, a scheme is shown on a plain background. */
  function lookOf(item, opts) {
    opts = opts || {};
    var doc = item.document || {};
    var look = { scheme: null, headingFont: DEFAULT_LOOK.headingFont, bodyFont: DEFAULT_LOOK.bodyFont, wallpaper: DEFAULT_LOOK.wallpaper, item: item };
    if (item.type === "theme") {
      look.scheme = typeof doc.scheme === "object" ? doc.scheme : null;
      look.headingFont = doc.headingFont || look.headingFont;
      look.bodyFont = doc.bodyFont || look.bodyFont;
      look.wallpaper = doc.wallpaper || look.wallpaper;
    } else if (item.type === "scheme") {
      look.scheme = doc;
      if (opts.alone) look.wallpaper = null;
    } else if (item.type === "wallpaper") {
      look.wallpaper = doc;
    }
    return look;
  }

  function el(tag, cls, text) {
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text != null) e.textContent = text;
    return e;
  }

  function setVars(node, vars) {
    Object.keys(vars).forEach(function (k) { node.style.setProperty(k, vars[k]); });
  }

  /** The background layers of a screen: gradient or photo, then the pattern. */
  function background(screen, wall, c, dark, opts) {
    opts = opts || {};
    if (!wall) return;
    if (wall.kind === "image" && opts.item) {
      var photo = el("div", "cg-photo" + (opts.sharp ? "" : " is-blurred"));
      var img = el("img");
      img.src = imageUrl(opts.item, wall, opts.thumb);
      img.alt = "";
      img.loading = "lazy";
      img.decoding = "async";
      photo.appendChild(img);
      screen.appendChild(photo);
      if (!opts.sharp) screen.appendChild(el("div", "cg-dim"));
      return;
    }
    var colors = palette(wall.palette || "theme", c, dark);
    var layer = el("div", "cg-wall");
    setVars(layer, { "--c0": colors[0], "--c1": colors[1], "--c2": colors[2], "--c3": colors[3], "--r": opts.portrait ? "113cqw" : "85cqw" });
    screen.appendChild(layer);
    var intensity = typeof wall.intensity === "number" ? wall.intensity : 0.5;
    if (wall.pattern && wall.pattern !== "none" && intensity > 0) {
      var ink = dark ? mix(c.p, "#ffffff", 0.35) : mix(c.p, "#000000", 0.25);
      var pattern = el("div", "cg-pattern");
      pattern.style.backgroundImage = patternTile(wall.pattern, ink, (dark ? 0.16 : 0.22) * intensity);
      pattern.style.backgroundSize = opts.portrait ? "calc(100cqw * 260 / 390)" : "calc(var(--u) * 260)";
      screen.appendChild(pattern);
    }
  }

  /** A Casama chat in a look's colors, fonts and background. */
  function chat(look, opts) {
    opts = opts || {};
    var dark = !!opts.dark;
    var c = scheme(look.scheme, dark);
    ensureFonts([look.headingFont, look.bodyFont]);
    var frame = el("div", "cg-frame");
    frame.setAttribute("data-ui", "");
    frame.style.setProperty("--ar", opts.aspect || "4 / 3");
    var screen = el("div", "cg-screen");
    var bot = dark ? c.high : c.lowest;
    setVars(screen, {
      "--surf": c.surf, "--on-surf": c.onSurf, "--on-surf-var": c.onSurfVar, "--p": c.p, "--on-p": c.onP,
      "--bot": bot, "--me": mix(bot, c.p, dark ? 0.32 : 0.18), "--field": dark ? c.cont : c.lowest,
      "--outline": c.outline + "99", "--heading-font": "'" + look.headingFont + "'", "--body-font": "'" + look.bodyFont + "'",
    });
    background(screen, look.wallpaper, c, dark, { item: look.item, thumb: opts.thumb });
    var ui = el("div", "cg-ui");
    var head = el("div", "cg-head");
    var av = el("span", "cg-av");
    av.appendChild(icon("cloud", { stroke: 2.2 }));
    head.appendChild(av);
    head.appendChild(el("span", "cg-name", "Casama"));
    ui.appendChild(head);
    ui.appendChild(el("div", "cg-spacer"));
    ui.appendChild(el("div", "cg-b cg-me", "Can you tidy up my notes?"));
    ui.appendChild(el("div", "cg-b cg-bot", "Done! They are in three folders now."));
    var comp = el("div", "cg-comp");
    comp.appendChild(el("span", "cg-field", "Message"));
    var send = el("span", "cg-send");
    send.appendChild(icon("arrow-up", { stroke: 2.4 }));
    comp.appendChild(send);
    ui.appendChild(comp);
    screen.appendChild(ui);
    frame.appendChild(screen);
    frame.setAttribute("role", "img");
    frame.setAttribute("aria-label", opts.label || "A Casama chat in this look");
    return frame;
  }

  /** A color scheme as fields of its colors. */
  function swatch(seeds, opts) {
    opts = opts || {};
    var c = scheme(seeds, !!opts.dark);
    var font = opts.font || DEFAULT_LOOK.headingFont;
    ensureFonts([font]);
    var frame = el("div", "cg-frame");
    frame.setAttribute("data-ui", "");
    frame.style.setProperty("--ar", opts.aspect || "4 / 3");
    frame.style.setProperty("--heading-font", "'" + font + "'");
    var grid = el("div", "cg-swatch");
    [[c.p, c.onP], [c.pc, c.onPc], [c.s, c.onS], [c.t, c.onT], [c.surf, c.onSurf]].forEach(function (pair) {
      var cell = el("span", null, "Aa");
      cell.style.background = pair[0];
      cell.style.color = pair[1];
      grid.appendChild(cell);
    });
    frame.appendChild(grid);
    frame.setAttribute("role", "img");
    frame.setAttribute("aria-label", opts.label || "Colors of this scheme");
    return frame;
  }

  /** A wallpaper on its own, phone-shaped. */
  function wallpaper(item, opts) {
    opts = opts || {};
    var dark = !!opts.dark;
    var c = scheme(null, dark);
    var frame = el("div", "cg-frame");
    frame.setAttribute("data-ui", "");
    frame.style.setProperty("--ar", opts.aspect || "3 / 4");
    var screen = el("div", "cg-screen");
    setVars(screen, { "--surf": c.surf });
    background(screen, wallpaperOf(item), c, dark, { item: item, thumb: true, sharp: true, portrait: true });
    frame.appendChild(screen);
    frame.setAttribute("role", "img");
    frame.setAttribute("aria-label", opts.label || item.name);
    return frame;
  }

  /** The picture for any item: a chat for themes, fields for schemes, the wallpaper, or null. */
  function preview(item, opts) {
    opts = opts || {};
    if (item.type === "theme") return chat(lookOf(item), opts);
    if (item.type === "scheme") return opts.chat ? chat(lookOf(item, { alone: false }), opts) : swatch(item.document, opts);
    if (item.type === "wallpaper") return opts.chat ? chat(lookOf(item), opts) : wallpaper(item, opts);
    return null;
  }

  function describeWallpaper(doc) {
    if (!doc) return "";
    if (doc.kind === "image") return "Image";
    return (PATTERN_LABELS[doc.pattern] || doc.pattern) + " on " + (PALETTE_LABELS[doc.palette] || doc.palette);
  }

  window.CasamaGallery = {
    HOST: HOST,
    icon: icon,
    scheme: scheme,
    lookOf: lookOf,
    chat: chat,
    swatch: swatch,
    wallpaper: wallpaper,
    preview: preview,
    ensureFonts: ensureFonts,
    describeWallpaper: describeWallpaper,
    appLink: function (item) { return "https://casama.ai/gallery/" + item.type + "/" + item.id; },
    sourceLink: function (item) { return "https://github.com/stackwares/casama-gallery/tree/main/" + item.type + "s/" + item.id; },
  };
})();
