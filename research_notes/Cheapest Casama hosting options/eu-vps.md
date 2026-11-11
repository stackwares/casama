# EU VPS list prices for a Casama Docker Compose host

Checked 11 November 2026. Prices below are what the vendors’ own pages, price files, or public order catalogs returned that day. Amounts are EUR. Where a page is dated before October 2026, that date is marked stale even if the page is still online.

Target sizes: about 4 vCPU / 8 GB, and 8 vCPU / 16 GB. Several vendors do not sell those exact pairs; the nearest advertised plans are listed and the mismatch is stated.

## Exact current monthly price, vCPU, RAM, disk, included traffic, IPv4 fee, and backup or snapshot price

### Takeaway

On 11 November 2026 the orderable EU plans that match both target sizes are Hetzner CPX32 and CPX42 (shared AMD, Germany about €35.49 and €69.49 per month excluding VAT and excluding the €0.50 IPv4) and Netcup VPS 1000 G12.5 and VPS 2000 G12.5 (4/8 and 8/16). Hetzner’s whole CX and CAX matrix is marked not available on the storefront. Contabo, OVHcloud’s advertised VPS 2027 range, and Hostinger do not sell an 8 vCPU / 16 GB plan; their nearest larger plans are 8 vCPU / 24 GB, 8 vCPU / 24 GB, and 8 vCPU / 32 GB.

### Cited Findings

#### Hetzner Cloud, EU (Falkenstein FSN1, Nuremberg NBG1, Helsinki HEL1)

Server prices are the monthly cap and hourly rate in Hetzner’s live price file, excluding VAT and excluding the separate primary IPv4 product. Specs and availability badges are from the product pages. Checked 11 November 2026.

