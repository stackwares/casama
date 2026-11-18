// k6 load test (SPEC "Testing: Load"): 200 bots waking at once (signed webhooks fired together),
// then 100 concurrent chat streams (message + SSE until the run ends). Time to first token is read
// from Postgres afterwards (load/report.ts), so it includes queueing in the worker.
//   k6 run -e DATA=/tmp/casama-load.json load/k6.js
import { check } from "k6";
import crypto from "k6/crypto";
import exec from "k6/execution";
import http from "k6/http";

const data = JSON.parse(open(__ENV.DATA || "/tmp/casama-load.json"));

export const options = {
  scenarios: {
    wake: {
      executor: "per-vu-iterations",
      exec: "wake",
      vus: data.wake.length,
      iterations: 1,
      maxDuration: "2m",
    },
    chat: {
      executor: "per-vu-iterations",
      exec: "chat",
      vus: data.chat.length,
      iterations: 1,
      startTime: "45s",
      maxDuration: "3m",
    },
  },
  thresholds: {
    "checks{scenario:wake}": ["rate==1"],
    "checks{scenario:chat}": ["rate>0.99"],
    "http_req_duration{scenario:wake}": ["p(95)<1000"],
  },
};

export function wake() {
  const i = exec.scenario.iterationInTest;
  const w = data.wake[i];
  const body = JSON.stringify({ event: "load", n: i });
  const sig = `sha256=${crypto.hmac("sha256", w.secret, body, "hex")}`;
  const res = http.post(`${data.api}/hooks/custom/${w.routine_id}`, body, {
    headers: { "content-type": "application/json", "x-casama-signature": sig },
  });
  check(res, { "webhook accepted": (r) => r.status === 202 });
}

export function chat() {
  const c = data.chat[exec.scenario.iterationInTest];
  const auth = { authorization: `Bearer ${data.token}`, "content-type": "application/json" };
  const sent = http.post(
    `${data.api}/v1/conversations/${c.conversation_id}/messages`,
    JSON.stringify({ text: "Hello there" }),
    {
      headers: auth,
    },
  );
  if (!check(sent, { "message sent": (r) => r.status === 201 || r.status === 202 })) return;
  const runId = sent.json("run_id");
  const stream = http.get(`${data.api}/v1/runs/${runId}/events`, {
    headers: { ...auth, accept: "text/event-stream" },
    timeout: "120s",
    tags: { name: "run events (SSE)" },
  });
  check(stream, {
    "stream ended with the run": (r) => r.status === 200 && /run\.(completed|failed)/.test(r.body),
    "assistant text streamed": (r) => r.body.includes("message.delta"),
  });
}
