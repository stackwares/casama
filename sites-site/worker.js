/**
 * The sites zone's own page (docs/SITES-AND-DOMAINS-PLAN.md §7.11). Answers only the bare zone and
 * www; every <name>.<zone> is someone's site, served by Casama's pages server through the
 * casama-sites tunnel, and never passes through this worker.
 *
 * Never set a cookie here: until the zone is on the Public Suffix List, a cookie for the zone would
 * reach every site on it.
 */
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.hostname.startsWith("www.")) {
      url.hostname = url.hostname.slice(4);
      url.protocol = "https:";
      return Response.redirect(url.toString(), 301);
    }
    return env.ASSETS.fetch(request);
  },
};
