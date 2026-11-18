import DefaultTheme from "vitepress/theme";
import { h } from "vue";
import BrandMark from "./BrandMark.vue";
import FaqFilter from "./FaqFilter.vue";
import NotFound from "./NotFound.vue";
import PageActions from "./PageActions.vue";
import "./custom.css";

// The Casama mark is the animated mascot (BrandMark), not a picture: in the nav bar and on the home hero.
// Every docs page also gets PageActions: copy it as markdown or open it in an AI chat. A missing page
// gets NotFound, the painted lost scene shared with the other sites.
/**
 * One anonymous page-view count per page (D-398), posted to casama.ai's counter, which forwards it to
 * Google Analytics from the server: no cookie and no Google script on the docs. Only on docs.casama.ai.
 */
function countPageView() {
  try {
    if (!navigator.sendBeacon || location.hostname !== "docs.casama.ai") return;
    let from = "";
    try {
      from = document.referrer ? new URL(document.referrer).hostname : "";
    } catch {
      from = "";
    }
    const utm = new URLSearchParams(location.search).get("utm_source") || "";
    navigator.sendBeacon(
      "https://casama.ai/b",
      JSON.stringify({ h: "docs", p: location.pathname, r: from, u: utm }),
    );
  } catch {
    // Counting is never worth breaking the page for.
  }
}

/**
 * Casama Help, the support chat that answers from these docs: casama.ai's loader draws a small
 * "? Questions" button and fetches the chat on the first click. Only in the browser; on localhost
 * the loader talks to the local stack's API.
 */
function addCasamaHelp() {
  if (document.querySelector("script[data-casama-help]")) return;
  const script = document.createElement("script");
  // scripts/serve-web.py turns this address into the local casama.ai.
  script.src = "https://casama.ai/assets/support/loader.js";
  script.async = true;
  script.dataset.casamaHelp = "";
  script.dataset.surface = "docs";
  document.body.appendChild(script);
}

/**
 * In the docs search (VitePress's local search), a last row: "Ask Casama Help about “query”". Watches
 * for the search box; if VitePress ever changes its markup and the box isn't found, nothing happens.
 */
function watchSearch() {
  let row: HTMLButtonElement | null = null;
  let input: HTMLInputElement | null = null;
  const update = () => {
    if (!row || !input) return;
    const q = input.value.trim();
    row.hidden = !q;
    const label = row.querySelector("span");
    if (label) label.textContent = q.length > 80 ? `${q.slice(0, 80)}…` : q;
  };
  const attach = () => {
    const box = document.querySelector(".VPLocalSearchBox");
    const shell = box?.querySelector(".shell");
    const field = box?.querySelector<HTMLInputElement>("input.search-input, input");
    if (!box || !shell || !field) {
      row = null;
      input = null;
      return;
    }
    if (row && shell.contains(row) && input === field) return;
    input = field;
    row = document.createElement("button");
    row.type = "button";
    row.className = "casama-help-search-row";
    row.innerHTML = "Ask Casama Help about “<span></span>”";
    row.addEventListener("click", () => {
      const text = (input?.value ?? "").trim().slice(0, 1000);
      // Close the search (it listens for Escape) before the chat opens.
      window.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true }));
      const help = (window as unknown as { CasamaHelp?: { open: (o: { text: string }) => void } })
        .CasamaHelp;
      if (help) setTimeout(() => help.open({ text }), 50);
      else window.location.href = `https://casama.ai/help?q=${encodeURIComponent(text)}`;
    });
    shell.appendChild(row);
    field.addEventListener("input", update);
    update();
  };
  let queued = false;
  new MutationObserver(() => {
    if (queued) return;
    queued = true;
    requestAnimationFrame(() => {
      queued = false;
      attach();
    });
  }).observe(document.body, { childList: true, subtree: true });
}

export default {
  extends: DefaultTheme,
  enhanceApp({ router }) {
    if (typeof window === "undefined") return;
    countPageView();
    try {
      addCasamaHelp();
      watchSearch();
    } catch {
      // The help chat is never worth breaking the docs for.
    }
    const previous = router.onAfterRouteChange;
    router.onAfterRouteChange = async (to) => {
      await previous?.(to);
      countPageView();
    };
  },
  Layout() {
    return h(DefaultTheme.Layout, null, {
      "nav-bar-title-before": () => h(BrandMark, { class: "casama-mark-nav" }),
      "home-hero-image": () => h(BrandMark, { class: "image-src casama-mark-hero" }),
      "doc-before": () => [h(PageActions), h(FaqFilter)],
      "not-found": () => h(NotFound),
    });
  },
};
