/**
 * casama.link (D-317). Sends www to the bare domain and serves the page's files.
 *
 * Never set a cookie here. Until casama.link is on the Public Suffix List, a cookie for
 * ".casama.link" would reach every Casama Link address, which are other people's servers.
 */
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.hostname !== "casama.link") {
      url.hostname = "casama.link";
      url.protocol = "https:";
      return Response.redirect(url.toString(), 301);
    }
    return env.ASSETS.fetch(request);
  },
};
