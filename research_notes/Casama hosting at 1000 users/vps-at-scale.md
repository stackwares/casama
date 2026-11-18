# VPS RAM at 64 GB and 128 GB

Checked 11 November 2026. Every new figure below was read that day from the vendor page, docs page, or public price file named on the bullet. Amounts are EUR. Starter-tier prices already on record were re-read only where this pass opened that vendor’s page again; they matched. Private-network fees are omitted. No traffic-per-user figure is invented, so none of the caps below is converted into a user count.

## Biggest plan, RAM, monthly price, term, and VAT

### Takeaway

On 11 November 2026 the largest VPS RAM on the public pages is 96 GB at Contabo (Cloud VPS 18 and Cloud VDS XXL), 24 GB on the OVHcloud VPS page (VPS-4 2027), 64 GB at Netcup (VPS 8000 G12.5), 32 GB at Hostinger (KVM 8), and 192 GB at Hetzner (CCX63). OVHcloud’s Ireland order catalog still contains a 64 GB and a 96 GB VPS product that the public VPS page does not show.

### Cited Findings

#### Contabo

- Core VPS page, fetched 11 November 2026: Cloud VPS 16 is 16 vCPU, 64 GB RAM, 500 GB SSD or 250 GB NVMe, 1 Gbit/s, unlimited traffic, €29.60 per month excluding VAT and €37.00 including VAT. Cloud VPS 18 is 18 vCPU, 96 GB RAM, 600 GB SSD or 300 GB NVMe, 1 Gbit/s, unlimited traffic, €39.20 excluding VAT and €49.00 including VAT. The page footer says the displayed price is the effective monthly rate for a 24-month subscription, including applicable taxes. The inclusive figures on this fetch are exactly 25% above the exclusive figures (€29.60 × 1.25 = €37.00; €39.20 × 1.25 = €49.00). The page does not label that rate as German 19% VAT. — [contabo.com/en/vps](https://contabo.com/en/vps/)
- The same page’s Cloud VPS 4 and Cloud VPS 8 cards still show €4.40 and €11.20 per month excluding VAT for the first 24 months, matching the figures already on record. — [contabo.com/en/vps](https://contabo.com/en/vps/)
- Contabo’s VPS documentation, fetched 11 November 2026, lists the same Core ceiling: Cloud VPS 4 through 18, 8 GB through 96 GB. Performance VPS (Cloud VPS Plus 4 through 18) also tops at 18 vCPU and 96 GB. Storage VPS tops at 50 GB. Docs describe Max Performance VPS (VDS) as a separate dedicated-core line. — [Contabo VPS docs](https://docs.contabo.com/docs/servers-hosting/vps/)
- Contabo’s Max Performance VPS docs list Cloud VDS XXL as the top of that line: 24 dedicated vCores (AMD EPYC 7282), 96 GB RAM, 720 GB NVMe, 1,000 Mbit/s. Cloud VDS XL is 16 vCores and 64 GB. The product page shows XXL at €151.20 per month excluding VAT and €189.00 including VAT, and XL at €103.20 excluding VAT and €129.00 including VAT, with the same 24-month footer. That line does not exceed 96 GB, and it is several times the Core price for the same RAM. — [Max Performance VPS docs](https://docs.contabo.com/docs/servers-hosting/max-performance-vps/); [vps-dedicated](https://contabo.com/en-us/vps-dedicated/)

#### OVHcloud

- The public VPS page, fetched 11 November 2026, shows a “VPS 2027” range of four plans. The largest card is VPS-4: 8 vCores, 24 GB RAM, 200 GB NVMe, unlimited traffic, 3 Gbps, “From $23.37 /month” on that worldwide English page. No 64 GB or 128 GB card is on the page. — [ovhcloud.com/en/vps](https://www.ovhcloud.com/en/vps/)
- Ireland public order catalog `ovhSubsidiary=IE`, fetched 11 November 2026. Prices below are the catalog integer divided by 100,000,000. The tax field is separate. On VPS-5 the tax is 23% of the monthly price, so these amounts are excluding VAT. Interval on these rows is 1, so the commitment figures are monthly rates, not prepay totals.
  - VPS-2 2027 (`vps-2027-model2`): no-commitment €8.49 per month, 12-month €7.21. Matches the figure already on record.
  - VPS-3 2027 (`vps-2027-model3`): no-commitment €12.24, 12-month €10.40, 6-month €11.62.
  - VPS-4 2027 (`vps-2027-model4`): product description “VPS 8 vCPU 24 GB RAM 200 GB disk”. No-commitment €23.49, 12-month €19.96, 6-month €22.31. Plan tags include `website:show` and `order-funnel:show`.
  - VPS-1 2027 (`vps-2027-model1`): no-commitment €4.49, 12-month €3.81. Product description was not re-printed in this pass; the public page and the earlier same-day catalog read give it 2 vCores, 4 GB RAM, 40 GB NVMe.
  — [IE VPS catalog](https://eu.api.ovh.com/1.0/order/catalog/public/vps?ovhSubsidiary=IE)
- The same catalog contains plans the public page does not tag for display:
  - `vps-2025-model5`, invoice name “VPS-5 2026”, product description “VPS 16 vCPU 64 GB RAM 350 GB disk”. No-commitment €54.99 per month, 6-month €52.24, 12-month €46.74, all excluding VAT. Tags are only `os:distribution-only` and `os:distribution-with-application`. No `website:show` or `order-funnel:show`.
  - `vps-2025-model6`, invoice name “VPS-6 2026”, product description “VPS 24 vCPU 96 GB RAM 400 GB disk”. No-commitment €72.99, 6-month €69.34, 12-month €62.04, excluding VAT. Same OS-only tags.
  — [IE VPS catalog](https://eu.api.ovh.com/1.0/order/catalog/public/vps?ovhSubsidiary=IE)
- A different catalog product, `vps-2020v2-model5`, has description “VPS 16 vCPU 64 GB RAM 350 GB disk” and a technical blob of 16 vCores, 64 GB memory, 350 GB NVMe, `bandwidth.level` 2500, `bandwidth.unlimited` true. That blob was not found on `vps-2025-model5` or `vps-2025-model6` in the fields read this pass, so the 2,500 Mbps figure is not applied to the 2026 plans. — [IE VPS catalog](https://eu.api.ovh.com/1.0/order/catalog/public/vps?ovhSubsidiary=IE)

#### Netcup

- VPS listing, fetched 11 November 2026, 12-month term selected, “from” price, prices labelled including 19% VAT. The largest card is VPS 8000 G12.5: 16 vCore x86, 64 GB RAM, 1 TB SSD. Bold €67.11, second figure €77.16. The next card down, VPS 4000 G12.5, is 12 vCore, 32 GB, 512 GB SSD, bold €45.36 and second figure €52.16. No card above 64 GB is on the page. VPS 2000 G12.5 is still bold €26.92, matching the figure already on record. — [netcup.com/en/server/vps](https://www.netcup.com/en/server/vps)
- VPS 8000 G12.5 24-month EU product page, fetched 11 November 2026: 16 vCore, 64 GB ECC RAM, 1024 GB SSD, setup fee €0.00 including 19% VAT. With “No preference Europe” and “IPv4 + IPv6 Connectivity”, the displayed total is €57.04 per month including 19% VAT on the 24-month term. The 1-month control reads “+€20.12”, and €57.04 + €20.12 = €77.16, which is the second figure on the listing card. Nuremberg is “+€8.56” on that same configuration. IPv6-only and “Cloud vLAN only” are each “−€0.60”. The page says provisioning “may be slightly delayed” and asks the buyer to open a ticket. — [VPS 8000 G12.5 24-month EU](https://www.netcup.com/en/server/vps/vps-8000-g12.5-iv-24m-eu)

#### Hostinger

- German VPS price page, fetched 11 November 2026, 24-month term selected. The largest plan on the page is KVM 8: 8 vCPU cores, 32 GB RAM, 400 GB NVMe, 32 TB bandwidth. Struck €64.99, promo €21.99 per month, “Heute zahlen Sie 527,76 € für 24 Monate”, renewal €49.99 per month for the same term. KVM 4 on the same page is 4 vCPU, 16 GB, 16 TB, promo €10.99, €263.76 for 24 months, renewal €27.99. The page does not say whether the euro amounts include VAT. 21.99 × 24 = 527.76. — [hostinger.com/de/Preise/vps-hosting](https://www.hostinger.com/de/Preise/vps-hosting)

#### Hetzner

- General Purpose page, fetched 11 November 2026. Dedicated-vCPU plans, prices excluding VAT, and the page has a “Price incl. IPv4” control. The largest plan is CCX63: 48 AMD vCPU, 192 GB RAM, 960 GB NVMe. “From” €725.49 per month and €1.1626 per hour. The Helsinki line is €725.49 per month. The Nuremberg line is €853.99 per month. EU included traffic on that card is 60 TB. — [hetzner.com/cloud/general-purpose](https://www.hetzner.com/cloud/general-purpose/)
- Same page, CCX53: 32 AMD vCPU, 128 GB RAM, 600 GB NVMe. From / Helsinki €453.49 per month, €0.7267 per hour. Nuremberg €533.99 per month. EU included traffic 50 TB. — [general-purpose](https://www.hetzner.com/cloud/general-purpose/)
- Same page, CCX43: 16 AMD vCPU, 64 GB RAM, 360 GB NVMe. From / Helsinki €234.99 per month, €0.3766 per hour. Nuremberg €276.49 per month. EU included traffic 40 TB. — [general-purpose](https://www.hetzner.com/cloud/general-purpose/)
- Regular Performance page, fetched 11 November 2026. Largest shared plan on that matrix is CPX62: 16 AMD vCPU, 32 GB RAM, 640 GB NVMe, EU included traffic 20 TB. From €110.99 per month excluding VAT and €0.1779 per hour. CPX52 is 12 vCPU, 24 GB, 480 GB, from €85.49. CPX42 is still from €59.49, matching the Helsinki figure already on record. These rows do not carry the `not-available` class. Each row’s HTML also contains a `configbtn-tooltip` string, “This product is currently unavailable. Please check back later,” next to a Create link. — [regular-performance](https://www.hetzner.com/cloud/regular-performance/)
- Live price file, fetched 11 November 2026. Primary IPv4 `CLOUD_21` is €0.50 per month and €0.0008 per hour, excluding VAT, location `ALL`. The displayed “from” prices above equal the Helsinki server cap plus €0.50:
  - `CLOUD_146`: Helsinki €110.49 per month (€0.1771 per hour); Falkenstein and Nuremberg €129.99 (€0.2083 per hour). €110.49 + €0.50 = €110.99, the CPX62 “from” price. Nuremberg including that IPv4 is €130.49.
  - `CLOUD_145`: Helsinki €84.99; Germany €100.49. €84.99 + €0.50 = €85.49, the CPX52 “from” price.
  - `CLOUD_150`: Helsinki €234.49 (€0.3758 per hour); Germany €275.99 (€0.4423 per hour). Plus €0.50 equals the CCX43 Helsinki and Nuremberg lines.
  - `CLOUD_151`: Helsinki €452.99 (€0.7259 per hour); Germany €533.49 (€0.8550 per hour). Plus €0.50 equals the CCX53 lines.
  - `CLOUD_152`: Helsinki €724.99 (€1.1618 per hour); Germany €853.49 (€1.3678 per hour). Plus €0.50 equals the CCX63 lines.
  The HTML id within 2,500 characters before each plan name was the previous card’s id, because the price widget sits above a large SVG. The ids above are the ones whose caps are exactly €0.50 under the displayed location price, in plan order. — [live price file](https://www.hetzner.com/_resources/app/data/app/live_data_prices.json)
- Billing is hourly with a monthly cap: “Your server's bill will never exceed its monthly price cap.” — [general-purpose](https://www.hetzner.com/cloud/general-purpose/)

### Inferences

- A single Contabo VPS reaches 64 GB (Cloud VPS 16) and 96 GB (Cloud VPS 18 or Cloud VDS XXL). It does not reach 128 GB. The cheap machine at 64 GB is Core Cloud VPS 16 at €29.60 excluding VAT, not the VDS.
- A single machine on the OVHcloud public VPS page does not reach 64 GB. The order catalog’s VPS-5 2026 description is 64 GB and VPS-6 2026 is 96 GB, and neither description is 128 GB. Those two plans are not tagged for the website.
- A single Netcup G12.5 VPS reaches 64 GB and does not reach 128 GB. The 24-month checkout price (€57.04 including 19% VAT) is lower than the 12-month “from” card (€67.11 including 19% VAT). Adding the published Nuremberg adder gives €57.04 + €8.56 = €65.60 including 19% VAT per month on that 24-month configuration.
- A single Hostinger KVM VPS does not reach 64 GB. KVM 8 at 32 GB is the top of the German price page.
- A single Hetzner cloud server reaches 64 GB (CCX43), 128 GB (CCX53), and 192 GB (CCX63). The largest shared plan, CPX62, stops at 32 GB. The customer price on the page includes the €0.50 IPv4; the price-file cap does not.

### Gaps

- Contabo does not publish the price after the first 24 months. Performance VPS (Cloud VPS Plus) prices were not taken from a product page in this pass; the docs cap that line at 96 GB, same as Core.
- Whether a customer can still place a new order for OVHcloud VPS-5 2026 or VPS-6 2026 is not stated. They are in the public catalog and they are not tagged `website:show`. Bandwidth for those two 2026 products was not in the fields read.
- The Germany OVHcloud subsidiary catalog was not compared with Ireland.
- Netcup root servers were not priced. They are a different product from the VPS page.
- Hostinger does not say whether the German euro prices include VAT.
- Hetzner’s `configbtn-tooltip` “currently unavailable” string is present on CPX cards that also have a Create link and no `not-available` class. This pass did not determine whether that tooltip is shown to buyers.

## Cost of 64 GB and of 128 GB

### Takeaway

One machine covers 64 GB at Contabo (€29.60 excluding VAT), Netcup (€67.11 including 19% VAT on the 12-month “from” card, or €57.04 including 19% VAT on the 24-month EU checkout), and Hetzner (CCX43 at €234.99 Helsinki or €276.49 Nuremberg, excluding VAT, IPv4 included). One machine covers 128 GB only at Hetzner (CCX53 at €453.49 Helsinki or €533.99 Nuremberg, same VAT and IPv4 treatment). Everywhere else, 64 GB and 128 GB are a sum of smaller VPS. The sums below use the cheapest combination found on that vendor’s own price list. They are arithmetic on the cited prices, not a second published bundle.

### Cited Findings

The prices summed here are the ones in the previous section. No vendor publishes a “64 GB pack” or “128 GB pack”.

### Inferences

Sums use one price basis per row. “Excl. VAT” and “incl. VAT” are not mixed inside a sum.

Contabo Core, 24-month displayed rate. Inclusive column is the 25% figure this fetch showed, not a labelled 19% rate.

| Target | Machines | RAM | Excl. VAT / month | Incl. VAT on this fetch / month |
| --- | --- | --- | --- | --- |
| 64 GB, one machine | 1 × Cloud VPS 16 | 64 GB | €29.60 | €37.00 |
| 128 GB, no single machine (max 96 GB) | 2 × Cloud VPS 16 | 128 GB | €59.20 | €74.00 |

One Cloud VPS 18 (96 GB, €39.20 excluding VAT) plus one Cloud VPS 12 (48 GB, €20.00 excluding VAT) is also €59.20 excluding VAT and totals 144 GB. Two Cloud VPS 16 is the combination that lands on 128 GB at that same sum. Cloud VDS XL is €103.20 excluding VAT for one 64 GB machine, and two would be €206.40, so the VDS line is not the cheap path.

OVHcloud, public VPS 2027 range only, Ireland catalog, excluding VAT. The largest plan is 24 GB, so three of them is 72 GB and five of them is 120 GB. Filling to the exact target with the smaller plans costs less than buying only VPS-4.

| Target | Machines | RAM | No commitment / month | 12-month / month |
| --- | --- | --- | --- | --- |
| 64 GB | 2 × VPS-4 + 1 × VPS-3 + 1 × VPS-1 | 48 + 12 + 4 = 64 GB | €63.71 | €54.13 |
| 128 GB | 5 × VPS-4 + 1 × VPS-2 | 120 + 8 = 128 GB | €125.94 | €107.01 |

Arithmetic: no-commitment 64 GB is 2 × €23.49 + €12.24 + €4.49. Twelve-month 64 GB is 2 × €19.96 + €10.40 + €3.81. No-commitment 128 GB is 5 × €23.49 + €8.49. Twelve-month 128 GB is 5 × €19.96 + €7.21. Buying only VPS-4 would be 3 × €23.49 = €70.47 (72 GB) and 6 × €23.49 = €140.94 (144 GB) with no commitment.

OVHcloud catalog plans that are not on the VPS page, same catalog, excluding VAT. These are a separate case because the plans lack `website:show`.

| Target | Machines | RAM | No commitment / month | 12-month / month |
| --- | --- | --- | --- | --- |
| 64 GB, one catalog product | 1 × VPS-5 2026 | 64 GB | €54.99 | €46.74 |
| 128 GB | 2 × VPS-5 2026 | 128 GB | €109.98 | €93.48 |

VPS-6 2026 is 96 GB at €72.99 no-commitment or €62.04 on 12 months. One of those plus one VPS-4 2027 is 120 GB, which is short of 128 GB. Two VPS-5 machines are the catalog combination that lands on 128 GB.

Netcup, including 19% VAT, no-preference Europe, IPv4 included in the checkout figure. VPS 8000 is 64 GB, so 128 GB is two of them. Two VPS 4000 (32 GB) at the card’s €52.16 would be €104.32 for 64 GB, which is more than one VPS 8000.

| Target | Machines | 12-month “from” card / month | 24-month checkout / month | 1-month / month |
| --- | --- | --- | --- | --- |
| 64 GB, one machine | 1 × VPS 8000 G12.5 | €67.11 | €57.04 | €77.16 |
| 128 GB | 2 × VPS 8000 G12.5 | €134.22 | €114.08 | €154.32 |

Nuremberg on the 24-month page is +€8.56 per server, so one server is €65.60 and two are €131.20, including 19% VAT, if that adder is applied once per server to the displayed monthly price.

Hostinger Germany, 24-month term, VAT not stated on the page. KVM 8 is 32 GB.

| Target | Machines | Promo / month | Due at order | Renewal / month |
| --- | --- | --- | --- | --- |
| 64 GB | 2 × KVM 8 | €43.98 | €1,055.52 | €99.98 |
| 128 GB | 4 × KVM 8 | €87.96 | €2,111.04 | €199.96 |

Four KVM 4 (16 GB) at the promo is 4 × €10.99 = €43.96 per month, almost the same as two KVM 8, but the renewal is 4 × €27.99 = €111.96 against €99.98 for two KVM 8. The pair of KVM 8 is the cheaper renewal for 64 GB.

Hetzner, excluding VAT, IPv4 included in the page price (€0.50 per server). Shared CPX62 is 32 GB. Dedicated CCX43 is one 64 GB machine and CCX53 is one 128 GB machine. Two or four CPX62 machines cost less than the single dedicated machine at both listed EU locations.

| Target | Machines | Helsinki / month | Nuremberg / month |
| --- | --- | --- | --- |
| 64 GB, shared | 2 × CPX62 | €221.98 | €260.98 |
| 64 GB, one machine | 1 × CCX43 | €234.99 | €276.49 |
| 128 GB, shared | 4 × CPX62 | €443.96 | €521.96 |
| 128 GB, one machine | 1 × CCX53 | €453.49 | €533.99 |

Server caps without the €0.50 IPv4, from the price file: two CPX62 are €220.98 in Helsinki and €259.98 in Nuremberg or Falkenstein; four are €441.96 and €519.96. One CCX43 is €234.49 Helsinki and €275.99 Germany. One CCX53 is €452.99 Helsinki and €533.49 Germany.

### Gaps

- No vendor page sells a single VPS of 128 GB except Hetzner CCX53 (and CCX63, which is 192 GB). Contabo, the OVHcloud catalog, and Netcup stop at 96 GB, 96 GB, and 64 GB.
- Hostinger’s promo is a 24-month introductory price. The renewal column is the later monthly price printed on the same page.
- OVHcloud VPS-5 and VPS-6 sums apply only if those catalog plans can be ordered. The public VPS page does not list them.

## Bandwidth caps that apply when some of 1,000 users open a live desktop stream

### Takeaway

Four of the five vendors publish a numeric traffic limit. Netcup throttles a VPS to 200 Mbps when its average over the last 24 hours exceeds 2 TB. Hostinger throttles to 10 Mbps for the rest of the month after the plan’s monthly terabyte cap, which is 32 TB on KVM 8. Hetzner includes 20 TB on CPX62 and 40 TB, 50 TB, or 60 TB on CCX43, CCX53, and CCX63, then prints a further charge. OVHcloud’s European VPS page says unlimited traffic, with a quota only for Mumbai, Singapore, and Sydney. Contabo says there is no default bandwidth cap and that it may throttle “exceptionally high or disruptive” use. None of the pages states how much traffic one user or one desktop stream generates, so this pass does not say whether 1,000 users would cross any of these caps.

### Cited Findings

- Contabo product page, 11 November 2026: “Incoming Traffic: Unlimited and unmetered. No extra charges apply. Outgoing Traffic: Unlimited — fair usage policy applies based on average server workloads.” Contabo “reserves the right to throttle servers with exceptionally high or disruptive usage patterns.” Cloud VPS 16 and Cloud VPS 18 are on a 1 Gbit/s port. — [contabo.com/en/vps](https://contabo.com/en/vps/)
- Contabo VPS docs, same day: “No default bandwidth cap; a fair usage policy applies. Contabo notifies customers by email if usage is exceptionally high or disruptive and reserves the right to throttle affected servers.” The same sentence is on the Max Performance VPS docs. Port speeds on Core VPS 16 and 18 are 1,000 Mbit/s. — [VPS docs](https://docs.contabo.com/docs/servers-hosting/vps/); [Max Performance VPS docs](https://docs.contabo.com/docs/servers-hosting/max-performance-vps/)
- OVHcloud public VPS page, same day: “Unlimited traffic” on each VPS 2027 card, with public bandwidth of 500 Mbps, 1 Gbps, 2 Gbps, and 3 Gbps for VPS-1 through VPS-4. Footnote: “Our VPS solutions in the Asia-Pacific region (Mumbai, Singapore, Sydney) come with a set monthly quota: 500 GB for VPS-1, 1 TB for VPS-2 and VPS-3, 3 TB for VPS-4. Beyond this, the bandwidth is capped at 10 Mbps.” The footnote does not give a quota for a European datacentre. — [ovhcloud.com/en/vps](https://www.ovhcloud.com/en/vps/)
- Netcup VPS 8000 G12.5 product page, same day: “If the average network traffic of the last 24 hours exceeds 2 TB, a temporary throttling to 200 Mbps is applied. The throttling is lifted as soon as the condition no longer applies.” Interface speed on that page is 2.5 Gbit/s. The listing calls this “Traffic Flatrate” and “Traffic included”. — [VPS 8000 G12.5 24-month EU](https://www.netcup.com/en/server/vps/vps-8000-g12.5-iv-24m-eu)
- Hostinger German price page, same day: KVM 8 includes “32 TB Bandbreite”. KVM 4 includes 16 TB, KVM 2 includes 8 TB, KVM 1 includes 4 TB. — [German VPS prices](https://www.hostinger.com/de/Preise/vps-hosting)
- Hostinger support article, fetched 11 November 2026, `dateModified` 29 October 2026: when the VPS reaches its monthly bandwidth limit, “the connection speed will be reduced to 10 Mbps for the rest of the month,” the services stay online, and the allowance resets at the beginning of the next month. The article describes the limit as terabytes per month and does not restate the 32 TB figure. — [bandwidth limit article](https://www.hostinger.com/support/8789965-what-happens-if-your-vps-bandwidth-resource-limits-are-exceeded/)
- Hetzner Regular Performance and General Purpose pages, same day. Included traffic printed on the plan, EU locations: CPX62 20 TB, CCX43 40 TB, CCX53 50 TB, CCX63 60 TB. The shared sentence on those cards: “Cloud servers located in the EU include at least 20 TB of included traffic. For each additional TB at EU-Central locations we charge € 1.00 per hour, excl. VAT.” The price label is “per hour” and the sentence is “for each additional TB”. Price-file product `CLOUD_66` is €1.00 in the hourly field for location `ALL`, with no monthly field, and €7.40 in the hourly field for the Singapore amount the page uses. — [regular-performance](https://www.hetzner.com/cloud/regular-performance/); [general-purpose](https://www.hetzner.com/cloud/general-purpose/); [live price file](https://www.hetzner.com/_resources/app/data/app/live_data_prices.json)
- Hetzner General Purpose FAQ, same page: host systems have a redundant 10 Gbit/s connection shared by the instances on that host. “We do not offer bandwidth guarantees for our Cloud servers, but you can expect about 300-500 Mbits.” — [general-purpose](https://www.hetzner.com/cloud/general-purpose/)

### Inferences

- The caps are per VPS. Buying two or four machines adds a separate allowance for each machine. It does not create one pooled allowance, and no page says that it does.
- The numeric caps a live desktop stream would draw against, if that stream’s bytes are counted as the traffic the vendor meters, are Netcup’s 2 TB over the last 24 hours per VPS, Hostinger’s monthly terabytes (32 TB on each KVM 8) followed by 10 Mbps, and Hetzner’s included terabytes followed by the printed extra charge. OVHcloud’s European wording does not set a terabyte cap. Contabo does not publish a terabyte number; it publishes a 1 Gbit/s port on the 64 GB and 96 GB Core plans and a fair-use throttle with no threshold.
- Whether 1,000 users, some of them opening a desktop stream, would cross any of those caps is not knowable from these pages. No vendor page gives traffic per user or traffic per desktop stream.

### Gaps

- Hetzner’s extra-traffic price is written both as “for each additional TB” and as “€ 1.00 per hour”. This pass does not choose between those two units.
- Contabo’s fair-use rule has no published terabyte or megabit threshold.
- OVHcloud’s 2,500 Mbps technical value belongs to catalog product `vps-2020v2-model5`, not to a bandwidth field read from VPS-5 2026 or VPS-6 2026.
- Hostinger’s support article does not repeat the per-plan terabyte amounts. Those amounts are on the German price page. The article’s `dateModified` is 29 October 2026.
- No source in this pass gives gigabytes per user or per live desktop stream, so no “this cap bites at 1,000 users” conclusion is available.
