import { EgressProxy } from "./proxy.ts";

const controlToken = process.env.EGRESS_CONTROL_TOKEN;
if (!controlToken || controlToken.length < 16)
  throw new Error("EGRESS_CONTROL_TOKEN (16+ characters) is required");
const proxy = new EgressProxy({
  controlToken,
  blockedCidrs: (process.env.EGRESS_BLOCKED_CIDRS ?? "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean),
  log: (e) => process.stdout.write(`${JSON.stringify({ ts: new Date().toISOString(), ...e })}\n`),
  // Kasama Cloud (D-094): EGRESS_ABUSE_URL is the API's /internal/abuse; its token is INTERNAL_TOKEN.
  abuse:
    process.env.EGRESS_ABUSE === "on"
      ? {
          report: (computer, kind, target) => {
            const url = process.env.EGRESS_ABUSE_URL;
            if (!url) return;
            fetch(url, {
              method: "POST",
              headers: {
                "content-type": "application/json",
                "x-kasama-internal": process.env.EGRESS_ABUSE_TOKEN ?? "",
              },
              body: JSON.stringify({ computer, kind, target }),
              signal: AbortSignal.timeout(5_000),
            }).catch(() => {});
          },
        }
      : undefined,
});
const proxyPort = Number(process.env.EGRESS_PROXY_PORT ?? 3128);
const controlPort = Number(process.env.EGRESS_CONTROL_PORT ?? 3129);
proxy
  .createProxyServer()
  .listen(proxyPort, "0.0.0.0", () => console.log(`egress proxy on :${proxyPort}`));
proxy
  .createControlServer()
  .listen(controlPort, "0.0.0.0", () => console.log(`egress control on :${controlPort}`));
for (const s of ["SIGTERM", "SIGINT"] as const) process.once(s, () => process.exit(0));
