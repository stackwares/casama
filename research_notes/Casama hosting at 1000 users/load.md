# Casama hosting load at 1,000 monthly users

Scope is load (RAM and disk) taken from Casama’s own writing. Prices below are the project’s figures. This note did not reopen vendor pricing pages. It does not choose a host. Figures marked as estimates are planning arithmetic, not measurements from production.

Sources read:

- [docs/COSTS.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs/COSTS.md) (vendor list prices recorded as checked 2026-11-11)
- [docs-site/self-hosting/index.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs-site/self-hosting/index.md) (hardware section)
- [docs-site/self-hosting/operations.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs-site/self-hosting/operations.md) (memory per computer)

## How much RAM does one headless computer take?

### Takeaway

Use **1 GB** as the current headless default from the cost model, and **about 2 GB** as the cautious figure still printed in the self-hosting guide. The two documents disagree, and neither page is dated against the other.

### Cited Findings

- The cost model marks this as done: headless computers default to **1 vCPU / 1 GB** (it says “instead of 4 GB”); a desktop is only when needed. The same page later says self-host templates, if E2B is used, should be built at **1 vCPU / 1 GB (headless)** and **2 vCPU / 4 GB (desktop)**. — [docs/COSTS.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs/COSTS.md)
- The same cost model’s Docker rate example is **1 vCPU / 1 GB ≈ $0.008 / hour** (`$0.003` per vCPU-hour + `$0.005` per GB-hour). E2B and Daytona are quoted at a larger size, **2 vCPU / 4 GiB ≈ $0.166 / hour**, and are described as optional adapters. The page says Casama itself runs computers on Docker. — [docs/COSTS.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs/COSTS.md)
- The install guide’s hardware line is: **“4 vCPU and 8 GB RAM for a few computers at once. Plan on about 2 GB RAM per running computer.”** The installer warns below about **8 GB** of memory, “because computers may not start reliably.” — [docs-site/self-hosting/index.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs-site/self-hosting/index.md)
- The operations guide says **`COMPUTER_MEMORY_MB` (default `2048`)** sets each new computer’s memory, plus **1 CPU**, **512 processes**, a **1 GB `/tmp`**, and **512 MB of shared memory**. Its planning sentence is: **“Plan host memory as about 2 GB per running computer, plus the stack itself.”** — [docs-site/self-hosting/operations.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs-site/self-hosting/operations.md)
- The Helm table repeats **`computers.memoryMb` = `2048`**, passed through as `COMPUTER_MEMORY_MB`, and says **only the Docker provider reads it**. Computer pods get no limits from that setting. — [docs-site/self-hosting/operations.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs-site/self-hosting/operations.md)
- A warm pool (`WARM_POOL_SIZE`) keeps headless computers started and unassigned. **“Each pool member uses memory while it waits.”** Desktop and custom-size computers start cold. No pool count is given on that page. — [docs-site/self-hosting/operations.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs-site/self-hosting/operations.md)
- Idle computers are archived and stopped so only computers in use take memory. The operations page says **after 10 minutes** without activity. The cost model says sleep **after 5 minutes idle instead of 10** (D-178), and that live viewers and open terminals keep a computer awake. — [docs-site/self-hosting/operations.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs-site/self-hosting/operations.md); [docs/COSTS.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs/COSTS.md)

### Inferences

- The **1 GB** column below follows the cost model’s stated headless default. The **2 GB** column follows the guide’s “about 2 GB” rule, which matches that guide’s `2048` MB default. Treat 2 GB as the cautious planning figure while the guide still says 2048.
- The guide’s own “about 2 GB” sentence lines up with 2048 MB. This note does not add the 1 GB `/tmp` or the 512 MB shared memory on top of that. The pages never say those sit outside the memory limit.
- RAM follows computers **awake** (in use, or sitting in the warm pool), not the count of monthly users. A desktop awake at the cost model’s **4 GB** is four times the 1 GB headless figure.

### Gaps

- These pages do not say which document was edited last, so “the guide is older” is the assignment’s description, not a date in the files.
- They do not say whether `/tmp` and shared memory are inside the cgroup limit.
- They do not give a number for `WARM_POOL_SIZE`.
- They disagree on idle sleep (**5 minutes** in the cost model, **10 minutes** in the operations guide). That does not change the arithmetic for a stated awake count. It does change how long an idle computer holds RAM.

## How much RAM do 15, 30, and 100 awake computers need?

### Takeaway

