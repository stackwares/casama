/**
 * Profile photos (D-202): checking an uploaded picture, and finding and fetching the photo a
 * sign-in provider shares. Kept apart from the routes so it can be tested without a database.
 */

export const MAX_PHOTO_BYTES = 1024 * 1024;

export type PhotoType = "image/jpeg" | "image/png" | "image/webp";

/** The picture's real type from its first bytes, or null when it's none of the three we keep. */
export function sniffPhotoType(b: Uint8Array): PhotoType | null {
  if (b.length >= 3 && b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff) return "image/jpeg";
  if (
    b.length >= 8 &&
    b[0] === 0x89 &&
    b[1] === 0x50 &&
    b[2] === 0x4e &&
    b[3] === 0x47 &&
    b[4] === 0x0d &&
    b[5] === 0x0a &&
    b[6] === 0x1a &&
    b[7] === 0x0a
  )
    return "image/png";
  if (
    b.length >= 12 &&
    String.fromCharCode(b[0]!, b[1]!, b[2]!, b[3]!) === "RIFF" &&
    String.fromCharCode(b[8]!, b[9]!, b[10]!, b[11]!) === "WEBP"
  )
    return "image/webp";
  return null;
}

/**
 * The provider's photo address from the sign-in metadata, asked for at 512 px, or null. Only
 * Google's photo host is fetched, so the server never follows an address someone typed in.
 */
export function providerPhotoUrl(meta: Record<string, unknown> | null | undefined): string | null {
  const raw = [meta?.avatar_url, meta?.picture].find((v) => typeof v === "string" && v);
  if (typeof raw !== "string") return null;
  let u: URL;
  try {
    u = new URL(raw);
  } catch {
    return null;
  }
  if (u.protocol !== "https:" || !/(^|\.)googleusercontent\.com$/.test(u.hostname)) return null;
  // Google sizes its photos with a "=s96-c" suffix; ask for 512 px instead.
  const sized = u.pathname.replace(/=s\d+(-c)?$/, "=s512-c");
  u.pathname = sized === u.pathname && !u.pathname.includes("=") ? `${sized}=s512-c` : sized;
  return u.toString();
}

/** Downloads a provider photo, or null when it can't be had (offline, too big, not a picture). */
export async function fetchProviderPhoto(
  url: string,
  fetcher: typeof fetch = fetch,
): Promise<{ bytes: Uint8Array; type: PhotoType } | null> {
  try {
    const res = await fetcher(url, { redirect: "error", signal: AbortSignal.timeout(8000) });
    if (!res.ok) return null;
    const bytes = new Uint8Array(await res.arrayBuffer());
    if (bytes.length === 0 || bytes.length > MAX_PHOTO_BYTES) return null;
    const type = sniffPhotoType(bytes);
    return type ? { bytes, type } : null;
  } catch {
    return null;
  }
}
