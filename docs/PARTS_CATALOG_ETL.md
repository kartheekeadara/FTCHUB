# Parts Catalog ETL Pipeline

This document describes how to build and publish the remote parts catalog manifest for FTCHUB. The app loads this manifest to display parts from goBILDA, AndyMark, and other vendors—without scraping vendor sites at runtime.

## Overview

```
┌──────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Vendor Exports  │ ──> │  ETL Script     │ ──> │  CDN / Storage  │
│  (CSV, JSON)     │     │  (Python/Node)  │     │  (S3, Supabase) │
└──────────────────┘     └─────────────────┘     └─────────────────┘
                                                         │
                                                         ▼
                                                 ┌───────────────┐
                                                 │   FTCHUB App  │
                                                 └───────────────┘
```

## Manifest Schema (v1)

The app expects a JSON file at the URL configured in `PARTS_CATALOG_MANIFEST_URL`:

```json
{
  "version": 1,
  "generated_at": "2026-04-21T12:00:00Z",
  "base_image_url": "https://cdn.example.com/parts-images",
  "parts": [
    {
      "id": "gobilda-3209-0001-0001",
      "sku": "3209-0001-0001",
      "name": "5203 Series Yellow Jacket Planetary Gear Motor",
      "manufacturer": "goBILDA",
      "partNumber": "5203 Series Motor",
      "category": "Motors",
      "subcategory": "Planetary Gear Motors",
      "description": "19.2:1 ratio planetary gearmotor with integrated encoder.",
      "unitCost": 39.99,
      "lowStockThreshold": 2,
      "image": "gobilda/motors/5203-series.jpg",
      "productURL": "https://www.gobilda.com/5203-series-motor/",
      "specifications": {
        "Gear Ratio": "19.2:1",
        "Free Speed": "312 RPM",
        "Stall Torque": "5.4 Nm",
        "Voltage": "12V DC"
      },
      "compatibleTags": ["ftc-legal", "planetary", "encoder"]
    }
  ]
}
```

### Field Reference

| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | Stable unique identifier (survives SKU changes). Format: `{vendor}-{sku}`. |
| `sku` | Yes | Vendor part number. |
| `name` | Yes | Human-readable part name. |
| `manufacturer` | Yes | Vendor name (goBILDA, AndyMark, REV Robotics, TETRIX). |
| `partNumber` | Yes | Display part number. |
| `category` | Yes | Primary category (Motors, Servos, Sensors, Structure, etc.). |
| `subcategory` | No | Optional sub-category for finer filtering. |
| `description` | No | Short description. |
| `unitCost` | No | Approximate unit price in USD. |
| `lowStockThreshold` | No | Default low-stock alert threshold (default: 1). |
| `image` | No | Relative path (resolved against `base_image_url`) or full URL. |
| `productURL` | No | Deep link to vendor product page. |
| `specifications` | No | Key-value map of technical specs. |
| `compatibleTags` | No | Array of tags for future filtering (e.g., `ftc-legal`). |
| `part_chunk_urls` | No | Array of URLs to extra JSON part lists (see “Chunked mega catalog” below). |

## Why the in-app list is not “every product on the website”

Vendor sites are large, change often, and usually **forbid automated scraping** in their terms of use. FTCHUB is designed to load a **manifest you publish** (from CSV exports, dealer portals, or other data you are allowed to use), not to crawl goBILDA or AndyMark at runtime.

To show **as many parts as you are entitled to ship**:

1. Obtain or build a complete export (per vendor policy).
2. Run your ETL to FTCHUB JSON.
3. Host the JSON (and images) on HTTPS with caching headers.
4. Set `PARTS_CATALOG_MANIFEST_URL` (and optional `PARTS_CATALOG_BASE_IMAGE_URL`) in `Secrets.plist`.

## Chunked mega catalog (`part_chunk_urls`)

For thousands of SKUs, split parts across multiple JSON files so the **index** manifest stays small. The app downloads the index, then every chunk, and merges by stable `id` (later chunks override earlier entries with the same `id`).

**Index manifest** (`manifest.json`):

```json
{
  "version": 2,
  "generated_at": "2026-04-21T12:00:00Z",
  "base_image_url": "https://cdn.example.com/catalog/img",
  "parts": [],
  "part_chunk_urls": [
    "chunks/gobilda-000.json",
    "chunks/gobilda-001.json",
    "https://cdn.example.com/catalog/chunks/andymark-000.json"
  ]
}
```

URLs may be **absolute** or **relative to the directory of the index file** (e.g. if the index is `https://cdn.example.com/catalog/manifest.json`, then `chunks/gobilda-000.json` resolves to `https://cdn.example.com/catalog/chunks/gobilda-000.json`).

