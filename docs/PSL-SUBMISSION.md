# Public Suffix List submission (sites zone)

Prepared for D-329 (`docs/SITES-AND-DOMAINS-PLAN.md` §2.5, §14 #9). **Oliver sends it**, once the
sites zone has a few thousand live sites. Nothing here has been sent.

Why: browsers and block lists (Safe Browsing) treat every host under a registrable domain as one
site. On the list, each `<name>.<zone>` is its own site: one bad site can't get the whole zone
flagged, and cookies can't be shared between sites.

## Before sending

1. The zone is registered at least two years ahead (the list asks for more than two years left;
   buy it for three or more).
2. There are a few thousand distinct users with live sites. The list's rule is "a minimum of 2000 -
   3000 distinct users"; entries meant to dodge rate limits are refused. Check:
   `select count(distinct s.created_by) from sites s join site_hosts h on h.page_id = s.page_id where h.kind = 'address' and h.status = 'active';`
3. Add the proof record at the zone's DNS (Cloudflare), with the pull request's URL once it's open:

   ```
   _psl.<zone>.  TXT  "https://github.com/publicsuffix/list/pull/<number>"
   ```

## The entry

In `public_suffix_list.dat`, private section, sorted by organisation name:

```
// Casama : https://casama.ai
// Submitted by Casama <security@casama.ai>
<zone>
```

The entry is the zone itself (`<zone>`, not `*.<zone>`): every `<name>.<zone>` becomes its own
registrable domain, and the zone's own page stays one site.

## The pull request text

> **Organisation:** Casama (https://casama.ai), open-source AI teammates; sites are pages people's
> bots build, published at `<name>.<zone>`.
>
> **Reason for inclusion:** each `<name>.<zone>` is a different person's site, served on its own
> origin. We'd like browsers and reputation lists to treat them as separate sites, so one
> person's site can't affect another's standing or read another's cookies. This isn't to get
> around certificate or rate limits: certificates are issued per host through Cloudflare.
>
> **DNS verification:** `dig +short TXT _psl.<zone>` answers this pull request's URL.
>
> **Registration:** `<zone>` is registered until `<date>` (more than two years ahead).
>
> **Users:** about `<number>` people have live sites under the zone.
>
> **Abuse contact:** abuse@casama.ai. Sites carry a Report link; three reports from different
> people take a site down until someone checks it.

## After it merges

Browsers pick up the list with their next releases, which takes months. Nothing changes in
Casama's code: sites are already served on their own origins with no shared cookies.
