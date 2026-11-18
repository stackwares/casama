/**
 * Signs the gallery's manifest.json (D-315). CI runs it after `node check.mjs`; servers check the
 * signature with the public key before they trust any of the gallery's JSON files.
 *   GALLERY_SIGNING_KEY=... node sign.mjs   write manifest.sig (base64 Ed25519 over manifest.json)
 *   node sign.mjs --verify <public key>     check manifest.sig against a base64 raw public key
 *   node sign.mjs --gen-key                 print a new key pair (keep the private key secret)
 * GALLERY_SIGNING_KEY is a PKCS8 PEM or a base64 raw 32-byte seed. No toolchain, only node.
 */
import { createPrivateKey, createPublicKey, generateKeyPairSync, sign, verify } from "node:crypto";
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const root = import.meta.dirname;
const SPKI_ED25519 = Buffer.from("302a300506032b6570032100", "hex");
const PKCS8_ED25519 = Buffer.from("302e020100300506032b657004220420", "hex");

function privateKey(value) {
  const v = value.trim();
  if (v.includes("-----BEGIN")) return createPrivateKey(v);
  const seed = Buffer.from(v, "base64");
  if (seed.length !== 32) throw new Error("GALLERY_SIGNING_KEY must be a PKCS8 PEM or a 32-byte seed in base64");
  return createPrivateKey({ key: Buffer.concat([PKCS8_ED25519, seed]), format: "der", type: "pkcs8" });
}

function publicKey(base64) {
  const raw = Buffer.from(base64.trim(), "base64");
  if (raw.length !== 32) throw new Error("the public key must be 32 bytes in base64");
  return createPublicKey({ key: Buffer.concat([SPKI_ED25519, raw]), format: "der", type: "spki" });
}

const args = process.argv.slice(2);
if (args.includes("--gen-key")) {
  const pair = generateKeyPairSync("ed25519");
  const spki = pair.publicKey.export({ format: "der", type: "spki" });
  console.log("Private key (GALLERY_SIGNING_KEY, keep it secret):");
  console.log(pair.privateKey.export({ format: "pem", type: "pkcs8" }).toString().trim());
  console.log("\nPublic key (GALLERY_PUBLIC_KEY, base64 raw 32 bytes):");
  console.log(spki.subarray(spki.length - 32).toString("base64"));
  process.exit(0);
}

const manifest = readFileSync(join(root, "manifest.json"));
const verifyAt = args.indexOf("--verify");
if (verifyAt !== -1) {
  const key = args[verifyAt + 1];
  if (!key) {
    console.error("usage: node sign.mjs --verify <base64 public key>");
    process.exit(2);
  }
  const sig = Buffer.from(readFileSync(join(root, "manifest.sig"), "utf8").trim(), "base64");
  const ok = sig.length === 64 && verify(null, manifest, publicKey(key), sig);
  console.log(ok ? "manifest.sig is valid" : "manifest.sig does NOT match");
  process.exit(ok ? 0 : 1);
}

const secret = process.env.GALLERY_SIGNING_KEY;
if (!secret) {
  console.error("GALLERY_SIGNING_KEY is not set, so manifest.sig was not written.");
  process.exit(1);
}
const key = privateKey(secret);
const signature = sign(null, manifest, key).toString("base64");
// Check our own work with the matching public key before publishing it.
if (!verify(null, manifest, createPublicKey(key), Buffer.from(signature, "base64"))) {
  console.error("the new signature didn't verify; nothing written");
  process.exit(1);
}
writeFileSync(join(root, "manifest.sig"), `${signature}\n`);
console.log("wrote manifest.sig");