For the three planning peaks, estimated RAM is **awake computers × GB each, plus 6 GB** for the API, the worker, and Postgres. At **1 GB** each that is **21 GB, 36 GB, and 106 GB**. At the guide’s **2 GB** it is **36 GB, 66 GB, and 206 GB**. These are estimates. The files do not measure how many computers are awake among 1,000 monthly users.

### Cited Findings

- Headless default in the cost model: **1 GB**. Guide planning figure: **about 2 GB**, with default **`COMPUTER_MEMORY_MB` = 2048**. — [docs/COSTS.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs/COSTS.md); [docs-site/self-hosting/index.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs-site/self-hosting/index.md); [docs-site/self-hosting/operations.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs-site/self-hosting/operations.md)
- The operations page says to plan computer memory **“plus the stack itself”** and does not give the stack a gigabyte figure. The install minimum is **8 GB RAM for a few computers at once**, also without a per-service split. — [docs-site/self-hosting/operations.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs-site/self-hosting/operations.md); [docs-site/self-hosting/index.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs-site/self-hosting/index.md)
- One install can put the whole stack on one machine: Postgres (`db`), API, worker, supervisor, egress, TURN, and Caddy. The operations page also allows computers on a **second host**, with the supervisor, egress proxy, and TURN relay on that computer host, and the database on the app host. — [docs-site/self-hosting/index.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs-site/self-hosting/index.md); [docs-site/self-hosting/operations.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs-site/self-hosting/operations.md)
- Supabase Cloud is listed at **from $25 / month**, including **8 GB database** and **100k monthly active users**, only if Postgres is not self-hosted. That 100k figure is a vendor inclusion in the cost model, not a Casama concurrency measurement. — [docs/COSTS.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs/COSTS.md)

### Inferences

The **6 GB** added below is an **estimate set for this note** for the API, the worker, and Postgres together. It is not a number printed in the three files. It is added once per peak, not once per computer. It does not include Caddy, Supabase Auth, REST, Realtime, the supervisor, egress, or TURN. Those are in the install guide and have no RAM figures here.

The awake counts **15, 30, and 100** are the three peak cases set for 1,000 monthly users. They are not derived from the docs.

Formula: **total ≈ (computers awake × GB per computer) + 6 GB**.

| Computers awake at once | At 1 GB headless (cost-model default) | At about 2 GB (self-hosting guide) |
| --- | --- | --- |
| 15 | 15 × 1 + 6 = **21 GB** | 15 × 2 + 6 = **36 GB** |
| 30 | 30 × 1 + 6 = **36 GB** | 30 × 2 + 6 = **66 GB** |
| 100 | 100 × 1 + 6 = **106 GB** | 100 × 2 + 6 = **206 GB** |

All six totals are estimates. If some of those awake computers are desktops, the cost model’s desktop size is **2 vCPU / 4 GB**, so each desktop replaces 1 GB (or the guide’s 2 GB) with 4 GB in the computer term. Example, still an estimate: 100 desktops would be 100 × 4 + 6 = **406 GB**. The peak cases above assume the headless size.

Computer RAM and the 6 GB need not be one machine. The guide allows a separate computer host. The sum is still the RAM to provide across hosts.

### Gaps

- No measured fraction of 1,000 monthly users with a computer awake. No p50 or p95 concurrency.
- No measured RAM for the API, worker, or Postgres, and none for the rest of the stack. The 6 GB allowance can be low or high relative to a real process list.
- Warm-pool members count as awake RAM and are not inside the 15 / 30 / 100 unless the operator included them.

## Why are model, image, and video fees not hosting fees?

### Takeaway

Model, image, and video charges in the cost model are **per-use API prices**. They move with tokens, images, and seconds of video. Hosting load is the machine that stays up (RAM, disk, and the fixed server line). A month with heavy video and a month with none can share the same RAM peak.

### Cited Findings

