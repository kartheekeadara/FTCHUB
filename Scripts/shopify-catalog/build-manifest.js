#!/usr/bin/env node
// Build a FTCHUB CatalogManifest JSON from a vendor's Shopify Storefront API.
// Usage: node build-manifest.js  (reads .env or process env)
//
// Output shape matches docs/PARTS_CATALOG_ETL.md and FTCHUB/Services/CatalogRepository.swift:
//   { version, generated_at, base_image_url, parts: [...], part_chunk_urls?: [...] }
// Each part matches PartTemplate in FTCHUB/Services/PartsLibraryService.swift.

import fs from "node:fs/promises";
import path from "node:path";
import "dotenv/config";

const {
  SHOPIFY_STORE_DOMAIN,
  SHOPIFY_STOREFRONT_TOKEN,
  SHOPIFY_API_VERSION = "2024-10",
  MANUFACTURER_NAME = "Vendor",
  COLLECTION_HANDLE = "",
  OUTPUT_DIR = "./dist",
  MANIFEST_FILENAME = "manifest.json",
  CHUNK_SIZE = "0",
  BASE_IMAGE_URL = "",
} = process.env;

if (!SHOPIFY_STORE_DOMAIN || !SHOPIFY_STOREFRONT_TOKEN) {
  console.error("Missing SHOPIFY_STORE_DOMAIN or SHOPIFY_STOREFRONT_TOKEN. See .env.example.");
  process.exit(1);
}

const endpoint = `https://${SHOPIFY_STORE_DOMAIN}/api/${SHOPIFY_API_VERSION}/graphql.json`;
const chunkSize = Number.parseInt(CHUNK_SIZE, 10) || 0;

const PRODUCTS_QUERY = /* GraphQL */ `
  query Products($cursor: String) {
    products(first: 100, after: $cursor) {
      pageInfo { hasNextPage endCursor }
      edges {
        node {
          id
          handle
          title
          description
          productType
          tags
          onlineStoreUrl
          collections(first: 5) { edges { node { handle title } } }
          variants(first: 100) {
            edges {
              node {
                id
                sku
                title
                price { amount currencyCode }
                image { url altText }
              }
            }
          }
          images(first: 1) { edges { node { url altText } } }
        }
      }
    }
  }
`;

const COLLECTION_QUERY = /* GraphQL */ `
  query CollectionProducts($handle: String!, $cursor: String) {
    collection(handle: $handle) {
      handle
      title
      products(first: 100, after: $cursor) {
        pageInfo { hasNextPage endCursor }
        edges { node {
          id handle title description productType tags onlineStoreUrl
          collections(first: 5) { edges { node { handle title } } }
          variants(first: 100) { edges { node {
            id sku title price { amount currencyCode } image { url altText }
          } } }
          images(first: 1) { edges { node { url altText } } }
        } }
      }
    }
  }
`;

async function gql(query, variables) {
  const res = await fetch(endpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Shopify-Storefront-Access-Token": SHOPIFY_STOREFRONT_TOKEN,
    },
    body: JSON.stringify({ query, variables }),
  });
  if (!res.ok) throw new Error(`Shopify HTTP ${res.status}: ${await res.text()}`);
  const json = await res.json();
  if (json.errors) throw new Error(`Shopify GraphQL: ${JSON.stringify(json.errors)}`);
  return json.data;
}

async function fetchAllProducts() {
  const products = [];
  let cursor = null;
  for (;;) {
    const data = COLLECTION_HANDLE
      ? await gql(COLLECTION_QUERY, { handle: COLLECTION_HANDLE, cursor })
      : await gql(PRODUCTS_QUERY, { cursor });
    const conn = COLLECTION_HANDLE ? data.collection?.products : data.products;
    if (!conn) break;
    for (const edge of conn.edges) products.push(edge.node);
    if (!conn.pageInfo.hasNextPage) break;
    cursor = conn.pageInfo.endCursor;
    // Gentle pacing to stay well under Storefront API cost limits.
    await new Promise((r) => setTimeout(r, 250));
  }
  return products;
}