**Each chunk** is either a raw array:

```json
[
  { "id": "gobilda-3209-0001-0001", "sku": "3209-0001-0001", "name": "…", "manufacturer": "goBILDA", "partNumber": "…", "category": "Motors" }
]
```

or an object wrapper:

```json
{ "parts": [ … ] }
```

Optional **inline `parts`** on the index are merged first; then chunk URLs are applied **in list order**.

### Splitting a huge `parts` array into chunks (Python)

```python
import json
from pathlib import Path

CHUNK_SIZE = 800
parts = json.load(open("all_parts.json"))["parts"]
out = Path("output/chunks")
out.mkdir(parents=True, exist_ok=True)
urls = []
for i, start in enumerate(range(0, len(parts), CHUNK_SIZE)):
    chunk = parts[start:start + CHUNK_SIZE]
    name = f"parts-{i:03d}.json"
    path = out / name
    path.write_text(json.dumps({"parts": chunk}))
    urls.append(f"chunks/{name}")

index = {
    "version": 3,
    "generated_at": "2026-04-21T12:00:00Z",
    "base_image_url": "https://cdn.example.com/catalog/img",
    "parts": [],
    "part_chunk_urls": urls,
}
Path("output/manifest.json").write_text(json.dumps(index, indent=2))
```

## ETL Script Workflow

### 1. Gather Source Data

Obtain product data from each vendor. Options:

- **goBILDA**: Download product CSV from their dealer portal or maintain a hand-curated spreadsheet.
- **AndyMark**: Export catalog or use publicly available product feeds.
- **REV / TETRIX**: Bundled JSON already ships with the app; only include in remote manifest if you want to add images/URLs.

Store source files in a `sources/` directory:

```
etl/
├── sources/
│   ├── gobilda_products.csv
│   ├── andymark_products.csv
│   └── rev_products.json
├── images/
│   └── (downloaded product images)
├── output/
│   └── manifest.json
└── build_manifest.py
```

### 2. Transform Data

Write a script (Python example) to normalize and merge:

```python
#!/usr/bin/env python3
"""
build_manifest.py — Builds FTCHUB parts catalog manifest from vendor sources.
"""
import csv
import json
from datetime import datetime, timezone

def load_gobilda(path):
    parts = []
    with open(path, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            parts.append({
                "id": f"gobilda-{row['sku']}",
                "sku": row['sku'],
                "name": row['name'],
                "manufacturer": "goBILDA",
                "partNumber": row.get('part_number', row['sku']),
                "category": row['category'],
                "subcategory": row.get('subcategory'),
                "description": row.get('description'),
                "unitCost": float(row['price']) if row.get('price') else None,
                "lowStockThreshold": 2,
                "image": f"gobilda/{row['sku']}.jpg" if row.get('has_image') else None,
                "productURL": row.get('url'),
                "specifications": parse_specs(row.get('specs', '')),
            })
    return parts

def parse_specs(spec_string):
    if not spec_string:
        return None
    specs = {}
    for pair in spec_string.split(';'):
        if ':' in pair:
            k, v = pair.split(':', 1)
            specs[k.strip()] = v.strip()
    return specs if specs else None

def build_manifest(parts):
    return {
        "version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "base_image_url": "https://cdn.yourapp.com/catalog/images",
        "parts": parts
    }

if __name__ == "__main__":
    all_parts = []
    all_parts.extend(load_gobilda("sources/gobilda_products.csv"))
    # all_parts.extend(load_andymark("sources/andymark_products.csv"))
    
    manifest = build_manifest(all_parts)
    
    with open("output/manifest.json", "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    
    print(f"Generated manifest with {len(all_parts)} parts.")
```

### 3. Process Images

Download or copy product images to `images/` following the path structure used in `image` fields. Resize to reasonable dimensions (e.g., max 800px wide) to optimize bandwidth.

```bash
# Example: resize all images to max 800px wide
for img in images/**/*.jpg; do
  convert "$img" -resize 800x\> "$img"
done
```

### 4. Upload to CDN

Upload `output/manifest.json` and `images/` to your CDN or Supabase Storage:

**Supabase Storage:**

```bash
# Create bucket if needed
supabase storage create catalog --public

# Upload manifest
supabase storage upload catalog manifest.json output/manifest.json

# Upload images folder
supabase storage upload catalog images/ --recursive
```

**AWS S3:**

```bash
aws s3 sync output/ s3://your-bucket/catalog/ --acl public-read
aws s3 sync images/ s3://your-bucket/catalog/images/ --acl public-read
```