- The cost model splits **fixed costs** (“paid whether or not anyone uses it”) from **usage costs** (“scale with what people do”). The fixed server line is “Server for API, worker, database.” Models, images, and video are in the usage table. — [docs/COSTS.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs/COSTS.md)
- **Models on Casama’s keys** are priced **per 1M tokens in / out** (examples on that page include GPT-6.1 Sol $2 / $10, Claude Opus 5.5 $4 / $20, Gemini 3.1 Pro $2 / $12, Grok 4.7 $2 / $6). Metering is `tokens_in` / `tokens_out`, from OpenRouter’s reported cost when present, otherwise a live price list. Through OpenRouter the page adds **5.5%** on credit purchases. On Casama’s key with billing on, the written charge is that cost × 1.055 × 1.3. — [docs/COSTS.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs/COSTS.md)
- **Bring-your-own keys and the ChatGPT plan cost Casama nothing for models:** the run is logged with `cost_usd = 0` (or `source = chatgpt_plan`). Computers on Casama’s side are still Casama’s to cover. — [docs/COSTS.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs/COSTS.md)
- **Images** are **per image**. The page’s 1K examples include Gemini Nano Banana 2.1 at **$0.034** on OpenRouter and GPT Image 2.6 medium at about **$0.043**. Metering is `media_images` at OpenRouter’s reported cost or fal’s list price; unknown models at **$0.04**. — [docs/COSTS.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs/COSTS.md)
- **Video** is **per second**. Gemini Omni Flash 1.2 at 720p is about **$0.07 a second** when a Google AI key exists; the meter is `media_video_seconds` at **$0.0695 a second** for Omni Flash, or fal’s list price (examples on the page: PixVerse V6 $0.005, MiniMax H3 Max Turbo $0.025, Grok Imagine $0.05, LTX about $0.04–0.10). Unknown models are **$0.10 / second**. — [docs/COSTS.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs/COSTS.md)
- The opening of the cost model says self-hosted servers **pay their own vendors** and that this Cloud price list does not apply to them. The install guide says self-hosted Casama has **no paywall and no usage limits** because billing is off in the bundled stack. The RAM and disk of that stack are still there. — [docs/COSTS.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs/COSTS.md); [docs-site/self-hosting/index.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs-site/self-hosting/index.md)

### Inferences

- A hosting estimate for 1,000 monthly users can state RAM and disk without a model, image, or video dollar total. Those dollars need a usage assumption (tokens, images, seconds) the three files do not give for 1,000 people.
- Zero model spend (everyone on their own key) does not remove computer RAM. The cost model treats computers as Casama’s cost even when model `cost_usd` is 0.
- File storage on R2 (**$0.015 per GB-month**) and Supabase storage (**$0.0213 per GB**) are also usage-shaped storage prices, separate from the Postgres chat question below. The page says file storage is not metered and should be capped per plan.

### Gaps

- No tokens, images, or video seconds per user, so no API bill for 1,000 monthly users can be computed from these files.
- Voice, phone, search, and Composio are also usage APIs in the same table. They are outside this question. They are also not RAM.

## What disk growth should Postgres see if each user has chats?

### Takeaway

The docs **do not give a Postgres growth number** for chats, per user or per message. This note does not invent one. What they do give is a **minimum disk of 40 GB or more**, of which **images take about 6 GB**, with home folders and snapshots taking the rest. That 6 GB is container images on disk, not chat rows, and it is not the 6 GB RAM allowance above.

### Cited Findings

- Hardware disk line: **“40 GB or more. The images take about 6 GB; home folders and snapshots take the rest.”** — [docs-site/self-hosting/index.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs-site/self-hosting/index.md)
- A fresh install downloads **about 3 GB of third-party images** besides building Casama’s own images (API, worker, supervisor, egress, TURN, and the headless computer image). — [docs-site/self-hosting/index.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs-site/self-hosting/index.md)
- Postgres is the `db` service: **Supabase Postgres 17**, described as holding all data, including encrypted secrets in Supabase Vault. The worker’s job list includes chats. Realtime “streams chat and run updates.” None of those lines states a row size or a growth rate. — [docs-site/self-hosting/index.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs-site/self-hosting/index.md)
- Backups include `postgres.dump` (a full `pg_dump`) and, optionally, computer archives. The operations page never states how large that dump is or how fast it grows. The Helm chart gives the supervisor a **20 Gi** volume for **computer archives**, one replica, not for chat rows. — [docs-site/self-hosting/operations.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs-site/self-hosting/operations.md)
- If Cloud uses Supabase instead of self-hosted Postgres, the cost model says that plan **includes 8 GB database**. That is an included allowance on a vendor plan, not a measured size of Casama chats. Off-site dumps go to R2 (`casama-backups`): **$0 within 10 GB-month**, then **$0.015 per GB-month**, **14 days kept**. — [docs/COSTS.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs/COSTS.md)

### Inferences

