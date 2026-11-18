#!/usr/bin/env node
// Local relay to the egress proxy for apps that can't send proxy credentials themselves, such as
// the desktop's Chromium (it would show a "proxy requires a username and password" dialog).
// Listens on 127.0.0.1 only, adds Proxy-Authorization from the computer's own environment, and
// forwards to the egress proxy. Every process here can already read these credentials, so the
// relay hands out nothing new; the egress proxy still applies its rules to everything.
import net from "node:net";

const upstream = new URL(process.env.AGENT_BROWSER_PROXY || "http://casama-egress:3128");
const user = process.env.AGENT_BROWSER_PROXY_USERNAME || "";
const pass = process.env.AGENT_BROWSER_PROXY_PASSWORD || "";
const port = Number(process.env.CASAMA_PROXY_RELAY_PORT || 3130);
const auth = `Proxy-Authorization: Basic ${Buffer.from(`${user}:${pass}`).toString("base64")}\r\n`;
const MAX_HEAD = 64 * 1024;

net
  .createServer((client) => {
    let head = Buffer.alloc(0);
    const onData = (chunk) => {
      head = Buffer.concat([head, chunk]);
      const end = head.indexOf("\r\n\r\n");
      if (end < 0) {
        if (head.length > MAX_HEAD) client.destroy();
        return;
      }
      client.off("data", onData);
      client.pause();
      const lines = head.subarray(0, end).toString("latin1").split("\r\n");
      const rest = head.subarray(end + 4);
      const connect = /^CONNECT /i.test(lines[0] ?? "");
      // Drop any credentials the app sent; plain-HTTP requests get one connection each, so every
      // request carries the header (a reused connection would reach the proxy without it).
      const headers = lines
        .slice(1)
        .filter((l) => !/^(proxy-authorization|proxy-connection|connection):/i.test(l));
      if (!connect) headers.push("Connection: close");
      const request = `${lines[0]}\r\n${auth}${headers.map((l) => `${l}\r\n`).join("")}\r\n`;
      const up = net.connect(Number(upstream.port || 3128), upstream.hostname, () => {
        up.write(request, "latin1");
        if (rest.length) up.write(rest);
        client.pipe(up);
        up.pipe(client);
        client.resume();
      });
      up.on("error", () => client.destroy());
      client.on("error", () => up.destroy());
      client.on("close", () => up.destroy());
      up.on("close", () => client.destroy());
    };
    client.on("data", onData);
    client.on("error", () => {});
  })
  .listen(port, "127.0.0.1");
