#!/bin/bash

#set -x  # Enable debugging mode

SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL}"
DOMAINS_FILE="domains.txt"

echo "Starting SSL Expiry Check"

while IFS= read -r TARGET; do
  [ -z "$TARGET" ] && continue
  
  expirationdate=$(date -d "$(: | openssl s_client -connect "$TARGET":443 -servername "$TARGET" 2>/dev/null \
                                | openssl x509 -text \
                                | grep 'Not After' \
                                |awk '{print $4,$5,$7}')" '+%s')

  current_epoch=$(date +%s)
  remaining_days=$(( (expirationdate - current_epoch) / 86400 ))

  message="SSL Expiry Alert
   * Domain: $TARGET
   * Warning: The SSL certificate for $TARGET will expire in $remaining_days days."

  echo "Sending Alert for Domain: $TARGET"
  curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"$message\"}" "$SLACK_WEBHOOK_URL"
done < "$DOMAINS_FILE"

echo "SSL Expiry Check Completed"

#set +x  # Disable debugging mode