- Disk planning from these pages can start from **at least 40 GB**, with about **6 GB** already spoken for by images, plus whatever home folders and snapshots accumulate per awake computer’s files. That is computer-related disk. It is not a forecast of the Postgres data directory at 1,000 users.
- Chat text lives in Postgres on this architecture, so it grows with use, and the backup is a full dump kept 14 days when that job is on. Without a bytes-per-chat figure, the growth term stays unknown.

### Gaps

- No bytes per message, per conversation, or per user.
- No measured size of `postgres.dump` at any user count.
- No statement of how large home folders or snapshots are per computer. “Take the rest” is not a gigabyte rate.

## What does the cost model claim for a Hetzner AX102?

### Takeaway

Quoted from the project, and **not rechecked** against Hetzner: an AX102 is **16 cores, 128 GB, €159 / month**, and **“holds about 28 standard computers”** because bots mostly wait on the model, so **CPU can be shared and memory is the limit**, at about **$0.01 per computer-hour** against about **$0.17** on E2B or Daytona. That is Casama’s figure in `docs/COSTS.md`. This note did not open the vendor page.

### Cited Findings

- Exact claim, under “Bot computers on our own dense servers”: **“a dedicated server such as Hetzner AX102 (16 cores, 128 GB, €159 / month) holds about 28 standard computers, because bots mostly wait on the model (CPU can be shared; memory is the limit). That is about $0.01 per computer-hour against $0.17 on E2B or Daytona.”** The line is marked not done: **“Needs a server.”** — [docs/COSTS.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs/COSTS.md)
- The sources list for that file, dated **checked 2026-11-11**, points at `hetzner.com/cloud` and `hetzner.com/dedicated-rootserver/matrix-ax` among other vendors. This research used the file and did not fetch those pages. — [docs/COSTS.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs/COSTS.md)
- Elsewhere the same file prices a smaller machine, **Hetzner CPX42, 8 vCPU / 16 GB**, at **€59.49–69.99 / month**, and says a CPX42 **“runs about 4 computers of that size”** (the size in that sentence is the **2 vCPU / 4 GiB** E2B/Daytona computer) for **€65 / month**, about **$0.025 / hour each if fully used**. EU servers are described as the cheap side; **“US ones cost about twice as much.”** — [docs/COSTS.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs/COSTS.md)
- The fixed-cost floor **before the first paying user** is written as **roughly $110–150 a month** (server, Sentry, Composio Pro, mailboxes, domain, Apple), **plus E2B’s $150** if computers run on E2B. That floor is a Cloud vendor mix, not the RAM table above. — [docs/COSTS.md](file:///Users/nemoryoliver/Desktop/Projects/Kasama/docs/COSTS.md)

### Inferences

- **“About 28” is the project’s packing claim, not a division shown in the file.** One reading that uses only numbers on the page: 28 × 4 GB = **112 GB**, which leaves **16 GB** of the stated **128 GB**. That lines up with memory as the limit and with the **4 GB** size the next bullet says headless replaced. The file never writes “128 ÷ 4” or “112”. At the **1 GB** headless default, 28 × 1 GB = **28 GB** of computer RAM, which would leave most of 128 GB unused if memory were the only limit. So the “about 28 standard computers” sentence fits the **4 GB** size better than the **1 GB** headless default. Both sizes appear on the same page. The file does not define the word “standard” in that sentence.
- The **$0.01 per computer-hour** is the project’s stated result. The page does not show the hours-in-a-month divisor or the euro-to-dollar rate. This note does not invent them. For scale only, the same page’s other own-server figure is about **$0.025 / hour** on a busy CPX42, and the E2B/Daytona comparison used next to the AX102 is about **$0.17 / hour** (the usage table’s matching figure is **≈ $0.166 / hour**).
- Comparing the project’s **128 GB** label to this note’s estimates, without choosing that server: **106 GB** (100 awake × 1 GB + 6 GB) is under 128 GB, and **206 GB** (100 awake × 2 GB + 6 GB) is over 128 GB. That comparison is RAM arithmetic only. It ignores CPU oversubscription, disk, the operating system, the warm pool, desktops at 4 GB, and services outside the 6 GB allowance. The project’s own packing claim is **about 28** computers of the larger “standard” size, not 100.

### Gaps

- AX102 cores, RAM, and **€159 / month** were not rechecked on Hetzner’s site. If the vendor page has moved since the file’s 2026-11-11 check, this note would not show it.
- The file does not show the arithmetic behind “about 28” or behind “about $0.01 per computer-hour.”
- No statement of how many AX102-class machines 1,000 monthly users would require. That would need the missing concurrency rate.