function stripHTML(html) {
  if (!html) return undefined;
  return html
    .replace(/<script[\s\S]*?<\/script>/gi, "")
    .replace(/<style[\s\S]*?<\/style>/gi, "")
    .replace(/<[^>]+>/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function stableIdFromGID(gid, fallback) {
  // gid://shopify/ProductVariant/1234567890 -> variant id tail
  const tail = (gid || "").split("/").pop();
  return tail ? `shopify-${tail}` : fallback;
}

function primaryCollection(product) {
  const edges = product.collections?.edges || [];
  if (edges.length === 0) return undefined;
  return edges[0].node.title;
}

function toPartTemplates(products) {
  const parts = [];
  for (const p of products) {
    const variants = p.variants?.edges?.map((e) => e.node) || [];
    const productImage = p.images?.edges?.[0]?.node?.url;
    const productURL = p.onlineStoreUrl || undefined;
    const description = stripHTML(p.description);
    const category = p.productType || primaryCollection(p) || "Uncategorized";
    const subcategory =
      p.productType && primaryCollection(p) && p.productType !== primaryCollection(p)
        ? primaryCollection(p)
        : undefined;

    for (const v of variants) {
      const isDefaultVariant = !v.title || v.title === "Default Title";
      const name = isDefaultVariant ? p.title : `${p.title} — ${v.title}`;
      const sku = (v.sku || "").trim();
      if (!sku && variants.length > 1) {
        // Skip variants without SKUs when the product has multiple variants,
        // since we cannot produce a stable cross-run identifier for inventory.
        continue;
      }
      const id = stableIdFromGID(v.id, sku || `${p.handle}-${parts.length}`);
      const image = v.image?.url || productImage;
      const price = v.price?.amount ? Number.parseFloat(v.price.amount) : undefined;

      parts.push({
        id,
        sku: sku || id,
        name,
        manufacturer: MANUFACTURER_NAME,
        partNumber: sku || p.handle,
        category,
        subcategory,
        description,
        unitCost: Number.isFinite(price) ? price : undefined,
        lowStockThreshold: 1,
        image,
        productURL,
        compatibleTags: p.tags?.length ? p.tags : undefined,
      });
    }
  }
  // Deduplicate by id (later wins, matching CatalogRepository merge semantics).
  const byId = new Map();
  for (const part of parts) byId.set(part.id, part);
  return [...byId.values()];
}

async function writeManifest(parts) {
  await fs.mkdir(OUTPUT_DIR, { recursive: true });
  const generatedAt = new Date().toISOString();
  const version = Math.floor(Date.now() / 1000);

  if (chunkSize > 0 && parts.length > chunkSize) {
    const chunkURLs = [];
    for (let i = 0; i < parts.length; i += chunkSize) {
      const slice = parts.slice(i, i + chunkSize);
      const name = `parts-${String(i / chunkSize).padStart(4, "0")}.json`;
      await fs.writeFile(path.join(OUTPUT_DIR, name), JSON.stringify(slice));
      chunkURLs.push(name);
    }
    const manifest = {
      version,
      generated_at: generatedAt,
      base_image_url: BASE_IMAGE_URL || null,
      parts: [],
      part_chunk_urls: chunkURLs,
    };
    await fs.writeFile(path.join(OUTPUT_DIR, MANIFEST_FILENAME), JSON.stringify(manifest, null, 2));
  } else {
    const manifest = {
      version,
      generated_at: generatedAt,
      base_image_url: BASE_IMAGE_URL || null,
      parts,
    };
    await fs.writeFile(path.join(OUTPUT_DIR, MANIFEST_FILENAME), JSON.stringify(manifest, null, 2));
  }
}

async function main() {
  console.log(`Fetching products from ${SHOPIFY_STORE_DOMAIN}${COLLECTION_HANDLE ? ` (collection: ${COLLECTION_HANDLE})` : ""}...`);
  const products = await fetchAllProducts();
  console.log(`Got ${products.length} products.`);
  const parts = toPartTemplates(products);
  console.log(`Mapped to ${parts.length} PartTemplate rows.`);
  await writeManifest(parts);
  console.log(`Wrote manifest to ${path.join(OUTPUT_DIR, MANIFEST_FILENAME)}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
