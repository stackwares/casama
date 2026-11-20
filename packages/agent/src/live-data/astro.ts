/**
 * Sun and moon (RICH-CARDS-PLAN §7.5), worked out locally: no provider. The formulas follow
 * SunCalc by Vladimir Agafonkin (BSD-2-Clause, THIRD_PARTY_NOTICES.md), from Astronomy Answers.
 */
const rad = Math.PI / 180;
const dayMs = 86400000;
const J1970 = 2440588;
const J2000 = 2451545;
const e = rad * 23.4397;

const toJulian = (d: Date) => d.valueOf() / dayMs - 0.5 + J1970;
const fromJulian = (j: number) => new Date((j + 0.5 - J1970) * dayMs);
const toDays = (d: Date) => toJulian(d) - J2000;

const rightAscension = (l: number, b: number) =>
  Math.atan2(Math.sin(l) * Math.cos(e) - Math.tan(b) * Math.sin(e), Math.cos(l));
const declination = (l: number, b: number) =>
  Math.asin(Math.sin(b) * Math.cos(e) + Math.cos(b) * Math.sin(e) * Math.sin(l));
const azimuth = (H: number, phi: number, dec: number) =>
  Math.atan2(Math.sin(H), Math.cos(H) * Math.sin(phi) - Math.tan(dec) * Math.cos(phi));
const altitude = (H: number, phi: number, dec: number) =>
  Math.asin(Math.sin(phi) * Math.sin(dec) + Math.cos(phi) * Math.cos(dec) * Math.cos(H));
const siderealTime = (d: number, lw: number) => rad * (280.16 + 360.9856235 * d) - lw;
const solarMeanAnomaly = (d: number) => rad * (357.5291 + 0.98560028 * d);
function eclipticLongitude(M: number) {
  const C = rad * (1.9148 * Math.sin(M) + 0.02 * Math.sin(2 * M) + 0.0003 * Math.sin(3 * M));
  const P = rad * 102.9372;
  return M + C + P + Math.PI;
}
function sunCoords(d: number) {
  const M = solarMeanAnomaly(d);
  const L = eclipticLongitude(M);
  return { dec: declination(L, 0), ra: rightAscension(L, 0) };
}

/** The sun's height above the horizon in degrees, and its compass direction (0 = north). */
export function sunPosition(date: Date, lat: number, lng: number) {
  const lw = rad * -lng;
  const phi = rad * lat;
  const d = toDays(date);
  const c = sunCoords(d);
  const H = siderealTime(d, lw) - c.ra;
  return {
    altitude: altitude(H, phi, c.dec) / rad,
    azimuth: (((azimuth(H, phi, c.dec) / rad + 180) % 360) + 360) % 360,
  };
}

const J0 = 0.0009;
const julianCycle = (d: number, lw: number) => Math.round(d - J0 - lw / (2 * Math.PI));
const approxTransit = (Ht: number, lw: number, n: number) => J0 + (Ht + lw) / (2 * Math.PI) + n;
const solarTransitJ = (ds: number, M: number, L: number) =>
  J2000 + ds + 0.0053 * Math.sin(M) - 0.0069 * Math.sin(2 * L);
const hourAngle = (h: number, phi: number, d: number) =>
  Math.acos((Math.sin(h) - Math.sin(phi) * Math.sin(d)) / (Math.cos(phi) * Math.cos(d)));
const observerAngle = (height: number) => (-2.076 * Math.sqrt(height)) / 60;

export interface SunTimes {
  sunrise: Date | null;
  sunset: Date | null;
  solarNoon: Date;
  dawn: Date | null;
  dusk: Date | null;
  goldenMorningEnd: Date | null;
  goldenEveningStart: Date | null;
  /** Always up (polar day) or never up (polar night) on this date. */
  polar?: "day" | "night";
}

/** Sunrise, sunset, twilight and golden hours on the day that contains [date] (UTC noon based). */
export function sunTimes(date: Date, lat: number, lng: number, height = 0): SunTimes {
  const lw = rad * -lng;
  const phi = rad * lat;
  const dh = observerAngle(height);
  const d = toDays(date);
  const n = julianCycle(d, lw);
  const ds = approxTransit(0, lw, n);
  const M = solarMeanAnomaly(ds);
  const L = eclipticLongitude(M);
  const dec = declination(L, 0);
  const Jnoon = solarTransitJ(ds, M, L);
  const at = (deg: number) => {
    const h0 = (deg + dh) * rad;
    const w = hourAngle(h0, phi, dec);
    if (Number.isNaN(w)) return null;
    const a = approxTransit(w, lw, n);
    const Jset = solarTransitJ(a, M, L);
    const Jrise = Jnoon - (Jset - Jnoon);
    return { rise: fromJulian(Jrise), set: fromJulian(Jset) };
  };
  const sun = at(-0.833);
  const civil = at(-6);
  const golden = at(6);
  const polar = sun
    ? undefined
    : sunPosition(fromJulian(Jnoon), lat, lng).altitude > 0
      ? "day"
      : "night";
  return {
    sunrise: sun?.rise ?? null,
    sunset: sun?.set ?? null,
    solarNoon: fromJulian(Jnoon),
    dawn: civil?.rise ?? null,
    dusk: civil?.set ?? null,
    goldenMorningEnd: golden?.rise ?? null,
    goldenEveningStart: golden?.set ?? null,
    ...(polar ? { polar } : {}),
  };
}

