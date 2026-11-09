import { createHmac } from "node:crypto";

/** A WebRTC ICE server entry (RTCIceServer). */
export interface IceServer {
  urls: string[];
  username?: string;
  credential?: string;
}

/**
 * Short-lived TURN credentials in coturn's REST API scheme (`use-auth-secret`):
 * username = "<expiry unix seconds>:<id>", credential = base64(HMAC-SHA1(secret, username)).
 */
export function turnCredentials(secret: string, id: string, ttlS: number, now = Date.now()) {
  const username = `${Math.floor(now / 1000) + ttlS}:${id}`;
  const credential = createHmac("sha1", secret).update(username).digest("base64");
  return { username, credential };
}

/** TURN over UDP and TCP on one host:port (and TURNS when a TLS port is given). */
export function turnIceServer(
  host: string,
  port: number,
  creds: { username: string; credential: string },
  tlsPort?: number,
): IceServer {
  return {
    urls: [
      `turn:${host}:${port}?transport=udp`,
      `turn:${host}:${port}?transport=tcp`,
      ...(tlsPort ? [`turns:${host}:${tlsPort}?transport=tcp`] : []),
    ],
    ...creds,
  };
}
