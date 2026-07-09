# Object Storage (S3-compatible)

Photo and export file storage with presigned uploads (ADR: file-storage). Hetzner Object Storage preferred to match deployment; any S3-compatible service works (AWS S3, Tigris, MinIO).

## Auth Type

api_token

## Required Credentials

- `S3_ENDPOINT` — HTTPS endpoint, e.g. `https://fsn1.your-objectstorage.com` for Hetzner (console: https://console.hetzner.com → Object Storage) or `https://s3.amazonaws.com`
- `S3_REGION` — region string the endpoint expects (Hetzner: `fsn1`/`nbg1`/`hel1`; AWS: e.g. `us-east-1`)
- `S3_BUCKET` — bucket name created for this app, e.g. `cleaner-crm-dev`
- `S3_ACCESS_KEY_ID` — access key generated in the provider console
- `S3_SECRET_ACCESS_KEY` — matching secret key

## Verify Script

.code_my_spec/qa/scripts/verify_object_storage.sh

## Status

pending
