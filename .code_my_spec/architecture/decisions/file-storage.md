# Photo & File Storage — S3-compatible object storage with presigned uploads

**Status:** Accepted

## Context

Stories 842 (before/after checklist photos, offline-tolerant), 845 (incident report photos), and 839 (owner photo review) make photo capture a core flow from phones on cell connections. Payroll CSV exports (838) also need file delivery. Photos must be durable, cheap, and uploaded without proxying large bodies through the app server.

## Options Considered

- **S3-compatible object storage + presigned URLs** — direct-from-phone uploads via LiveView `allow_upload(external: ...)`; works with AWS S3, Hetzner Object Storage, or Tigris.
- **Local disk on the app server** — simplest but not durable across deploys and complicates Hetzner scaling.
- **Cloudinary/Uploadcare** — image pipelines we don't need yet at meaningful cost.

## Decision

Store photos in S3-compatible object storage (Hetzner Object Storage to match the Hetzner deployment ADR; any S3 API works). Generate presigned PUT URLs server-side with a small project-local signer (no ExAws dependency — Req + :crypto SigV4), and use LiveView external uploads so phones upload directly. `CleanerCrm.Quality.Photo` records track upload state (`pending` → `uploaded`) to tolerate offline retry (criterion 7172).

## Consequences

- Bucket credentials via Dotenvy; per-company key prefixes for tenant isolation.
- Thumbnails/derivatives deferred; store originals, render responsive via `img` sizing initially.
- A cleanup job (Oban) reaps `pending` photo records whose uploads never completed.
