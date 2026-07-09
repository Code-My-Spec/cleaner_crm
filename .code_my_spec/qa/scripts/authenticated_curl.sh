#!/bin/bash
# Session-authenticated curl for Cleaner CRM QA.
# Usage: authenticated_curl.sh [email] [password] <curl-args...>
#   authenticated_curl.sh /users/settings
#   authenticated_curl.sh qa-cleaner@cleanercrm.test "qa password 1234" /users/settings -i
# Logs in via POST /users/log-in, stores the session cookie, then runs curl
# with the session against BASE_URL (default http://127.0.0.1:4100).
set -u

BASE_URL="${BASE_URL:-http://127.0.0.1:4100}"
EMAIL="qa-owner@cleanercrm.test"
PASSWORD="qa password 1234"

if [[ "${1:-}" == *"@"* ]]; then
  EMAIL="$1"; PASSWORD="$2"; shift 2
fi

JAR="${TMPDIR:-/tmp}/cleaner_crm_qa_cookies_$$"
trap 'rm -f "$JAR"' EXIT

page=$(curl -sS -c "$JAR" "$BASE_URL/users/log-in")
csrf=$(echo "$page" | grep -oE 'name="_csrf_token"[^>]*value="[^"]*"' | head -1 | sed 's/.*value="//;s/"$//')

login_code=$(curl -sS -b "$JAR" -c "$JAR" -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/users/log-in" -d "_csrf_token=$csrf" --data-urlencode "user[email]=$EMAIL" --data-urlencode "user[password]=$PASSWORD")

if [ "$login_code" != "302" ]; then
  echo "login failed with HTTP $login_code for $EMAIL" >&2
  exit 1
fi

path="$1"; shift
curl -sS -b "$JAR" "$@" "$BASE_URL$path"
