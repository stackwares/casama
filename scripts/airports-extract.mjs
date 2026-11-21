#!/usr/bin/env node
/**
 * Builds packages/agent/src/live-data/airports.json (docs/FLIGHT-SEARCH-PLAN.md §6) from OurAirports'
 * airports.csv (public domain, https://ourairports.com/data/). Only airports with scheduled service
 * and an IATA code are kept, as [iata, name, city, country, lat, lng, size] with size 2 = large,
 * 1 = medium, 0 = small.
 *
 *   curl -sSfLo /tmp/airports.csv https://davidmegginson.github.io/ourairports-data/airports.csv
 *   node scripts/airports-extract.mjs /tmp/airports.csv
 *   pnpm exec biome format --write packages/agent/src/live-data/airports.json
 */
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const src = process.argv[2];
if (!src) {
  console.error("usage: node scripts/airports-extract.mjs <airports.csv>");
  process.exit(1);
}

/** One CSV line into fields (quoted fields may hold commas and doubled quotes). */
function fields(line) {
  const out = [];
  let cur = "";
  let q = false;
  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (q) {
      if (c === '"' && line[i + 1] === '"') {
        cur += '"';
        i++;
      } else if (c === '"') q = false;
      else cur += c;
    } else if (c === '"') q = true;
    else if (c === ",") {
      out.push(cur);
      cur = "";
    } else cur += c;
  }
  out.push(cur);
  return out;
}

const lines = readFileSync(src, "utf8").split(/\r?\n/).filter(Boolean);
const head = fields(lines[0]);
const col = (name) => {
  const i = head.indexOf(name);
  if (i < 0) throw new Error(`airports.csv has no ${name} column`);
  return i;
};
const C = {
  type: col("type"),
  name: col("name"),
  lat: col("latitude_deg"),
  lng: col("longitude_deg"),
  country: col("iso_country"),
  city: col("municipality"),
  scheduled: col("scheduled_service"),
  iata: col("iata_code"),
};
const SIZE = { large_airport: 2, medium_airport: 1, small_airport: 0 };
const seen = new Set();
const rows = [];
for (const line of lines.slice(1)) {
  const f = fields(line);
  const iata = (f[C.iata] ?? "").trim().toUpperCase();
  if (!/^[A-Z]{3}$/.test(iata) || f[C.scheduled] !== "yes" || !(f[C.type] in SIZE)) continue;
  if (seen.has(iata)) continue;
  seen.add(iata);
  rows.push([
    iata,
    f[C.name].trim(),
    (f[C.city] ?? "").trim(),
    f[C.country].trim(),
    Math.round(Number(f[C.lat]) * 100) / 100,
    Math.round(Number(f[C.lng]) * 100) / 100,
    SIZE[f[C.type]],
  ]);
}
rows.sort((a, b) => (a[0] < b[0] ? -1 : 1));
const out = join(
  dirname(fileURLToPath(import.meta.url)),
  "../packages/agent/src/live-data/airports.json",
);
writeFileSync(out, `${JSON.stringify(rows).replaceAll("],[", "],\n[")}\n`);
console.log(`${rows.length} airports → ${out}`);
