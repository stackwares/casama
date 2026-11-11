# Cheapest always-on servers outside the EU budget set

Scope: published always-on VM prices for a Docker Compose stack (Postgres, a Node API, a worker, and extra containers), outside the EU budget-VPS set. Checked 11 November 2026 unless a source’s own timestamp is cited. Figures are USD list prices before tax. No provider is selected.

Boxes requested: a small one (about 2–4 vCPU and 4–8 GB) and a larger one (8 vCPU and 16 GB) where that shape exists. Ampere A1 is Arm: 1 OCPU = 1 vCPU, not 2.

## Monthly price, specs, traffic, egress, IPv4, and backups

### Takeaway

On the pages checked 11 November 2026, a small always-on box is published from a few dollars a month (RackNerd’s annual 4 GB special, Hostinger’s current 24-month KVM 2 rate) through about $24–$48 on Vultr, DigitalOcean, and Akamai shared CPU, while a paid Oracle Ampere A1 shape can stay inside a large monthly free hour allowance. An 8 vCPU / 16 GB shape is on Vultr’s shared high-performance list at $96, DigitalOcean’s basic list at $96, and Akamai’s G6 dedicated list at $144. BuyVM’s largest published slice on its KVM slice page is 7 cores, and RackNerd’s specials page stops at 8 GB.

### Cited Findings

#### Oracle Cloud, Ampere A1

