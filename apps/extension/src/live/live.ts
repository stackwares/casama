/** The pop-out live view of a bot's cloud computer (D-323 D10). */
import { h } from "../lib/dom.ts";
import { LiveView } from "../lib/live-view.ts";
import { appUrl, here } from "../lib/workspace.ts";

const app = document.getElementById("app") as HTMLElement;
const q = new URLSearchParams(location.search);
const id = q.get("computer") ?? "";
const name = q.get("name") ?? "Computer";

async function main() {
  const w = await here().catch(() => null);
  if (!w || !id) {
    app.replaceChildren(h("p", {}, "Sign in to Casama to watch."));
    return;
  }
  document.title = `${name}: live view`;
  const status = h("span", { className: "muted", "data-testid": "live-status" }, "Connecting…");
  const img = h("img", { alt: `${name}'s screen`, "data-testid": "live-img" }) as HTMLImageElement;
  app.replaceChildren(
    h(
      "header",
      {},
      h("h1", {}, name),
      status,
      h(
        "a",
        { href: appUrl(w.account, `/computer/live?c=${id}`), target: "_blank", rel: "noopener" },
        "Take over in Casama",
      ),
    ),
    img,
  );
  const view = new LiveView({
    account: w.account,
    api: w.api,
    computerId: id,
    img,
    status: (t) => {
      status.textContent = t;
    },
  });
  addEventListener("pagehide", () => view.stop());
  await view.start().catch((e) => {
    status.textContent = (e as Error).message;
  });
}
void main();
