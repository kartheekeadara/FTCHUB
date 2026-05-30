#!/usr/bin/env node
// Uploads the built manifest (and any chunk files) to Supabase Storage.
// Keeps the last good manifest — only overwrites on full success.

import fs from "node:fs/promises";
import path from "node:path";
import "dotenv/config";

const {
  OUTPUT_DIR = "./dist",
  MANIFEST_FILENAME = "manifest.json",
  SUPABASE_URL,
  SUPABASE_SERVICE_ROLE_KEY,
  SUPABASE_BUCKET = "catalog",
  SUPABASE_MANIFEST_PATH = "parts/manifest.json",
} = process.env;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY.");
  process.exit(1);
}

async function upload(localPath, remotePath, contentType = "application/json") {
  const body = await fs.readFile(localPath);
  const url = `${SUPABASE_URL}/storage/v1/object/${SUPABASE_BUCKET}/${remotePath}`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      "Content-Type": contentType,
      "x-upsert": "true",
    },
    body,
  });
  if (!res.ok) throw new Error(`Upload ${remotePath} failed: ${res.status} ${await res.text()}`);
  console.log(`Uploaded ${remotePath}`);
}

async function main() {
  const manifestDir = path.dirname(SUPABASE_MANIFEST_PATH);

  // Upload chunks first (so app never sees a manifest referencing missing chunks).
  const files = await fs.readdir(OUTPUT_DIR);
  const chunkFiles = files.filter((f) => f.startsWith("parts-") && f.endsWith(".json"));
  for (const f of chunkFiles) {
    await upload(path.join(OUTPUT_DIR, f), `${manifestDir}/${f}`);
  }

  await upload(path.join(OUTPUT_DIR, MANIFEST_FILENAME), SUPABASE_MANIFEST_PATH);

  const publicURL = `${SUPABASE_URL}/storage/v1/object/public/${SUPABASE_BUCKET}/${SUPABASE_MANIFEST_PATH}`;
  console.log(`\nSet PARTS_CATALOG_MANIFEST_URL to:\n  ${publicURL}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