- The Always Free doc says every tenancy gets the first 1,500 OCPU-hours and 9,000 GB-hours per month on `VM.Standard.A1.Flex`, and that for Always Free tenancies this equals 2 OCPUs and 12 GB, usable as one VM or two 1-OCPU VMs, only in the home region. Checked 11 November 2026. — [Always Free Resources](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm)
- The same doc says the minimum boot volume is 47 GB, the account includes 200 GB of Always Free block volume (boot plus data) and five volume backups, and Always Free includes 10 TB per month of outbound data. A later paragraph in the same doc says the default boot volume is 50 GB and the minimum allowed is 50 GB. — [Always Free Resources](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm)
- The public price list says the first 3,000 OCPU-hours and 18,000 GB-hours each month are free for the Ampere A1 shape, and a container-instances note says each paid tenancy gets that allowance, shared across bare metal, VM, and container instances. Price cells on the HTML page are filled by script and were empty in a static fetch. Checked 11 November 2026. — [Cloud Price List](https://www.oracle.com/cloud/price-list/)
- Oracle’s cost-estimator product API, `lastUpdated` 2026-11-02, prices PAYG USD as: A1 OCPU (part B93297) $0 from 0 to 3,000 OCPU-hours, then $0.01 per OCPU-hour; A1 memory (B93298) $0 from 0 to 18,000 GB-hours, then $0.0015 per GB-hour. The Arm marketing page states the same $0.01 and $0.0015 rates “in all regions.” — [Cost estimator product API](https://apexapps.oracle.com/pls/apex/cetools/api/v1/products/); [Ampere A1 Compute](https://www.oracle.com/cloud/compute/arm/)
- The same API prices block volume storage (B91961) at $0.0255 per GB-month and lists a separate “Block Volume - Free 200GB” SKU (B91445) at $0. Performance units (B91962) are $0.0017 per performance unit per GB-month. The price-list page text says 10 VPUs are $0.017 for balanced performance. — [Cost estimator product API](https://apexapps.oracle.com/pls/apex/cetools/api/v1/products/); [Cloud Price List](https://www.oracle.com/cloud/price-list/)
- Outbound data in that API is free for the first 10,240 GB, then $0.0085 per GB from North America, Europe, and the UK (B88327), $0.025 per GB from APAC, Japan, and South America (B93455), and $0.05 per GB from the Middle East and Africa (B93456). Inbound is free on the price-list page. A February 2026 news write-up saying OCI had removed all egress charges is contradicted by this 2 November 2026 API and by the live price list still having an over-10-TB SKU. — [Cost estimator product API](https://apexapps.oracle.com/pls/apex/cetools/api/v1/products/); [Cloud Price List](https://www.oracle.com/cloud/price-list/); contradicted by [TCOIQ](https://tcoiq.com/cloud-news/oracle-oci-announces-free-egress-pricing-globally-across-all-regions)
- The price list says 1 OCPU on Arm A1 equals 1 core or 1 vCPU, and A1 memory can be set from 1 GB to 64 GB per OCPU. Boot volumes are billed as block volume on top of compute. — [Cloud Price List](https://www.oracle.com/cloud/price-list/)
- No public-IPv4 or reserved-IP product with a non-zero USD price turned up in a name search of that API on 11 November 2026. The Always Free doc says the AMD micro shape includes one public IP; it describes A1 networking as scaling with OCPU count and does not list an IPv4 fee. — [Cost estimator product API](https://apexapps.oracle.com/pls/apex/cetools/api/v1/products/); [Always Free Resources](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm)

#### BuyVM KVM slices

- Slice page, checked 11 November 2026. Slice 2048: 1 core at 3.50+ GHz, fair-share CPU, 2 GB, 40 GB SSD, unmetered, 1 IPv4, $7/month. Slice 4096: 1 core, “Dedicated CPU Usage,” 4 GB, 80 GB SSD, unmetered, 1 IPv4, $15/month. High-volume rows: 2 cores / 8 GB / 160 GB SSD / unmetered 1 Gbps / $30/month; 4 cores / 16 GB / 320 GB SSD / $60/month; the table continues by one core and 4 GB up to 7 cores / 28 GB / $105/month. No 8-core row. — [BuyVM KVM slices](https://www.buyvm.net/kvm-dedicated-server-slices)
- One IPv4 is included. A DDoS-filtered IPv4 is $3/month per IP. Block storage is $1.25/month per 256 GB. Automatic backups are 10% of the instance price, or $0.50/month on the 512 MB and 1 GB instances, nightly, with 7 days kept. Five snapshots per location are included. The page states unmetered bandwidth and does not list an egress overage rate. — [BuyVM KVM slices](https://www.buyvm.net/kvm-dedicated-server-slices)
- A separate, older-looking KVM VPS page still lists much smaller RAM at higher prices (for example 1 GB for $20/month and a high-volume 8-core / 4 GB plan at $80/month). That page does not match the slice page. The slice page is the one whose prices a third-party tracker said it had re-read on 10 November 2026. — [BuyVM KVM VPS](https://www.buyvm.net/kvm-vps/); [Kuraberu, prices checked 10 Nov](https://kuraberu.app/vps/providers/buyvm)
- BuyVM’s own comparison table on the slice page quotes competitor prices (DigitalOcean 4 GB at $40, Linode 4 GB at $20, Vultr 4 GB at $40) that do not match those vendors’ own pages on 11 November 2026. — [BuyVM KVM slices](https://www.buyvm.net/kvm-dedicated-server-slices)

#### RackNerd

- Specials page, checked 11 November 2026, lifetime-recurring annual prices, 1 IPv4, 1 Gbps, KVM: 2 GB / 2 vCPU / 35 GB SSD / 5 TB for $35.99/year; 4 GB / 3 vCPU / 60 GB SSD / 7 TB for $59.99/year; 8 GB / 7 vCPU / 150 GB SSD / 20 TB for $119.99/year. There is no 16 GB special and no 8 vCPU / 16 GB special. — [RackNerd VPS specials](https://www.racknerd.com/specials/)
- The Ryzen NVMe page lists monthly plans, not the annual specials: 4 GB / 2 vCores / 30 GB NVMe / 3 TB at $24.59/month; 8 GB / 3 vCores / 75 GB / 5 TB at $36.59/month; 12 GB / 4 vCores / 90 GB / 6 TB at $55.99/month. No 16 GB row. — [RackNerd Ryzen VPS](https://www.racknerd.com/ryzen-vps)
- The specials FAQ says every special includes an IPv4 address and that Docker is allowed, including a one-click Portainer install. The page does not state an egress price past the included transfer, and it does not state a backup price. — [RackNerd VPS specials](https://www.racknerd.com/specials/)

#### Vultr

- Pricing page, checked 11 November 2026. Shared regular performance (older Intel, SSD): 2 vCPU / 4 GB / 3 TB / 80 GB at $20/month ($0.03/hr); 4 vCPU / 8 GB / 4 TB / 160 GB at $40/month; 6 vCPU / 16 GB / 5 TB / 320 GB at $80/month. There is no regular 8 vCPU / 16 GB row; the next row is 8 vCPU / 32 GB / 6 TB / 640 GB at $160/month. — [Vultr pricing](https://www.vultr.com/pricing/)
- Shared high performance, AMD and Intel rows printed at the same prices: 2 vCPU / 4 GB / 5 TB / 100 GB NVMe at $24/month; 4 vCPU / 8 GB / 6 TB / 180 GB at $48/month; 8 vCPU / 16 GB / 8 TB / 350 GB at $96/month ($0.143/hr). — [Vultr pricing](https://www.vultr.com/pricing/)
- The page says these Cloud Compute VMs “run atop shared vCPUs.” A separate CPU-optimized block, which the product docs describe as dedicated vCPUs, lists 4 vCPU / 8 GB at $80/month (75 GB) or $90/month (150 GB), both with 6 TB, and 8 vCPU / 16 GB at $160/month (150 GB) or $180/month (300 GB), both with 7 TB. — [Vultr pricing](https://www.vultr.com/pricing/); [Optimized Cloud Compute](https://docs.vultr.com/product-overviews/optimized-cloud-compute)
- The same pricing page’s FAQ: bandwidth past the included quota is $0.01 per GB; automatic backups add 20% to the base monthly/hourly fee; stored snapshots are $0.05/GB per month. It also says some locations can differ and the control panel is the source for those location prices. The $2.50 regular plan is marked IPv6 only; the $3.50 / 0.5 GB plan is not. An extra-IPv4 price was not on this page. — [Vultr pricing](https://www.vultr.com/pricing/)
- Billing doc, updated 26 October 2026: Cloud Compute is hourly and capped at 672 hours a month, so the printed monthly price is the always-on cap. Stopped instances that are not destroyed keep billing. GPU plans use a 730-hour cap instead. — [How am I billed for my servers?](https://docs.vultr.com/support/platform/billing/how-am-i-billed-for-my-servers)
- VX1, on the same pricing page, is described as dedicated CPU and is not capped at 672 hours. Rows include 2 vCPU / 8 GB at $0.060/hr (5 TB, block storage) and 4 vCPU / 16 GB at $0.120/hr. There is no 8 vCPU / 16 GB VX1 row; 8 vCPU / 32 GB is $0.240/hr. The Cloud Compute product page says VX1 starts at $43.80/month. — [Vultr pricing](https://www.vultr.com/pricing/); [Cloud Compute](https://www.vultr.com/products/cloud-compute/)

#### DigitalOcean Droplets

- Droplet pricing page, checked 11 November 2026. Basic (shared) bundled plans: 4 GiB / 2 vCPU / 4,000 GiB transfer / 80 GiB SSD at $24/month ($0.03571/hr); 8 GiB / 4 vCPU / 5,000 GiB / 160 GiB at $48/month; 16 GiB / 8 vCPU / 6,000 GiB / 320 GiB at $96/month. — [Droplet pricing](https://www.digitalocean.com/pricing/droplets)
- CPU-optimized (dedicated vCPUs, page text says 2.6 GHz+): 4 GiB / 2 vCPU / 4,000 GiB / 25 GiB at $42/month; 8 GiB / 4 vCPU / 5,000 GiB / 50 GiB at $84/month; 16 GiB / 8 vCPU / 6,000 GiB / 100 GiB at $168/month. General purpose dedicated starts at 8 GiB / 2 vCPU / $63 and 16 GiB / 4 vCPU / $126; the 8 vCPU general-purpose row on that table is 32 GiB at $252, not 16 GiB. — [Droplet pricing](https://www.digitalocean.com/pricing/droplets)
- Outbound overage is $0.01 per GiB. Inbound is free. Transfer is pooled across the team’s Droplets and does not roll over. The allowance accrues by the second, up to 2,419,200 seconds (28 days) per cycle. From 1 January 2026, Droplets are billed per second with a 60-second or $0.01 minimum, and bundled plans have a monthly cap at the printed price. — [Droplet pricing](https://www.digitalocean.com/pricing/droplets); [Bandwidth billing](https://docs.digitalocean.com/platform/billing/bandwidth/)
- Backups: weekly adds 20% of the Droplet cost, daily adds 30%. Usage-based backups are $0.04/GiB per month weekly down to $0.01/GiB per month every 4 hours. Snapshots are $0.06/GB per month. — [Droplet pricing](https://www.digitalocean.com/pricing/droplets); [Backups pricing](https://docs.digitalocean.com/products/backups/details/pricing/)
- Reserved IPv4 and IPv6 are free while assigned to a Droplet. An unassigned reserved IPv4 is $5.00/month ($0.01/hour), and billing starts only after $1 accrues on that IP. Unassigned reserved IPv6 is free. Doc `last_updated` 2026-10-26. — [Reserved IPs pricing](https://docs.digitalocean.com/products/networking/reserved-ips/details/pricing/)

#### Akamai Cloud (Linode)

- CPU pricing page, checked 11 November 2026, egress overage $0.005 per GB on every table below. Shared: Linode 4 GB, 2 CPU, 80 GB, 4 TB, $24/month ($0.036/hr); Linode 8 GB, 4 CPU, 160 GB, 5 TB, $48/month; Linode 16 GB, 6 CPU, 320 GB, 8 TB, $96/month. There is no shared 8 vCPU / 16 GB plan. The shared 8-CPU plan is Linode 32 GB at $192/month with 16 TB. — [Akamai Cloud CPU pricing](https://www.akamai.com/cloud/pricing/cpu)
- The public API `https://api.linode.com/v4/linode/types` on 11 November 2026 matches those base prices and adds region overrides only for Jakarta and Sao Paulo: Linode 4 GB $28.80 / $33.60, Linode 8 GB $57.60 / $67.20, Linode 16 GB $115.20 / $134.40. — [Linode types API](https://api.linode.com/v4/linode/types)
- G6 dedicated, same page and API: Dedicated 8 GB is 4 vCPU, 160 GB, 5 TB, $72/month (Jakarta $86.40, Sao Paulo $100.80); Dedicated 16 GB is 8 vCPU, 320 GB, 6 TB, $144/month (Jakarta $172.80, Sao Paulo $201.60). G7 Dedicated 16 GB is 8 vCPU, 320 GB, 6 TB, $173/month. — [Akamai Cloud CPU pricing](https://www.akamai.com/cloud/pricing/cpu); [Linode types API](https://api.linode.com/v4/linode/types)
- G8 Dedicated 16x8 is 8 vCPU, 16 GB, 160 GB disk, $0.27/hr, and the transfer column is 0 TB. The API returns `monthly: null` for G8. Jakarta is $0.324/hr and Sao Paulo $0.378/hr. The pricing FAQ says G6 and G7 include transfer in the rate, and G8 dedicated compute does not. Powered-off VMs are still billed until the service is removed. The FAQ also says an extra IP is billed, but not the amount. — [Akamai Cloud CPU pricing](https://www.akamai.com/cloud/pricing/cpu); [Linode types API](https://api.linode.com/v4/linode/types)
- Backup docs, page tree updated through 2026-11-09, say backups are optional and the enable dialog shows “the specified monthly cost.” The fetched docs do not print a price table. — [Enable backups](https://techdocs.akamai.com/cloud-computing/docs/enable-backups)

#### Hostinger KVM VPS (cheaper published option with its own price page)

- US pricing page, checked 11 November 2026, headed as a Black Friday deal, 24-month term, paid upfront. KVM 1: 1 vCPU, 4 GB, 50 GB NVMe, 4 TB, $6.49/month ($155.76 for 24 months), renews at $11.99/month for the same term. KVM 2: 2 vCPU, 8 GB, 100 GB NVMe, 8 TB, $8.79/month ($210.96 for 24 months), renews at $14.99/month. KVM 4: 4 vCPU, 16 GB, 200 GB NVMe, 16 TB, $12.99/month ($311.76 for 24 months), renews at $28.99/month. KVM 8: 8 vCPU, 32 GB, 400 GB NVMe, 32 TB, $25.99/month ($623.76 for 24 months), renews at $49.99/month. There is no 8 vCPU / 16 GB plan. Struck-through figures ($19.49, $24.49, $42.99, $73.99) are shown beside the sale rates; the page does not define them as the month-to-month price. — [Hostinger VPS pricing](https://www.hostinger.com/pricing/vps-hosting)
- The same page says free weekly backups, a 1 Gbps port, AMD EPYC, and a dedicated IP on every KVM VPS. It does not state an egress price past the included bandwidth. — [Hostinger VPS pricing](https://www.hostinger.com/pricing/vps-hosting)

### Inferences

- On a paid Oracle tenancy, a 730-hour month of 4 OCPUs and 16 GB is 2,920 OCPU-hours and 11,680 GB-hours, both inside the API’s free ranges (3,000 and 18,000), so compute would be $0 if nothing else consumes the A1 allowance. Eight OCPUs and 16 GB is 5,840 OCPU-hours, so 2,840 hours at $0.01, or $28.40, with memory still inside 18,000 GB-hours. A 50 GB boot volume sits inside the 200 GB free block allowance. These are arithmetic from the published rates, not invoices.
- Dividing RackNerd’s annual specials by 12 is $3.00, $5.00, and $10.00 per month for the 2 GB, 4 GB, and 8 GB plans. The page bills them as a year, not as $5/month.
- An always-on Akamai G8 8 vCPU / 16 GB VM at $0.27/hr is about $197 over 730 hours because the API has no monthly cap. That is not a printed monthly price, and every gigabyte of egress is at $0.005 because included transfer is 0 TB.
- Vultr’s printed monthly Cloud Compute prices already assume the 672-hour cap, so they are the always-on charge. VX1 does not use that cap.
- Hostinger’s $8.79 and $12.99 figures are the current 24-month promotional rates. The renewal rates on the same page ($14.99 and $28.99) are the later price for that same term. They are still well below DigitalOcean, Vultr, and Akamai shared prices for similar RAM, and the page is a sale page whose intro rate can end.

### Gaps

- Oracle paid volume-backup price beyond the five free backups, and any reserved public IPv4 fee, were not in the SKUs returned by the name search.
- RackNerd egress overage, backup price, and extra IPv4 price were not on the specials page.
- Vultr’s price for an additional IPv4, and location-specific exceptions to the published grid, were not retrieved (the FAQ points at the control panel).
- Akamai’s backup dollar schedule and extra-IPv4 dollar amount were not on the pages that loaded. A secondary review claiming backups are about 20% was not used as a price.
- Hostinger’s price past the included transfer, and whether the struck-through dollar figures are a real monthly term, were not stated on the pricing page.
- BuyVM’s older KVM VPS page and the slice page disagree. Which SKUs are actually in stock was not checked.

## Whether the free or cheap tier is obtainable in November 2026

### Takeaway

Oracle still publishes Always Free Ampere, but the live docs cap an Always Free tenancy at 2 OCPUs and 12 GB and tell users to expect “out of host capacity” in the home region. A paid account’s A1 SKU still has a larger free hour allowance (3,000 OCPU-hours and 18,000 GB-hours). No live per-region capacity board was available on 11 November 2026. RackNerd, Vultr, DigitalOcean, Akamai, and Hostinger are ordinary paid orders on public price pages. BuyVM’s prices are public; stock was not verified.

### Cited Findings

- Oracle documents an “out of host capacity” error as a temporary lack of Always Free shapes in the home region, and says to try another availability domain, wait, or upgrade to Pay as You Go. It says Always Free resources stay free after an upgrade and only usage above the Always Free limits is charged. Always Free A1 cannot be created in South Korea North (Chuncheon). Checked 11 November 2026. — [Always Free Resources](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm)
- The same doc says idle Always Free VM and bare-metal instances may be reclaimed if, for 7 days, the 95th percentile of CPU is under 20%, network utilization is under 20%, and, for A1 only, memory utilization is under 20%. — [Always Free Resources](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm)
- A secondary post describes the 2 OCPU / 12 GB Always Free cap as a reduction from an older 4 OCPU / 24 GB allowance. The official doc states the new cap and does not date the change. Another secondary page still describes Always Free as 4 cores and 24 GB, which the official doc contradicts. — [Joey, “When an Always Free server gets smaller”](https://joeywang.github.io/posts/oracle-always-free-arm-downsize/); contradicted by [CloudVista](https://www.ossvisor.com/blog/oci-the-overlooked-cloud.html); current wording on [Always Free Resources](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm)
- The paid-tenancy 3,000 / 18,000 hour allowance is in the price list and in the 2 November 2026 cost API. That is a different limit from the Always Free tenancy’s 1,500 / 9,000 hours. — [Cloud Price List](https://www.oracle.com/cloud/price-list/); [Cost estimator product API](https://apexapps.oracle.com/pls/apex/cetools/api/v1/products/)
- RackNerd’s specials page says plans are provisioned immediately and renew at the same rate for as long as the service is kept. — [RackNerd VPS specials](https://www.racknerd.com/specials/)
- Hostinger’s US VPS page was serving the promotional 24-month rates on 11 November 2026 under a “before it ends” sale heading. No end date was in the fetched text. — [Hostinger VPS pricing](https://www.hostinger.com/pricing/vps-hosting)
- Vultr, DigitalOcean, and Akamai publish hourly or monthly rates with no “sold out” flag on the pricing pages or, for Akamai, on the types API. Akamai’s region API returned `status: ok` for the EU and Asia regions listed in the regions section. — [Vultr pricing](https://www.vultr.com/pricing/); [Droplet pricing](https://www.digitalocean.com/pricing/droplets); [Linode regions API](https://api.linode.com/v4/regions)

### Inferences

- An Always Free tenancy cannot legally size an 8 OCPU instance: the doc caps that tenancy at 2 OCPUs and 12 GB. Reaching 4–8 OCPUs means a paid account, after which the SKU’s 3,000 / 18,000 hour free band can still cover a modest always-on A1 shape.
- A quiet Docker host on Always Free can meet the idle rule if CPU, network, and memory all stay under the 20% marks for a week. A stack that holds more than 20% of the VM’s memory, or that serves steady traffic, does not match the written reclaim test. That is a reading of the rule, not a count of how often Oracle applies it.
- Because capacity errors are defined as temporary and regional, “Always Free is obtainable in November 2026” is not a single global fact. It depends on the home region chosen at signup.

### Gaps

- No Oracle status page or capacity API was found that says, on 11 November 2026, whether Always Free A1 was in stock in Frankfurt, Amsterdam, or Singapore.
- An official “one free tenancy per person” or credit-card rule was not on the Always Free page that was read. Account-limit wording beyond home region, Chuncheon, and the idle rule is unverified here.
- BuyVM stock in Las Vegas, New York, and Luxembourg was not checked. The price page loads, which does not prove a plan can be ordered.
- Hostinger’s sale end date, and whether new orders on 11 November 2026 still received the intro rate in every country, was not tested with a checkout.

## Docker and shared CPU for an always-on API plus Postgres

### Takeaway

Docker is explicitly allowed on BuyVM, RackNerd, and Hostinger, and Akamai lists container workers as a normal shared-CPU use. Oracle A1 is a physical-core Arm shape, so the limit is Arm images and the Always Free idle rule, not a shared-CPU product. The cheap shared tiers at Vultr, DigitalOcean, and Akamai are the ones those vendors describe as variable or contention-prone; each also sells a dedicated tier at a higher price. No November 2026 steal-time measurement for this workload was found.

### Cited Findings

- BuyVM’s slice FAQ says “Yes, Docker works here!” and that the slices run KVM, not OpenVZ. Slice 512 through Slice 2048 are labeled “Fair Share CPU Usage.” Slice 4096 is labeled “Dedicated CPU Usage.” The high-volume table does not repeat either label. The page also claims “Absolutely no overselling” and no noisy-neighbor issues. — [BuyVM KVM slices](https://www.buyvm.net/kvm-dedicated-server-slices)
- RackNerd’s specials FAQ says Docker can be installed over SSH or from the panel, and the marketing line says “Full KVM for dedicated resources, stronger isolation, and steady performance.” The page does not publish a CPU pin, a fair-share ratio, or a steal-time limit. — [RackNerd VPS specials](https://www.racknerd.com/specials/)
- Hostinger’s VPS FAQ says full root access includes “Docker environments,” and a separate answer says the plans provide “dedicated CPU, RAM, and storage.” The same FAQ also says a VPS is not a dedicated server: it is a virtual machine on a shared physical host. Hardware is described as HPE and Dell with AMD EPYC. — [Hostinger VPS pricing](https://www.hostinger.com/pricing/vps-hosting)
- Vultr’s pricing page says Cloud Compute uses shared vCPUs and is suitable for low-traffic sites, dev/test, and small databases. High-performance plans are still in that shared section. Optimized Cloud Compute is documented as dedicated vCPUs. — [Vultr pricing](https://www.vultr.com/pricing/); [Optimized Cloud Compute](https://docs.vultr.com/product-overviews/optimized-cloud-compute)
- DigitalOcean describes Basic Droplets as the efficient, lower-cost choice “for workloads that underuse dedicated threads” and “bursty applications that can handle variable levels of CPU.” CPU-optimized and general-purpose Droplets are the dedicated-vCPU plans. — [Droplet pricing](https://www.digitalocean.com/pricing/droplets)
- Akamai’s shared-CPU doc says those CPUs are not dedicated, “a small amount of resource contention is possible,” and cores may burst to 100% but “should remain below 80% sustained usage on average, including virtualization overheads.” Recommended uses include low-traffic databases, production apps that can tolerate contention, and container-cluster workers. Dedicated plans are the alternative on the pricing page. — [Shared CPU Linodes](https://techdocs.akamai.com/cloud-computing/docs/shared-cpu-compute-instances); [Akamai Cloud CPU pricing](https://www.akamai.com/cloud/pricing/cpu)
- Oracle’s price list defines an A1 OCPU as one physical Arm core, priced separately from memory, not as a burstable shared-credit SKU. The Arm page prices that core at $0.01 per OCPU-hour. Container Instances use the same A1 OCPU and memory SKUs. — [Cloud Price List](https://www.oracle.com/cloud/price-list/); [Ampere A1 Compute](https://www.oracle.com/cloud/compute/arm/)
- No Docker prohibition appeared on the Vultr or DigitalOcean pricing pages that were read. That is absence of a ban on those pages, not a vendor sentence that says Docker is allowed.

### Inferences

- An always-on API plus Postgres fits the written “small database / low-traffic / bursty” description of Vultr shared, DigitalOcean Basic, and Akamai shared only while CPU stays inside those vendors’ own limits. Akamai’s published limit is the most concrete: sustained average under 80% including hypervisor overhead. A compile, a migration, or a backup that sits on the CPU can violate that even if the API is quiet.
- Postgres is more sensitive to CPU steal and disk latency than a stateless API. The sources support a distinction between shared and dedicated tiers. They do not support a numeric claim such as “shared CPU is too slow for Postgres” or “it is fine,” because no current benchmark for this stack was collected.
- Oracle’s risk for the free shape is reclamation and Arm images, not the shared-credit model used by Basic Droplets. Official Postgres and Node images have Arm builds in general, but that was not re-checked against Docker Hub on 11 November 2026.
- RackNerd’s “dedicated resources” line and Hostinger’s “dedicated CPU” line are vendor wording on KVM VMs. BuyVM is the only budget host in this set that labels fair-share and dedicated on specific plan rows.

### Gaps

- No steal-time, disk-latency, or noisy-neighbor measurement from November 2026 was found for a Compose stack on these plans.
- Vultr and DigitalOcean were not searched beyond pricing and billing docs for an acceptable-use rule that might restrict Docker or long-running databases.
- Whether BuyVM’s 2-core / 8 GB and 4-core / 16 GB rows are pinned cores or fair-share is not written on those rows.

## Regions for users in the EU and the Philippines

### Takeaway

None of these providers, on the lists checked 11 November 2026, has a Philippines region. Singapore is the common nearby site (Oracle, Vultr, DigitalOcean, Akamai). Akamai and Hostinger also name Jakarta. For the EU, Oracle, Vultr, DigitalOcean, and Akamai all have Frankfurt and at least one of Amsterdam or London. BuyVM’s only European site is Luxembourg. RackNerd’s specials page did not show a European or Asian city as a datacenter.

### Cited Findings

- Oracle’s public regions page, checked 11 November 2026, includes Germany Central (Frankfurt), Netherlands Northwest (Amsterdam), France Central (Paris), France South (Marseille), Italy Northwest (Milan), Spain Central (Madrid), Sweden Central (Stockholm), Switzerland North (Zurich), UK South (London), plus Singapore, Singapore West, Tokyo, Osaka, Seoul, Mumbai, Hyderabad, Sydney, and Melbourne. The extracted region list does not include Manila or Jakarta. Always Free compute still has to be in the tenancy home region, and Chuncheon is excluded for Always Free A1. — [Oracle public cloud regions](https://www.oracle.com/cloud/public-cloud-regions/); [Always Free Resources](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm)
- Egress from an EU or UK Oracle region is in the $0.0085-after-10,240-GB band. Egress from Singapore or Tokyo is in the APAC band at $0.025 per GB after the same free amount. — [Cost estimator product API](https://apexapps.oracle.com/pls/apex/cetools/api/v1/products/)
- BuyVM’s slice FAQ says the slices are in Las Vegas, New York, and Roost, Luxembourg. — [BuyVM KVM slices](https://www.buyvm.net/kvm-dedicated-server-slices)
- RackNerd’s specials page text includes Los Angeles, Chicago, and Dallas as datacenter labels, and also the strings San Jose, Ashburn, Atlanta, New York, and Utah. Amsterdam, Frankfurt, Singapore, and Tokyo did not appear. The page does not say which of those US names are current specials locations. — [RackNerd VPS specials](https://www.racknerd.com/specials/)
- Vultr’s public regions API on 11 November 2026 includes Amsterdam, Frankfurt, London, Paris, Madrid, Stockholm, Warsaw, Singapore, Tokyo, Osaka, Seoul, Mumbai, Bangalore, Delhi, and Sydney. It does not include Manila or Jakarta. The pricing FAQ says some of these locations can have different hourly and monthly prices than the public grid. — [Vultr regions API](https://api.vultr.com/v2/regions); [Vultr pricing](https://www.vultr.com/pricing/)
- DigitalOcean’s regional-availability doc, `last_updated` 2026-10-28, lists 16 datacenters open to new resources, including AMS3 (Amsterdam), FRA1 (Frankfurt), LON1 (London), SGP1 (Singapore), BLR1 (Bangalore), and SYD1 (Sydney). Basic Droplets are marked fully available in AMS3, FRA1, LON1, and SGP1. There is no Manila, Jakarta, or Tokyo datacenter on that list. — [Regional availability](https://docs.digitalocean.com/platform/regional-availability/)
- Akamai’s regions API on 11 November 2026 returned `status: ok` for London, Stockholm, Madrid, Milan, Amsterdam, Frankfurt, Paris, Singapore, Tokyo, Osaka, Jakarta, Mumbai, and Sydney, among others. No Manila region was in the filtered results. Jakarta and Sao Paulo are the two regions with higher shared and dedicated prices in the types API. — [Linode regions API](https://api.linode.com/v4/regions); [Linode types API](https://api.linode.com/v4/linode/types)
- Hostinger’s India VPS page says customers can launch in 10 data centers on 4 continents, “from Boston to Jakarta,” and can move between those 10 locations. The US pricing page says “data centers worldwide” and does not list the 10 cities. A Hostinger comparison page dated 27 October 2026 says Hostinger has 10 data centers. — [Hostinger VPS hosting (India)](https://www.hostinger.com/in/vps-hosting); [Hostinger vs Vultr](https://www.hostinger.com/compare/hostinger-vs-vultr)

### Inferences

- For a single VM that must be acceptable to both EU and Philippine users, Singapore is the site these lists actually share, apart from BuyVM and RackNerd. Jakarta appears only at Akamai (at a higher list price) and in Hostinger’s Boston-to-Jakarta claim. A Luxembourg or US-only host leaves one of the two audiences on a long path. None of the sources here quantify that latency.
- Putting the VM in Frankfurt or Amsterdam favors EU users and leaves Philippine users on an intercontinental path. Oracle’s APAC egress rate is also higher than its EU rate once the free 10,240 GB is passed, which matters if the home region is Singapore.
- Two regions would cover the two audiences more evenly. That doubles the VM, and it splits Postgres unless the product can tolerate separate data. This note does not price replication.

### Gaps

- Hostinger’s full list of 10 cities was not on the pages that were read, so an EU city is not confirmed, even though “Boston to Jakarta” implies sites on more than one continent.
- RackNerd’s exact orderable location list for the annual specials was not isolated from other city names on the page.
- No round-trip latency figures from the Philippines or from a specific EU country to these sites were collected.
- Live capacity for Oracle Always Free in Frankfurt, Amsterdam, or Singapore was not available.
