# FTCHUB Shopify catalog ETL

Builds a FTCHUB `CatalogManifest` JSON from a vendor's Shopify Storefront API and uploads it to Supabase Storage. The iOS app consumes the uploaded manifest via `PARTS_CATALOG_MANIFEST_URL` (see [FTCHUB/Utils/Config.swift](../../FTCHUB/Utils/Config.swift)).

## Vendor access checklist

Before running, confirm the following with the vendor (this addresses the "we don't have a CSV — use our Shopify public API" response):

1. Shop domain, e.g. `gobilda.myshopify.com` or a custom storefront host that exposes `/api/<version>/graphql.json`.
2. A **Storefront API access token** scoped to `unauthenticated_read_product_listings` (the vendor creates this from Shopify Admin — Headless / Custom storefront).
3. Optional collection handle (e.g. `ftc-legal`) if only part of the store should be exported.
4. Permission to cache product data in your app's remote manifest.

Record the answers in `.env` locally or repo/org secrets in CI. **Variants, not products, are the unit of inventory** — each Shopify variant with a SKU maps to one `PartTemplate`.

## Running locally

```bash
cd scripts/shopify-catalog
cp .env.example .env            # fill in values
npm install
npm run build-manifest          # writes ./dist/manifest.json
npm run upload-manifest         # uploads to Supabase Storage
```

After upload, the script prints the public URL. Put that URL in `PARTS_CATALOG_MANIFEST_URL` in the app's `Secrets.plist` or CI-generated secrets (read by `Config.partsCatalogManifestURL`).

## What the script does

- Paginates the Storefront API (`products` or `collection.products`) with cursor-based paging, 250ms between pages.
- Maps each variant to a `PartTemplate` row matching the schema in [FTCHUB/Services/PartsLibraryService.swift](../../FTCHUB/Services/PartsLibraryService.swift).
- Uses Shopify variant GID as the stable `id` (`shopify-<numeric>`), so re-running keeps user inventory links stable even if SKUs are edited.
- Strips HTML from `description`.
- Chunks output if `CHUNK_SIZE > 0`, using the manifest's existing `part_chunk_urls` support in [FTCHUB/Services/CatalogRepository.swift](../../FTCHUB/Services/CatalogRepository.swift).

## Scheduling

See [.github/workflows/shopify-catalog.yml](../../.github/workflows/shopify-catalog.yml) for a daily GitHub Actions job. Configure these repo secrets: `SHOPIFY_STORE_DOMAIN`, `SHOPIFY_STOREFRONT_TOKEN`, `MANUFACTURER_NAME`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`.
