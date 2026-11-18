/**
 * Read aloud (A11): audio plays in an offscreen document, so it keeps playing when the panel
 * closes and the service worker can start it too. Firefox has no offscreen documents: there it
 * plays in the page that asked (the sidebar, or the background page, which has a DOM there).
 */
const PATH = "offscreen/offscreen.html";

let here: HTMLAudioElement | null = null;
function playHere(bytes: ArrayBuffer, mime: string) {
  stopHere();
  here = new Audio(URL.createObjectURL(new Blob([bytes], { type: mime })));
  return here.play();
}
function stopHere() {
  if (!here) return;
  here.pause();
  URL.revokeObjectURL(here.src);
  here = null;
}

async function ensureOffscreen() {
  const url = chrome.runtime.getURL(PATH);
  const have = await chrome.runtime.getContexts?.({
    contextTypes: ["OFFSCREEN_DOCUMENT" as chrome.runtime.ContextType],
    documentUrls: [url],
  });
  if (have?.length) return;
  await chrome.offscreen.createDocument({
    url: PATH,
    reasons: ["AUDIO_PLAYBACK" as chrome.offscreen.Reason],
    justification: "Reads a bot's reply aloud when the person asks.",
  });
}

export async function playAudio(bytes: ArrayBuffer, mime: string) {
  if (__CASAMA_BROWSER__ === "firefox" || !chrome.offscreen) return playHere(bytes, mime);
  await ensureOffscreen();
  const { toBase64 } = await import("./capture.ts");
  await chrome.runtime.sendMessage({
    target: "offscreen",
    type: "play",
    data: toBase64(new Uint8Array(bytes)),
    mime,
  });
}

export async function stopAudio() {
  stopHere();
  if (__CASAMA_BROWSER__ === "firefox" || !chrome.offscreen) return;
  await chrome.runtime.sendMessage({ target: "offscreen", type: "stop" }).catch(() => {});
}
