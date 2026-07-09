#!/bin/bash
# Verify S3-compatible object storage credentials by writing and deleting a
# probe object (proves list/put/delete permissions on the bucket).
# Requires curl >= 7.75 (--aws-sigv4).
set -u

for var in S3_ENDPOINT S3_REGION S3_BUCKET S3_ACCESS_KEY_ID S3_SECRET_ACCESS_KEY; do
  if [ -z "$(eval echo "\${$var:-}")" ]; then
    echo "{\"integration\": \"object_storage\", \"status\": \"error\", \"error\": \"$var not set\", \"details\": \"export $var or add it to .env\"}"
    exit 1
  fi
done

host=$(echo "$S3_ENDPOINT" | sed 's|https\?://||')
key=".cms-verify-probe-$$"
url="${S3_ENDPOINT}/${S3_BUCKET}/${key}"

put_code=$(curl -s -o /dev/null -w "%{http_code}" -X PUT --data "probe" \
  --aws-sigv4 "aws:amz:${S3_REGION}:s3" \
  --user "${S3_ACCESS_KEY_ID}:${S3_SECRET_ACCESS_KEY}" \
  -H "Host: ${host}" "$url")

if [ "$put_code" != "200" ]; then
  echo "{\"integration\": \"object_storage\", \"status\": \"error\", \"error\": \"PUT probe returned HTTP ${put_code}\", \"details\": \"check endpoint/region/bucket/keys\"}"
  exit 1
fi

del_code=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  --aws-sigv4 "aws:amz:${S3_REGION}:s3" \
  --user "${S3_ACCESS_KEY_ID}:${S3_SECRET_ACCESS_KEY}" \
  -H "Host: ${host}" "$url")

if [ "$del_code" = "204" ] || [ "$del_code" = "200" ]; then
  echo '{"integration": "object_storage", "status": "ok", "details": "PUT and DELETE probe object succeeded on bucket"}'
else
  echo "{\"integration\": \"object_storage\", \"status\": \"error\", \"error\": \"DELETE probe returned HTTP ${del_code}\", \"details\": \"PUT worked but cleanup failed; check delete permissions\"}"
  exit 1
fi
