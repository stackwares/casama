# Trademark evidence: first use of "Casama"

A dated record of when Stackwares started using the name **Casama** in commerce. It's here for
the IPOPHL trademark filing (the application asks for the date of first use), and for any dispute
about the name before or after registration. Git commits are timestamped and can't be backdated
without it showing, so each entry names one where it can. The commit IDs refer to the full
development history, kept in the private repository `stackwares/casama-archive` (the original
repository, created on GitHub on 2026-11-09 and renamed on 2026-11-19 when the public history
restarted, D-405) and in an offline git bundle.

Not legal advice. Keep this file up to date and add new evidence as it happens.

## Status

- **Registered trademark:** none yet, so we use **Casama™** (never ®, which is only for registered
  marks; using it before registration is misleading and can count against us).
- **Mark to file:** the word "CASAMA" in plain letters (it covers every font and logo), and later
  the logo and mascots separately.
- **Classes to file first:** 42 (software as a service, hosted AI software) and 9 (downloadable
  software and apps). 35 and 38 can come later.
- **Owner:** Stackwares is a trade name, not a registered legal entity yet (2026-11-18). Until it
  is, the founder personally owns the copyright and the mark, and "Stackwares" means the founder
  doing business under that name. When a company is formed, assign the copyright, the mark and
  this evidence to it in writing, and record the assignment at IPOPHL/USPTO.
- **Priority:** file at IPOPHL first. The Paris Convention then gives 6 months to file in the US
  and other countries with the Philippine filing date (directly, or through the Madrid Protocol
  from IPOPHL).

## Known conflicts to check before filing

- **The App Store name "Casama" is taken by another developer.** Our App Store record had to be
  named "Casama AI" (`casama-store-setup` notes, 2026-11-11). Find out what that app is, who
  publishes it and in which country, and whether they hold a registration.
- Search, for free, before paying any fee:
  - IPOPHL: <https://www3.wipo.int/branddb/ph/en/> (the Philippine trademark database)
  - WIPO Global Brand Database: <https://branddb.wipo.int> (most countries, Madrid filings)
  - USPTO: <https://tmsearch.uspto.gov>
  - EUIPO: <https://www.tmdn.org/tmview/>
- "Kasama" (the former working name) is an everyday Filipino word ("companion"), so it is weak as
  a mark and isn't worth claiming.

## Timeline

| Date (UTC+8 unless noted) | Evidence | Where to verify |
|---|---|---|
| 2026-11-09 | First commit of the project (then named Kasama); GitHub repo `stackwares/casama` (now `casama-archive`) created 11:31 UTC | archive `git log` 49a6ca66; GitHub API `createdAt` of `casama-archive` |
| 2026-11-10 | Website and open-source launch prep | `git log` 2a63416e |
| 2026-11-11 | **Renamed to Casama, on casama.ai** (D-170): product, packages `@casama/*`, CLI `casama`, app id `ai.casama.app`, deep links `casama://` | `git log` 5a040120; `docs/DECISIONS.md` D-170 |
| 2026-11-11 | App records created: Google Play "Casama" (`ai.casama.app`), App Store "Casama AI" (id 6833509960) | Play Console, App Store Connect |
| 2026-11-12 | Production server set up; Casama Cloud serving users at api.casama.ai | D-199 |
| 2026-11-13 | First public release: Casama CLI 0.1.0 on GitHub | <https://github.com/stackwares/casama/releases/tag/cli-v0.1.0> |
| 2026-11-13 | Paid plans priced under the Casama name (Plus, Pro, Max) | D-249 |
| 2026-11-14 | casama.link domain registered | WHOIS creation date |
| 2026-11-15 | npm packages under `@casama/*` published | `npm view @casama/client time.created` |
| 2026-11-15 | Purchases live in the stores through RevenueCat | D-297 |
| 2026-11-17 | Builds on Google Play internal testing and TestFlight | D-331 |
| 2026-11-18 | "Casama™" marking added to casama.ai, casama.link, casama.page and the README | this commit |

## To add (needs Oliver's accounts)

- [ ] casama.ai registration date from Cloudflare Registrar (Dashboard → Domain Registration).
      Public WHOIS for `.ai` only shows the registry, not our date.
- [ ] casama.page registration date (Name.com, D-329).
- [ ] Date of the **first paying customer** and the first invoice (Dodo / RevenueCat). This is
      the strongest "use in commerce" evidence.
- [ ] First public posts that name Casama (social media, awesome-list submissions, launch posts),
      with links.
- [ ] DTI business name registration for "Casama" (bnrs.dti.gov.ph), certificate number and date.
- [ ] Internet Archive snapshots: save casama.ai, app.casama.ai, the GitHub repo and both store
      listings at <https://web.archive.org/save> and list the snapshot links here.
- [ ] Screenshots of the store listings and the website as they look today, saved with the date
      in the file name (keep them outside the repo, for example in Google Drive).
