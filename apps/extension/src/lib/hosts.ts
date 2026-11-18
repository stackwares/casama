/** Addresses on this computer or its network, which a link's file is never fetched from. */
export function privateHost(url: string): boolean {
  try {
    const h = new URL(url).hostname.toLowerCase().replace(/^\[|\]$/g, "");
    return (
      h === "localhost" ||
      h.endsWith(".localhost") ||
      h.endsWith(".local") ||
      h.endsWith(".internal") ||
      /^(127\.|10\.|0\.|169\.254\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)/.test(h) ||
      h === "::1" ||
      (h.includes(":") && /^(f[cd][0-9a-f]{2}|fe80):/.test(h))
    );
  } catch {
    return true;
  }
}
