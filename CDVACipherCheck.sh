#!/usr/bin/env bash

###############################################################################
# Dmitriy Baimakov's Cipher Check Test Script 
# 
# Features:
#   - Accepts server, port, URL, cookie, and optional cipher file via CLI args
#   - Reads a list of default ciphers (or from file) to test
#   - Attempts a connection for each cipher
#   - Logs whether it was accepted or rejected
#   - Shows final summary
#
# Usage:
#   ./cipher_test.sh -s <server> -p <port> -u <url> [-c <cookie>] [-f <cipher_file>]
#
# Example:
#   ./cipher_test.sh -s apps.sstest.ncr.ec.gc.ca -p 443 \
#       -u https://apps.sstest.ncr.ec.gc.ca/inrp-npri \
#       -c '.AspNetCore.Antiforgery.NUcV1478dws=...; ...' \
#       -f weak_ciphers.txt
###############################################################################

# Function: Print usage/help
usage() {
  cat <<EOF
Usage: $0 -s <server> -p <port> -u <url> [-c <cookie>] [-f <cipher_file>]

Required arguments:
  -s <server>       Server hostname or IP (e.g. "apps.sstest.ncr.ec.gc.ca")
  -p <port>         Port (e.g. 443)
  -u <url>          URL (e.g. "https://apps.sstest.ncr.ec.gc.ca/inrp-npri")

Optional arguments:
  -c <cookie>       Cookie string (Use Freshly Authenticated Cookies)

Example:
  $0 -s myserver.com -p 443 -u https://myserver.com/app -c "FreshlyInterceptedCookieFromBurp=abc123"

EOF
  exit 1
}

###############################################################################
# Parse Command-Line Arguments
###############################################################################

while getopts "s:p:u:c:f:" opt; do
  case "$opt" in
    s) SERVER="$OPTARG" ;;
    p) PORT="$OPTARG" ;;
    u) URL="$OPTARG" ;;
    c) COOKIE="$OPTARG" ;;
    f) CIPHER_FILE="$OPTARG" ;;
    *) usage ;;
  esac
done

# Check required arguments
[ -z "$SERVER" ] && usage
[ -z "$PORT" ] && usage
[ -z "$URL" ] && usage

###############################################################################
# Define Cipher List
###############################################################################
if [ -z "$CIPHER_FILE" ]; then
  # Default "weak" cipher list 
  WEAK_CIPHERS=(
    "ECDHE-RSA-NULL-SHA"
    "EXP-EDH-RSA-DES-CBC-SHA"
    "EXP-EDH-DSS-DES-CBC-SHA"
    "EXP-ADH-DES-CBC-SHA"
    "ECDHE-ECDSA-NULL-SHA"
    "AES128-GCM-SHA256"
    "AES256-GCM-SHA384"
    "AES128-SHA256"
    "AES256-SHA256"
    "AES128-SHA"
    "AES256-SHA"
    "DES-CBC3-SHA"
  )
else
  # Read cipher list from file
  mapfile -t WEAK_CIPHERS < "$CIPHER_FILE"
fi

###############################################################################
# Testing Loop
###############################################################################

echo "Testing weak ciphers against $SERVER:$PORT"
echo "URL: $URL"
if [ -n "$COOKIE" ]; then
  echo "Using cookie: $COOKIE"
fi
echo "--------------------------------------------"

ACCEPTED_COUNT=0
REJECTED_COUNT=0

for CIPHER in "${WEAK_CIPHERS[@]}"; do
    echo -n "Testing $CIPHER... "

    CURL_CMD=(curl -k -s -v --cipher "$CIPHER" "$URL" -o /dev/null \
              -w "%{http_code} %{ssl_verify_result}\n")

    if [ -n "$COOKIE" ]; then
      CURL_CMD+=( -b "$COOKIE" )
    fi

    echo "Executing: ${CURL_CMD[@]}"
    OUTPUT=$("${CURL_CMD[@]}" 2>&1)

    HTTP_CODE=$(echo "$OUTPUT" | tail -n1 | awk '{print $1}')
    SSL_INFO=$(echo "$OUTPUT" | grep "SSL connection using")

    if [ -n "$SSL_INFO" ]; then
        NEGOTIATED_PROTO=$(echo "$SSL_INFO" | sed -E 's/.*using (TLS[0-9.]+) \/ .*/\1/')
        NEGOTIATED_CIPHER=$(echo "$SSL_INFO" | sed -E 's/.*using TLS[0-9.]+ \/ (.*)/\1/')

        if [[ "$NEGOTIATED_CIPHER" == "$CIPHER" ]]; then
            echo "ACCEPTED - Negotiated: $NEGOTIATED_PROTO / $NEGOTIATED_CIPHER"
            ((ACCEPTED_COUNT++))
        else
            echo "ACCEPTED (BUT NEGOTIATED DIFFERENT CIPHER: $NEGOTIATED_PROTO / $NEGOTIATED_CIPHER)"
            ((ACCEPTED_COUNT++))
        fi
    else
        if [[ "$HTTP_CODE" == "000" ]]; then
            echo "REJECTED or UNSUPPORTED CIPHER"
            ((REJECTED_COUNT++))
        else
            echo "Unexpected result: HTTP code $HTTP_CODE"
        fi
    fi
done

echo "--------------------------------------------"
echo "Testing complete."
echo "Accepted: $ACCEPTED_COUNT  |  Rejected: $REJECTED_COUNT"