### 5. Configure the App

Set these in `Secrets.plist` or environment:

```
PARTS_CATALOG_MANIFEST_URL = https://cdn.yourapp.com/catalog/manifest.json
PARTS_CATALOG_BASE_IMAGE_URL = https://cdn.yourapp.com/catalog/images
```

## Versioning & Cache Invalidation

- **Increment `version`** in the manifest whenever you add/remove/update parts.
- The app uses **ETag** and **If-None-Match** headers for efficient cache validation.
- Configure your CDN to return proper `ETag` headers on the manifest.
- The app caches the manifest locally for 1 hour before re-checking.

## Legal Considerations

1. **Only include data you have rights to use.** Vendor product pages and images may be copyrighted.
2. **Deep links are generally safe** — linking to vendor product pages is allowed.
3. **Images**: Either use images with explicit permission, host your own photos, or use placeholder icons.
4. **Prices are approximate** — the app displays a disclaimer: "Prices may differ; verify on vendor site."

## Automation

For ongoing updates, set up a scheduled job (GitHub Actions, cron, etc.):

```yaml
# .github/workflows/update-catalog.yml
name: Update Parts Catalog

on:
  schedule:
    - cron: '0 6 * * 1'  # Every Monday at 6 AM UTC
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - run: pip install -r requirements.txt
      - run: python build_manifest.py
      - name: Upload to S3
        run: aws s3 sync output/ s3://${{ secrets.BUCKET }}/catalog/
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| App shows "Bundled catalog only" | Check `PARTS_CATALOG_MANIFEST_URL` is set and reachable. |
| Images not loading | Verify `base_image_url` + relative paths resolve correctly. |
| Stale data in app | Force refresh via the ↻ button, or wait 1 hour for cache expiry. |
| Large manifest size | Consider chunking (manifest indexes smaller part-000.json files). |

## Shopify source (vendor with no CSV export)

Some vendors (e.g. goBILDA) don't publish a CSV but expose their store via Shopify's **Storefront API**. A ready-made ETL lives in [scripts/shopify-catalog/](../scripts/shopify-catalog/README.md) and produces a manifest matching the schema above, so no app changes are needed.

### Required env vars

| Name | Purpose |
|------|---------|
| `SHOPIFY_STORE_DOMAIN` | e.g. `gobilda.myshopify.com` |
| `SHOPIFY_STOREFRONT_TOKEN` | Storefront API token (vendor-issued, read-only) |
| `SHOPIFY_API_VERSION` | Defaults to `2024-10` |
| `MANUFACTURER_NAME` | Written into `PartTemplate.manufacturer` |
| `COLLECTION_HANDLE` | Optional — limits export to one collection |
| `CHUNK_SIZE` | `0` for single file, or e.g. `500` to emit `part_chunk_urls` |
| `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_BUCKET`, `SUPABASE_MANIFEST_PATH` | Upload target |

### Sample query (cursor-paginated)

```graphql
query Products($cursor: String) {
  products(first: 100, after: $cursor) {
    pageInfo { hasNextPage endCursor }
    edges { node {
      id handle title description productType tags onlineStoreUrl
      collections(first: 5) { edges { node { handle title } } }
      variants(first: 100) { edges { node {
        id sku title price { amount currencyCode } image { url }
      } } }
      images(first: 1) { edges { node { url } } }
    } }
  }
}
```

### Mapping (variant → `PartTemplate`)

| Shopify field | `PartTemplate` field |
|---------------|----------------------|
| Variant GID tail | `id` (`shopify-<numeric>`) |
| Variant `sku` | `sku`, `partNumber` |
| Product title (+ variant title if not `Default Title`) | `name` |
| `MANUFACTURER_NAME` env | `manufacturer` |
| `productType` (fallback: primary collection) | `category` |
| Primary collection title (when distinct) | `subcategory` |
| `description` (HTML stripped) | `description` |
| `price.amount` | `unitCost` |
| Variant image → product image | `image` (absolute URL; `base_image_url` may stay `null`) |
| `onlineStoreUrl` | `productURL` |
| `tags` | `compatibleTags` |

Scheduling is handled by [.github/workflows/shopify-catalog.yml](../.github/workflows/shopify-catalog.yml) (daily + manual `workflow_dispatch`). Failures abort before upload, so the last good manifest stays live.

## Future Enhancements

- **Chunked manifests**: For 10k+ parts, split into indexed chunks.
- **Search index**: Publish a lightweight search index for faster filtering.
- **Price alerts**: Track price changes between manifest versions.
- **Compatibility matrix**: Link parts that work well together.