function moonCoords(d: number) {
  const L = rad * (218.316 + 13.176396 * d);
  const M = rad * (134.963 + 13.064993 * d);
  const F = rad * (93.272 + 13.22935 * d);
  const l = L + rad * 6.289 * Math.sin(M);
  const b = rad * 5.128 * Math.sin(F);
  const dt = 385001 - 20905 * Math.cos(M);
  return { ra: rightAscension(l, b), dec: declination(l, b), dist: dt };
}

/** The moon's lit fraction (0–1) and phase (0 new, 0.25 first quarter, 0.5 full, 0.75 last quarter). */
export function moonIllumination(date: Date) {
  const d = toDays(date);
  const s = sunCoords(d);
  const m = moonCoords(d);
  const sdist = 149598000;
  const phi = Math.acos(
    Math.sin(s.dec) * Math.sin(m.dec) + Math.cos(s.dec) * Math.cos(m.dec) * Math.cos(s.ra - m.ra),
  );
  const inc = Math.atan2(sdist * Math.sin(phi), m.dist - sdist * Math.cos(phi));
  const angle = Math.atan2(
    Math.cos(s.dec) * Math.sin(s.ra - m.ra),
    Math.sin(s.dec) * Math.cos(m.dec) - Math.cos(s.dec) * Math.sin(m.dec) * Math.cos(s.ra - m.ra),
  );
  return {
    fraction: (1 + Math.cos(inc)) / 2,
    phase: 0.5 + (0.5 * inc * (angle < 0 ? -1 : 1)) / Math.PI,
  };
}

function moonAltitude(date: Date, lat: number, lng: number) {
  const lw = rad * -lng;
  const phi = rad * lat;
  const d = toDays(date);
  const c = moonCoords(d);
  const H = siderealTime(d, lw) - c.ra;
  let h = altitude(H, phi, c.dec);
  h += (rad * 0.017) / Math.tan(h + (rad * 10.26) / (h + rad * 5.1)); // refraction
  return h;
}

/** Moonrise and moonset within 24 hours from [start] (the local midnight), by stepping hours. */
export function moonTimes(start: Date, lat: number, lng: number) {
  const hc = 0.133 * rad;
  const at = (h: number) => new Date(start.valueOf() + h * 3600000);
  let h0 = moonAltitude(start, lat, lng) - hc;
  let rise: number | undefined;
  let set: number | undefined;
  for (let i = 1; i <= 24; i += 2) {
    const h1 = moonAltitude(at(i), lat, lng) - hc;
    const h2 = moonAltitude(at(i + 1), lat, lng) - hc;
    const a = (h0 + h2) / 2 - h1;
    const b = (h2 - h0) / 2;
    const xe = -b / (2 * a);
    const ye = (a * xe + b) * xe + h1;
    const dd = b * b - 4 * a * h1;
    let roots = 0;
    let x1 = 0;
    let x2 = 0;
    if (dd >= 0) {
      const dx = Math.sqrt(dd) / (Math.abs(a) * 2);
      x1 = xe - dx;
      x2 = xe + dx;
      if (Math.abs(x1) <= 1) roots++;
      if (Math.abs(x2) <= 1) roots++;
      if (x1 < -1) x1 = x2;
    }
    if (roots === 1) {
      if (h0 < 0) rise = i + x1;
      else set = i + x1;
    } else if (roots === 2) {
      rise = i + (ye < 0 ? x2 : x1);
      set = i + (ye < 0 ? x1 : x2);
    }
    if (rise !== undefined && set !== undefined) break;
    h0 = h2;
  }
  return {
    rise: rise === undefined ? null : at(rise),
    set: set === undefined ? null : at(set),
  };
}

/** The phase's name, for the card and its spoken summary. */
export function moonPhaseName(phase: number) {
  const p = ((phase % 1) + 1) % 1;
  if (p < 0.03 || p > 0.97) return "new_moon";
  if (p < 0.22) return "waxing_crescent";
  if (p < 0.28) return "first_quarter";
  if (p < 0.47) return "waxing_gibbous";
  if (p < 0.53) return "full_moon";
  if (p < 0.72) return "waning_gibbous";
  if (p < 0.78) return "last_quarter";
  return "waning_crescent";
}