Regular Performance, shared AMD, NVMe, product page [hetzner.com/cloud/regular-performance](https://www.hetzner.com/cloud/regular-performance/). These CPX plans did not carry the storefront `not-available` class.

- CPX32, product `CLOUD_143`: 4 AMD vCPU, 8 GB RAM, 160 GB NVMe. FSN1 and NBG1 €35.49 per month (€0.0569 per hour). HEL1 €29.99 per month (€0.0481 per hour). — [live price file](https://www.hetzner.com/_resources/app/data/app/live_data_prices.json); specs [regular-performance](https://www.hetzner.com/cloud/regular-performance/)
- CPX42, product `CLOUD_144`: 8 AMD vCPU, 16 GB RAM, 320 GB NVMe. FSN1 and NBG1 €69.49 per month (€0.1114 per hour). HEL1 €58.99 per month (€0.0945 per hour). — [live price file](https://www.hetzner.com/_resources/app/data/app/live_data_prices.json); specs [regular-performance](https://www.hetzner.com/cloud/regular-performance/)
- The same page’s price widget is keyed `CLOUD_144+CLOUD_21` and its fallback text shows a “from” monthly price of €59.49 excluding VAT for CPX42. That equals the Helsinki server cap €58.99 plus the €0.50 IPv4. A rendered location line on the same page showed NBG1 at €69.99 excluding VAT, which equals the Germany server cap €69.49 plus €0.50. — [regular-performance](https://www.hetzner.com/cloud/regular-performance/)
- Included traffic on that page: cloud servers in the EU include at least 20 TB. The tooltip says each additional TB at EU-Central locations is charged the `CLOUD_66` price. `CLOUD_66` in the price file is €1.00 for location `ALL` (and €7.40 in Singapore), stored in the hourly field. The widget’s hidden label renders that field as “€ 1.00 per hour, excl. VAT”, while the sentence says the charge is per additional TB. — [regular-performance](https://www.hetzner.com/cloud/regular-performance/); [live price file](https://www.hetzner.com/_resources/app/data/app/live_data_prices.json)
- Primary IPv4, product `CLOUD_21`: €0.50 per month and €0.0008 per hour, excluding VAT, location `ALL`. — [live price file](https://www.hetzner.com/_resources/app/data/app/live_data_prices.json). The docs page states the same €0.50 excluding VAT for Cloud Primary IPv4 and €0 for Cloud Primary IPv6, and €3.00 per month for a Cloud Floating IPv4. That docs page says “Last change on 2023-04-13”, which is stale relative to October 2026, but the 11 November 2026 price file still has €0.50. — [IPv4 pricing](https://docs.hetzner.com/general/infrastructure-and-availability/ipv4-pricing/); [server overview](https://docs.hetzner.com/cloud/servers/overview/)
- Snapshots on the regular-performance page: “Snapshots per GB per month € 0.0143, excl. VAT”. Product `CLOUD_24` in the price file is €0.0143 in the hourly field for location `ALL`. — [regular-performance](https://www.hetzner.com/cloud/regular-performance/); [live price file](https://www.hetzner.com/_resources/app/data/app/live_data_prices.json)
- Backups on that page: “mo. price related to instance, starting at: € 1.0980, excl. VAT”, with seven backup slots. The billing FAQ says backups are a monthly flat price of 20% of the server price, for seven slots, and that snapshots are billed per gigabyte of compressed data. That FAQ says “Last change on 2020-07-07”, so the 20% sentence is stale-dated. €1.0980 is 20% of €5.49, and €5.49 is the page’s “from” price for the cheapest CPX (CPX02 Helsinki €4.99 plus €0.50 IPv4). — [regular-performance](https://www.hetzner.com/cloud/regular-performance/); [billing FAQ](https://docs.hetzner.com/cloud/billing/faq/)
- The regular-performance FAQ says host systems have a redundant 10 Gbit/s connection shared by instances, with no bandwidth guarantee, and “you can expect about 300-500 Mbits.” — [regular-performance](https://www.hetzner.com/cloud/regular-performance/)
- EU cloud locations named on the cloud homepage: Falkenstein, Nuremberg, and Helsinki. — [hetzner.com/cloud](https://www.hetzner.com/cloud)

Cost-Optimized CX and CAX, [hetzner.com/cloud/cost-optimized](https://www.hetzner.com/cloud/cost-optimized/). Every plan in the matrix had the HTML class `not-available` on 11 November 2026. The price file still lists them `active: true`.

- CX33, `CLOUD_133`: 4 Intel/AMD vCPU, 8 GB, 80 GB NVMe. FSN1, NBG1, and HEL1 €8.49 per month (€0.0144 per hour). Marked not available. — [cost-optimized](https://www.hetzner.com/cloud/cost-optimized/); [live price file](https://www.hetzner.com/_resources/app/data/app/live_data_prices.json)
- CX43, `CLOUD_134`: 8 Intel/AMD vCPU, 16 GB, 160 GB NVMe. Same three EU locations €15.99 per month (€0.0256 per hour). Marked not available. — same two sources
- CAX21, `CLOUD_112`: 4 Ampere vCPU, 8 GB, 80 GB NVMe. €10.49 per month (€0.0168 per hour) in FSN1, NBG1, and HEL1. Marked not available. — same two sources
- CAX31, `CLOUD_113`: 8 Ampere vCPU, 16 GB, 160 GB NVMe. €20.99 per month (€0.0336 per hour) in those locations. Marked not available. — same two sources
- The same not-available class covered the rest of that matrix, including CX23 (2 vCPU / 4 GB / 40 GB, €5.49) and CAX11 (2 Ampere / 4 GB / 40 GB, €5.99). — [cost-optimized](https://www.hetzner.com/cloud/cost-optimized/)

Older CPX11, CPX21, CPX31, CPX41, and CPX51 keys (`CLOUD_121`, `CLOUD_123`, `CLOUD_125`, `CLOUD_127`, `CLOUD_129`) returned no FSN1, NBG1, or HEL1 rows in the price file. The regular-performance page still shows CPX31 (4 vCPU, 8 GB, 160 GB) “from” €62.99 excluding VAT on US locations HIL1 and ASH1. — [live price file](https://www.hetzner.com/_resources/app/data/app/live_data_prices.json); [regular-performance](https://www.hetzner.com/cloud/regular-performance/)

A secondary compilation dated 10 November 2026 lists the same Germany net caps for current CPX32 (€35.49) and CPX42 (€69.49), excluding VAT and excluding IPv4, with 20 TB and backups at 20%. — [cloudtally.eu/hetzner-cloud-prices](https://cloudtally.eu/hetzner-cloud-prices)

#### Netcup VPS G12.5

Product page [netcup.com/en/server/vps](https://www.netcup.com/en/server/vps), checked 11 November 2026. The page defaulted to the 12-month term and a “from” price.

Rendered cards, 12-month term. The bold figure is `product-group-card-price`. The second figure is `product-group-card-baseline-price` with a line-through. The VAT label sits in that block.

- VPS 1000 G12.5: 4 vCore x86, 8 GB RAM, 128 GB SSD, “Traffic included”, “Snapshots, Remote console & more”. Bold €14.50, struck-through €16.68, label “(incl. 19% VAT)”. — [VPS page](https://www.netcup.com/en/server/vps)
- VPS 2000 G12.5: 8 vCore x86, 16 GB RAM, 256 GB SSD, same traffic and snapshot line. Bold €26.92, struck-through €30.96, “(incl. 19% VAT)”. — [VPS page](https://www.netcup.com/en/server/vps)
- The page says a 12-month term saves relative to monthly billing and a 24-month term saves more, and the term control shows “12 months −13%” and “24 months −26%”. — [VPS page](https://www.netcup.com/en/server/vps)
- Locations you can select: Vienna (VIE), Nuremberg (NUE), Amsterdam (AMS), Manassas (MNZ), Singapore (SIN), plus “No preference Europe”. — [VPS page](https://www.netcup.com/en/server/vps)
- The page says prices may vary by country of residence under Directive 2006/112/EC and “Price incl. 19% VAT.” — [VPS page](https://www.netcup.com/en/server/vps)
- No separate IPv4 monthly fee, setup fee, or traffic-terabyte cap is printed on the plan cards. Network options listed in the FAQ on that page are “IPv4 and IPv6 connectivity”, “IPv6 connectivity”, and “Cloud vLAN only”. — [VPS page](https://www.netcup.com/en/server/vps)
- Local block storage on the same page is quoted three ways: “€0.01 per month” and “€0.014”, and “The price per GB is €0.012.” — [VPS page](https://www.netcup.com/en/server/vps)

The page’s embedded catalog (Nuxt payload on that same URL) has these monthly amounts for the “iv” SKUs. Amsterdam is `soldOut: true` at the Nuremberg/Vienna price. “EU” is the no-preference SKU and is cheaper. These payload numbers are not the bold card prices.

VPS 1000 G12.5 iv:

- 1 month: EU €13.51, NUE €15.61, VIE €15.61, AMS €15.61 sold out
- 12 months: EU €11.68, NUE €13.51, VIE €13.51, AMS €13.51 sold out
- 24 months: EU €9.85, NUE €11.41, VIE €11.41, AMS €11.41 sold out

VPS 2000 G12.5 iv:

- 1 month: EU €25.51, NUE €29.41, VIE €29.41, AMS €29.41 sold out
- 12 months: EU €22.12, NUE €25.51, VIE €25.51, AMS €25.51 sold out
- 24 months: EU €18.73, NUE €21.61, VIE €21.61, AMS €21.61 sold out

Source for the payload rows: the `__NUXT_DATA__` block of [netcup.com/en/server/vps](https://www.netcup.com/en/server/vps), read 11 November 2026.

#### Contabo Core / Cloud VPS

Page [contabo.com/en/vps](https://contabo.com/en/vps/), checked 11 November 2026. The page says the displayed price is the effective monthly rate for a 24-month subscription and that the lines shown are “for the first 24 months”. This fetch’s VAT toggle produced inclusive figures that are exactly 25% above the exclusive figures, so the inclusive column is the tax rate applied for that page view, not a universal EU VAT rate.

- Cloud VPS 4: 4 vCPU, 8 GB RAM, 100 GB SSD, 1 snapshot, 200 Mbit/s, “Unlimited Traffic”. Excluding VAT €4.40 per month, including VAT €5.50 per month, for the first 24 months. — [contabo.com/en/vps](https://contabo.com/en/vps/)
- Cloud VPS 6: 6 vCPU, 12 GB RAM, 200 GB SSD or 100 GB NVMe, 2 snapshots, 300 Mbit/s, unlimited traffic. Excluding VAT €6.00, including VAT €7.50. — [contabo.com/en/vps](https://contabo.com/en/vps/)
- Cloud VPS 8: 8 vCPU, 24 GB RAM, 300 GB SSD or 150 GB NVMe, 3 snapshots, 600 Mbit/s, unlimited traffic. Excluding VAT €11.20, including VAT €14.00. There is no 8 vCPU / 16 GB plan on this page. — [contabo.com/en/vps](https://contabo.com/en/vps/)
- Higher cards on the same page: Cloud VPS 12 is 12 vCPU / 48 GB at €20.00 excluding VAT; Cloud VPS 16 is 16 vCPU / 64 GB at €29.60 excluding VAT; Cloud VPS 18 is 18 vCPU / 96 GB at €39.20 excluding VAT. Same 24-month presentation. — [contabo.com/en/vps](https://contabo.com/en/vps/)
- Incoming traffic is unlimited and unmetered. Outgoing traffic is unlimited with a fair-use policy; Contabo “reserves the right to throttle servers with exceptionally high or disruptive usage patterns.” — [contabo.com/en/vps](https://contabo.com/en/vps/)
- “Dedicated IPv4 and IPv6 addresses come with every plan.” No separate IPv4 price is stated. — [contabo.com/en/vps](https://contabo.com/en/vps/)
- Snapshots are included in the counts above (1, 2, or 3). Auto Backup is described as a paid add-on. No euro price for Auto Backup or for extra snapshots is on the page. — [contabo.com/en/vps](https://contabo.com/en/vps/)
- “A one-time setup fee applies to new Cloud VPS 4 instances (monthly contracts only).” The page does not state the fee amount. “For longer contracts, no setup fees apply.” The other listed plans are marked “No Setup Fee”. — [contabo.com/en/vps](https://contabo.com/en/vps/)
- “Minimum initial contract length: 1 month. Minimum following contract length: Equal to the initial contract length.” — [contabo.com/en/vps](https://contabo.com/en/vps/)

An older naming scheme (Cloud VPS 10 / 20 / 30) still appears on third-party pages and on a Contabo US URL. Those pages were not used as the price source. The EU English product page above uses Cloud VPS 4 / 6 / 8.

#### OVHcloud VPS, Ireland storefront (EUR, excluding VAT)

Marketing page [ovhcloud.com/en-ie/vps](https://www.ovhcloud.com/en-ie/vps/) and the public order catalog `https://eu.api.ovh.com/1.0/order/catalog/public/vps?ovhSubsidiary=IE`, both read 11 November 2026. The catalog locale is EUR, subsidiary IE, tax rate 23. The Ireland page labels the same euro figures “ex. VAT”. Catalog prices below are the integer price divided by 100,000,000. Installation fees in the catalog for these plans are 0. The “From” price on the page matches the catalog `upfront12` monthly figure, not the no-commitment monthly figure.

Advertised range is “VPS 2027”. None of these four is 8 vCPU / 16 GB.

- VPS-1 2027 (`vps-2027-model1`): 2 vCores, 4 GB RAM, 40 GB NVMe, unlimited traffic, 500 Mbps, daily backup of the previous 24 hours. No-commitment €4.49 per month. 12-month €3.81 per month. — [Ireland VPS page](https://www.ovhcloud.com/en-ie/vps/); [IE catalog](https://eu.api.ovh.com/1.0/order/catalog/public/vps?ovhSubsidiary=IE)
- VPS-2 2027 (`vps-2027-model2`): 4 vCores, 8 GB RAM, 75 GB NVMe, unlimited traffic, 1 Gbps, daily backup. No-commitment €8.49 per month. 12-month €7.21 per month. This is the 4 vCPU / 8 GB plan. — same two sources
- VPS-3 2027 (`vps-2027-model3`): 6 vCores, 12 GB RAM, 100 GB NVMe, unlimited traffic, 2 Gbps, daily backup. No-commitment €12.24 per month. 12-month €10.40 per month. — same two sources
- VPS-4 2027 (`vps-2027-model4`): 8 vCores, 24 GB RAM, 200 GB NVMe, unlimited traffic, 3 Gbps, daily backup. No-commitment €23.49 per month. 12-month €19.96 per month. This is the nearest 8-vCPU plan, at 24 GB RAM rather than 16 GB. — same two sources
- “Dedicated IPv4” and IPv6 are included. — [Ireland VPS page](https://www.ovhcloud.com/en-ie/vps/)
- Standard automatic daily backup is included. Premium automatic backup is “From €1.10 ex. VAT/month”. Snapshots are “From €0.30 ex. VAT/month”. Those “from” prices are not broken out per plan. — [Ireland VPS page](https://www.ovhcloud.com/en-ie/vps/)
- Unlimited traffic on this page has a footnote that applies to Mumbai, Singapore, and Sydney only (500 GB, 1 TB, or 3 TB depending on plan, then 10 Mbps). It does not set a quota for European datacentre VPS. — [Ireland VPS page](https://www.ovhcloud.com/en-ie/vps/)

The same IE catalog still lists a VPS 2026 generation at no-commitment monthly prices of €6.49 (VPS-1), €9.99 (VPS-2), €19.99 (VPS-3), and €36.99 (VPS-4), with 12-month figures €5.52, €8.49, €16.99, and €31.44, and installation fees 0. The Ireland marketing page does not show this 2026 generation, and this pass did not extract 2026 vCPU, RAM, or disk from the catalog, so those four prices are catalog prices without confirmed 2026 specs. — [IE catalog](https://eu.api.ovh.com/1.0/order/catalog/public/vps?ovhSubsidiary=IE)

The catalog also contains plan codes whose names encode 8 vCPU and 16 GB, including `vps-elite-8-16-160` at a no-commitment monthly price of €44.00 excluding VAT. The 12-month price field on that family is on a different scale from the VPS 2027 `upfront12` field (it looks like a 12-month total rather than a monthly rate), so the commitment price is not restated here. Those elite plans are not on the VPS 2027 cards. — [IE catalog](https://eu.api.ovh.com/1.0/order/catalog/public/vps?ovhSubsidiary=IE)

#### Hostinger KVM VPS

German price page [hostinger.com/de/Preise/vps-hosting](https://www.hostinger.com/de/Preise/vps-hosting) and English page [hostinger.com/vps-hosting](https://www.hostinger.com/vps-hosting), both checked 11 November 2026. Both are a Black Friday promotion with the 24-month term selected. “All plans are paid upfront. The monthly rate reflects the total plan price divided by the number of months in your plan.” The German page does not say whether the euro amounts include VAT.

There is no 4 vCPU / 8 GB plan and no 8 vCPU / 16 GB plan. The German 24-month prices:

- KVM 1: 1 vCPU, 4 GB RAM, 50 GB NVMe, 4 TB bandwidth. Struck €17.99, promo €5.49 per month, €131.76 due for 24 months, renewal €11.99 per month for the same term. — [German VPS prices](https://www.hostinger.com/de/Preise/vps-hosting)
- KVM 2: 2 vCPU, 8 GB RAM, 100 GB NVMe, 8 TB. Struck €21.49, promo €7.79 per month, €186.96 due for 24 months, renewal €14.99 per month. This is the plan with 8 GB RAM; it has 2 vCPU, not 4. — [German VPS prices](https://www.hostinger.com/de/Preise/vps-hosting)
- KVM 4: 4 vCPU, 16 GB RAM, 200 GB NVMe, 16 TB. Struck €35.99, promo €10.99 per month, €263.76 due for 24 months, renewal €27.99 per month. This is 4 vCPU / 16 GB, not 8 vCPU / 16 GB. — [German VPS prices](https://www.hostinger.com/de/Preise/vps-hosting)
- KVM 8: 8 vCPU, 32 GB RAM, 400 GB NVMe, 32 TB. Struck €64.99, promo €21.99 per month, €527.76 due for 24 months, renewal €49.99 per month. This is the 8-vCPU plan, at 32 GB RAM. — [German VPS prices](https://www.hostinger.com/de/Preise/vps-hosting)

The struck price is the pre-discount reference for that 24-month presentation (the stated percent off matches struck versus promo). Renewal is a third figure and is lower than the struck price. 7.79 × 24 = 186.96, 10.99 × 24 = 263.76, and 21.99 × 24 = 527.76, matching the “today you pay” totals.

The English page the same day shows the promo in USD for the same specs: KVM 2 $8.79 per month ($210.96 for 24 months, renews at $14.99), KVM 4 $12.99 ($311.76, renews at $28.99), KVM 8 $25.99 ($623.76, renews at $49.99). — [hostinger.com/vps-hosting](https://www.hostinger.com/vps-hosting)

Other facts from the English page: free weekly backups; “1 Gbps network speed”; EU deploy locations “UK, Germany, France, and Lithuania”; “every KVM VPS client gets a dedicated IP address.” No separate IPv4 fee is stated. Reinstalling in another datacentre “permanently deletes all data, including backups and snapshots,” so snapshots exist, but no snapshot price is given. — [hostinger.com/vps-hosting](https://www.hostinger.com/vps-hosting)

### Inferences

- Hetzner’s orderable EU match for the budgeted CPX42 class is the Germany cap of €69.49 excluding VAT for the server, or about €69.99 excluding VAT once the €0.50 primary IPv4 is added. Helsinki is €58.99 plus €0.50. That sits in the project’s €59–70 band only after location and IPv4 are specified. The figure is the monthly cap, not a prepaid discount.
- Netcup’s rendered “from” prices equal `(cheapest EU payload price + €0.50) × 1.19`, rounded to the cent. For VPS 1000, (11.68 + 0.50) × 1.19 = 14.494, shown as €14.50, and (13.51 + 0.50) × 1.19 = 16.672, shown as the struck €16.68. The same identity holds for VPS 2000 (€26.92 and €30.96). The €0.50 addend is not labeled in the payload fields that were readable, so it is not recorded here as a confirmed IPv4 fee. The struck price matches the 1-month EU payload under that formula, and 14.50/16.68 is about 13% off, which matches the page’s “12 months −13%”.
- Applying that same unlabeled formula to the Nuremberg payload would put VPS 1000 at about €19.17 (1 month), €16.67 (12 months), and €14.17 (24 months) including 19% VAT, and VPS 2000 at about €35.59, €30.95, and €26.31. Those Nuremberg VAT-inclusive totals were not printed on the card; only the cheaper “from” EU card price was.
- Contabo Cloud VPS 4 is the 4 vCPU / 8 GB machine, at €4.40 excluding VAT per month on the 24-month presentation in this fetch. The 8 vCPU machine on that page has 24 GB RAM, at €11.20 excluding VAT. A month-to-month price was not on the rendered page.
- OVHcloud VPS-2 2027 is the 4 vCPU / 8 GB machine at €8.49 excluding VAT with no commitment, or €7.21 excluding VAT per month on a 12-month term. The 8-vCPU VPS-4 2027 has 24 GB RAM at €23.49 or €19.96.
- Hostinger’s 24-month promo prices are introductory. KVM 4’s renewal of €27.99 per month is more than double the €10.99 promo. The page does not show a 4 vCPU / 8 GB or 8 vCPU / 16 GB shape.

### Gaps

- Hetzner Finland overage per TB was not separated from the EU-Central €1.00 figure. Whether a partial hour is billed as a full hour was not on the FAQ text that was isolated. The customer-country VAT rate table was not extracted; published Hetzner prices are excluding VAT.
- Netcup: no numeric traffic cap, no hourly rate for G12.5, no setup fee, and no separate snapshot price beyond the feature line that snapshots are included. The three block-storage prices on one page (€0.01, €0.012, and €0.014 per GB) were not reconciled. Whether the payload amounts are net of VAT is inferred from the card math, not from a field labeled “excl. VAT”.
- Contabo: the VPS 4 monthly-contract setup fee has no amount. Auto Backup has no price. The price after the first 24 months was not on the page. No hourly rate was found. The 25% VAT in this fetch may be the tax of the fetching location rather than German 19% VAT.
- OVHcloud: the Germany subsidiary catalog was not compared with Ireland. Six-month commitment prices were present in the catalog and not extracted. VPS 2026 specs were not extracted. Elite 8-vCPU / 16 GB commitment prices were left out because the price-field unit did not match the VPS 2027 cards. Premium backup and snapshot prices are “from” prices only.
- Hostinger: 1-month and 12-month prices were not in the rendered 24-month view and are not taken from third-party tables. VAT inclusion on the German euro prices was not stated. Daily-backup and snapshot prices were not stated. No setup fee was stated.

## Docker, nested containers, outbound internet, nested virtualization, and SMTP

### Takeaway

All five sell a normal Linux VPS on which Docker is either a documented install path or an explicit recommendation. None of the VPS products document nested virtualization as available. Hetzner Cloud blocks outbound SMTP ports 25 and 465 by default. No vendor page found in this pass says that containers are denied outbound internet while the host is allowed it. A TURN relay using UDP was not covered by the port policies that were found, except where a general firewall or fair-use rule could be applied by the customer or the host.

### Cited Findings

- Hetzner publishes a Docker CE one-click app for Cloud servers and documents creating a server with image `docker-ce`. — [Docker CE docs](https://docs.hetzner.com/cloud/apps/list/docker-ce/), and the cloud homepage lists Docker among one-click apps — [hetzner.com/cloud](https://www.hetzner.com/cloud)
- Hetzner’s cloud server FAQ: “Can I run virtual machines on cloud servers, or rather is nested virtualization possible? No, this is not possible on cloud server.” The FAQ page says “Last change on 2024-09-12”, which is stale relative to October 2026; that answer was still the text on the live page fetched 11 November 2026. — [cloud server FAQ](https://docs.hetzner.com/cloud/servers/faq/)
- The same Hetzner FAQ: “we block ports 25 and 465 by default on all cloud servers.” It says this is to prevent abuse, and that after one month as a customer and a paid first invoice you can open a limit request to unblock those ports for a valid use case, decided case by case. — [cloud server FAQ](https://docs.hetzner.com/cloud/servers/faq/). A quotation of that same FAQ URL says port 587 is not blocked and can be used for external mail services without a limit request. That 587 sentence was not isolated in the stripped HTML of the direct fetch; it is cited here only as a quotation of the official FAQ. — [emailwiz issue quoting the FAQ](https://github.com/LukeSmithxyz/emailwiz/issues/317)
- Netcup’s server FAQ: the SVM flag for nested virtualization is disabled and cannot be activated. “We recommend container-based solutions such as Docker or Podman for the isolated execution of applications.” Any OS with KVM drivers can be used. The FAQ says “Last update: 2 March 2026”, which is stale relative to October 2026. — [netcup server FAQ](https://www.netcup.com/en/helpcenter/documentation/server/faq)
- Contabo’s VPS page says Core VPS is KVM, offers Linux distributions and custom images, and gives full root access. It does not mention a Docker ban. — [contabo.com/en/vps](https://contabo.com/en/vps/). Contabo’s support article: nested virtualization can be set up on Dedicated Servers and Virtual Dedicated Servers, and “You cannot set up nested virtualization with Contabo Virtual Private Servers (VPS).” The article has no visible revision date; it was fetched 11 November 2026. — [Contabo nested virtualization](https://help.contabo.com/en/support/solutions/articles/103000271595-can-i-setup-nested-virtualization-on-my-server-)
- OVHcloud’s VPS page says a datacentre VPS is an isolated virtual machine whose OS the customer manages, including Linux. It does not state a Docker ban for datacentre VPS. It does say a Local Zone VPS “only works with Linux; Windows, Plesk, cPanel, and Docker are not yet supported.” — [Ireland VPS page](https://www.ovhcloud.com/en-ie/vps/)
- Hostinger’s VPS page offers a “Docker and Traefik” template and a “Docker manager” for Docker Compose, and says full root access allows installing Docker. KVM is the virtualization on all VPS plans. — [hostinger.com/vps-hosting](https://www.hostinger.com/vps-hosting). Nested virtualization “is not supported on Hostinger Virtual Private Server (VPS) hosting plans.” The article’s schema `dateModified` is 29 October 2026. — [Hostinger nested virtualization](https://www.hostinger.com/support/10429687-is-nested-virtualization-supported-in-hostinger/)
- A secondary comparison, not a vendor page, says as of its writing that Contabo does not document an outbound port 25 block and sets a sending limit of about 25 emails per minute, that Hostinger’s help says port 25 is not blocked and is capped at 5 emails per minute, and that OVHcloud’s mail guide says port 25 is not blocked by default on VPS but can be blocked if spam is detected, and that Local Zone VPS cannot reach SMTP. Those claims were not re-fetched from the vendors’ own articles in this pass. — [vpsforlife.com port 25 comparison](https://vpsforlife.com/which-vps-providers-allow-port-25.php)

### Inferences

- Docker Compose on the host does not need nested virtualization. The nested-virtualization blocks above stop a hypervisor inside the VPS (KVM, Proxmox, Hyper-V). They do not, by themselves, stop Docker containers on the host. Netcup states that distinction by disabling SVM and recommending Docker or Podman.
- Containers that use the VPS network namespace or a bridge with NAT use the host’s outbound path. No page found here says the provider filters container egress differently from host egress. Hetzner’s SMTP block is on the cloud server, so it applies to mail sent from containers on that server as well.
- A TURN server that needs inbound UDP on the public IPv4 depends on the provider not filtering those UDP ports. That policy was not found for any of the five. Hetzner’s stated expectation of about 300–500 Mbit/s and Contabo’s port caps (200–600 Mbit/s on the plans above) are the only quantitative network limits tied to these plans.

### Gaps

- Official SMTP policy pages for Netcup, Contabo, OVHcloud datacentre VPS, and Hostinger were not fetched. The vpsforlife comparison is a secondary source only.
- No vendor statement was found on Docker-in-Docker, privileged containers, or UDP ports used by TURN.
- Whether Hetzner’s port 587 exception is still the current FAQ sentence was not confirmed by a clean extract on 11 November 2026; the 25 and 465 block was.

## Hourly versus monthly billing, VAT, and setup fees

### Takeaway

Hetzner bills hourly up to a monthly cap, with prices excluding VAT and no setup fee in the price file. OVHcloud VPS 2027 is monthly, with a lower monthly rate if 12 months are paid upfront, prices excluding VAT, and a zero installation fee. Netcup and Contabo sell fixed terms (1, 12, and 24 months at Netcup; the Contabo page’s headline rate is a 24-month term, with a 1-month minimum). Hostinger’s advertised rate is a 24-month prepay. Only Netcup’s card is explicitly labeled as including 19% VAT.

### Cited Findings

- Hetzner: “Servers have both a monthly price cap and a price per hour. Your server's bill will never exceed its monthly price cap. If you delete your Cloud Server before the end of the billing month, you will only be billed the hourly rate.” Servers are billed until deleted, including when they are not in use. The billing FAQ says the invoice uses the minimum of the monthly cap and the hourly amount. — [regular-performance FAQ](https://www.hetzner.com/cloud/regular-performance/); [billing FAQ](https://docs.hetzner.com/cloud/billing/faq/). The billing FAQ’s last change date is 2020-07-07 (stale). The hourly and monthly figures in the 11 November 2026 price file are the current numbers. — [live price file](https://www.hetzner.com/_resources/app/data/app/live_data_prices.json)
- Hetzner cloud server rows in that price file have no setup price. Product pages label prices “excl. VAT”. — [live price file](https://www.hetzner.com/_resources/app/data/app/live_data_prices.json); [regular-performance](https://www.hetzner.com/cloud/regular-performance/)
- Netcup G12.5 terms on the VPS page: minimum term of one, twelve, or 24 months, with the longer terms cheaper. The rendered default is 12 months. The card block is labeled “(incl. 19% VAT)”, and the page says prices can vary by country of residence. A product blurb in the page data says “hourly billing”, but no euro-per-hour figure for G12.5 was in the fields extracted. No setup fee is shown on the cards. — [netcup VPS](https://www.netcup.com/en/server/vps)
- Contabo: headline prices are the 24-month effective monthly rate. Minimum initial contract is 1 month, and the renewal term matches the initial term. Cancellation is none for prepay or 4 weeks for post-pay. A setup fee applies only to new Cloud VPS 4 on monthly contracts; the amount is not stated. Longer contracts have no setup fee. The VAT toggle in this fetch showed 25% on top of the excluding-VAT column. No hourly price was found. — [contabo.com/en/vps](https://contabo.com/en/vps/)
- OVHcloud IE catalog: VPS 2027 has a `default` monthly fee and an `upfront12` fee that the Ireland page shows as the lower “From … ex. VAT/month” price. Installation fees are 0. The catalog tax rate for subsidiary IE is 23, and the page prints prices excluding VAT. No hourly price was in the pricing rows extracted for VPS-1 through VPS-4 2027. — [Ireland VPS page](https://www.ovhcloud.com/en-ie/vps/); [IE catalog](https://eu.api.ovh.com/1.0/order/catalog/public/vps?ovhSubsidiary=IE)
- Hostinger: the German and English pages are prepaid term prices. The monthly figure is the term total divided by the number of months. The view that was captured is 24 months, with a separate renewal monthly price. No setup fee and no hourly rate were stated. The German page does not say “inkl. MwSt.” or “zzgl. MwSt.” in the price block that was extracted. The English page offers a 30-day money-back guarantee. — [German VPS prices](https://www.hostinger.com/de/Preise/vps-hosting); [English VPS page](https://www.hostinger.com/vps-hosting)

### Inferences

- A Hetzner server that runs all month costs the monthly cap, not 730 times the hourly rate. CPX42 in Germany is €0.1114 per hour excluding VAT, and 0.1114 × 730 is about €81, which is above the €69.49 cap, so the cap binds for an always-on machine. The same shape holds for CPX32 (€0.0569 × 730 is above €35.49).
- Comparing headline prices without the term and VAT basis mixes unlike numbers. Hetzner and OVHcloud Ireland are excluding VAT and, for Hetzner, hourly-with-a-cap. Netcup’s card is including 19% VAT on a 12-month term. Contabo’s €4.40 is excluding VAT on a 24-month term. Hostinger’s €7.79 and €10.99 are 24-month promo rates whose VAT treatment was not stated, and the renewal rates are €14.99 and €27.99.

### Gaps

- Hetzner’s VAT rate by customer country was not copied from a current tax page.
- Netcup’s hourly euro rate for G12.5, if it still exists, was not found.
- Contabo’s 1-month price, the numeric VPS 4 setup fee, and the price after 24 months were not on the page.
- OVHcloud prices for the German subsidiary, and any hourly VPS mode, were not confirmed.
- Hostinger 1-month and 12-month euro prices, and whether German prices include VAT, were not on the rendered 24-month module.

## Source URL and check date for every price

### Takeaway

Every euro figure in the findings above was taken on 11 November 2026 from a vendor page, a vendor price file, or OVHcloud’s public order catalog, except the CloudTally and vpsforlife rows, which are labeled as secondary and dated in the finding.

### Cited Findings

- Hetzner CPX specs, 20 TB traffic wording, snapshot €0.0143 per GB-month, backup “starting at €1.0980”, and the €59.49 / €69.99 widget figures: [https://www.hetzner.com/cloud/regular-performance/](https://www.hetzner.com/cloud/regular-performance/) — 11 November 2026.
- Hetzner CPX, CX, CAX, and IPv4 euro amounts and hourly rates: [https://www.hetzner.com/_resources/app/data/app/live_data_prices.json](https://www.hetzner.com/_resources/app/data/app/live_data_prices.json) — 11 November 2026. This file is what the product pages’ price component loads (`website-price-api` falls back to this URL in Hetzner’s webcomponents script).
- Hetzner CX and CAX specs and the not-available badge: [https://www.hetzner.com/cloud/cost-optimized/](https://www.hetzner.com/cloud/cost-optimized/) — 11 November 2026.
- Hetzner primary IPv4 €0.50 on the docs page, last change 2023-04-13 (stale date): [https://docs.hetzner.com/general/infrastructure-and-availability/ipv4-pricing/](https://docs.hetzner.com/general/infrastructure-and-availability/ipv4-pricing/).
- Hetzner backup 20% and hourly-versus-cap billing, FAQ last change 2020-07-07 (stale date): [https://docs.hetzner.com/cloud/billing/faq/](https://docs.hetzner.com/cloud/billing/faq/).
- Netcup card prices, specs, and embedded catalog amounts: [https://www.netcup.com/en/server/vps](https://www.netcup.com/en/server/vps) — 11 November 2026.
- Contabo Cloud VPS 4 / 6 / 8 prices and specs: [https://contabo.com/en/vps/](https://contabo.com/en/vps/) — 11 November 2026.
- OVHcloud VPS 2027 “from” prices, specs, included backup, premium backup from €1.10, snapshots from €0.30: [https://www.ovhcloud.com/en-ie/vps/](https://www.ovhcloud.com/en-ie/vps/) — 11 November 2026.
- OVHcloud no-commitment monthly prices and zero installation fees: [https://eu.api.ovh.com/1.0/order/catalog/public/vps?ovhSubsidiary=IE](https://eu.api.ovh.com/1.0/order/catalog/public/vps?ovhSubsidiary=IE) — 11 November 2026.
- Hostinger euro promo and renewal prices: [https://www.hostinger.com/de/Preise/vps-hosting](https://www.hostinger.com/de/Preise/vps-hosting) — 11 November 2026.
- Hostinger USD promo cross-check, transfer quotas, 1 Gbps, EU locations, weekly backups: [https://www.hostinger.com/vps-hosting](https://www.hostinger.com/vps-hosting) — 11 November 2026.

### Inferences

- The Hetzner price file and the product-page widget agree once the €0.50 IPv4 is added to the file’s server cap. The file is the better source for the server-only cap; the widget is the better source for what the page shows as the price including IPv4.
- Netcup’s bold card price is a “from” price for the cheapest EU SKU on a 12-month term, including the VAT label, not the Nuremberg 1-month price.

### Gaps

- Pages with a last-change date before October 2026 (Hetzner IPv4 docs 2023-04-13, Hetzner billing FAQ 2020-07-07, Hetzner server FAQ 2024-09-12, Netcup server FAQ 2 March 2026) are still the live documents, and they are marked stale by that date rule.
- Contabo’s nested-virtualization article has no revision date. Hostinger’s nested-virtualization article was modified 29 October 2026.
