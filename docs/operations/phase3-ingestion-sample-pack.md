# Phase 3 Sample Data Pack

## Purpose

This sample-data pack gives the project a small but realistic starting point for pipeline-based ingestion into the Lakehouse landing zone.

## Location In Repo

- `sample-data/dev/landing/manifest.json`
- `sample-data/dev/landing/pos/daily_sales/`
- `sample-data/dev/landing/inventory/snapshot/`
- `sample-data/dev/landing/suppliers/master/`

## Included Files

### CSV

- `pos_daily_sales_2026_04_15.csv`
- `pos_daily_sales_2026_04_16.csv`

### JSON

- `inventory_snapshot_2026_04_15.json`
- `suppliers_master_2026_04_15.json`

## Recommended Ingestion Pattern

Use a Fabric pipeline in `ws-npw-data-dev` to copy these repo-backed sample files into the Lakehouse landing folders.

### Target landing folders

- `landing/pos/daily_sales`
- `landing/inventory/snapshot`
- `landing/suppliers/master`

## Practical Learning Notes

- start with one pipeline and 3 copy activities
- ingest CSV and JSON separately so you learn both source formats cleanly
- load the files into `Files`, not tables, for the initial landing step
- keep landing source-oriented and raw

## Recommended Source Hosting Choice

For the first ingestion exercise, use the GitHub raw file URLs from this repository as the source location.

This keeps the sample pack in source control and avoids manual local uploads as a dependency for the first pipeline run.

