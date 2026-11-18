/** Plays read-aloud audio for the panel and the service worker (A11). */
let audio: HTMLAudioElement | null = null;
let url: string | null = null;

function stop() {
  audio?.pause();
  if (url) URL.revokeObjectURL(url);
  audio = null;
  url = null;
}

chrome.runtime.onMessage.addListener(
  (m: { target?: string; type?: string; data?: string; mime?: string }) => {
    if (m?.target !== "offscreen") return;
    if (m.type === "stop") stop();
    if (m.type === "play" && m.data) {
      stop();
      const bin = atob(m.data);
      const bytes = new Uint8Array(bin.length);
      for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
      url = URL.createObjectURL(new Blob([bytes], { type: m.mime || "audio/mpeg" }));
      audio = new Audio(url);
      audio.addEventListener("ended", stop);
      void audio.play();
    }
  },
);
