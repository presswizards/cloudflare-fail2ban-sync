#!/bin/bash
# If this module saves you time, helps your clients, or helps you do better work, I’d appreciate some coffee:
# https://www.buymeacoffee.com/robwpdev
# Thanks! ~ Rob / PressWizards.com

# Cloudflare Global API Key and Email
CF_API_KEY="xt71fjfu2h2z23jeb1c5h0s006zsl3954io2e4"
CF_EMAIL="support@yourdomain.com"

IP=$2  # IP to be blocked or unblocked (provided as argument)
ACTION=$1  # Action: "ban" or "unban"

# Function to validate IP address format
validate_ip() {
  local ip=$1
  if [[ ! "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    echo "Invalid IP address format: $ip"
    exit 1
  fi
}

# Check if action is provided and valid
if [[ "$ACTION" != "ban" && "$ACTION" != "unban" ]]; then
  echo "Usage: $0 {ban|unban} <IP>"
  exit 1
fi

# Check if the IP argument is provided
if [ -z "$IP" ]; then
  echo "Error: No IP address provided. Usage: $0 {ban|unban} <IP>"
  exit 1
fi

# Validate the IP address format
validate_ip "$IP"

# Get the list of account IDs
ACCOUNT_IDS=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts" \
    -H "X-Auth-Email: $CF_EMAIL" \
    -H "X-Auth-Key: $CF_API_KEY" \
    -H "Content-Type: application/json" | jq -r '.result[].id')

if [ -z "$ACCOUNT_IDS" ]; then
    echo "No accounts found or API key does not have access to any accounts."
    exit 1
fi

# Loop through each account ID and apply the block or unban rule
for ACCOUNT_ID in $ACCOUNT_IDS; do
    echo "$ACTION IP $IP for Account ID: $ACCOUNT_ID"

    if [[ "$ACTION" == "ban" ]]; then
        # Create the global firewall rule to block the IP at the account level
        RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/firewall/access_rules/rules" \
                        -H "X-Auth-Email: $CF_EMAIL" \
                        -H "X-Auth-Key: $CF_API_KEY" \
                        -H "Content-Type: application/json" \
                        --data '{
                            "mode": "block",
                            "configuration": {
                                "target": "ip",
                                "value": "'"$IP"'"
                            },
                            "notes": "Blocked by Fail2Ban (All Sites)"
                        }')

        # Check if the block was successful
#        echo "Response: $RESPONSE"
        if echo "$RESPONSE" | jq -e '.success' > /dev/null; then
            echo "Successfully blocked $IP for Account ID $ACCOUNT_ID."
        else
            echo "Failed to block $IP for Account ID $ACCOUNT_ID. Response: $RESPONSE"
        fi
    elif [[ "$ACTION" == "unban" ]]; then
        # Fetch all firewall rules for the account and look for the matching IP
        RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/firewall/access_rules/rules" \
                        -H "X-Auth-Email: $CF_EMAIL" \
                        -H "X-Auth-Key: $CF_API_KEY" \
                        -H "Content-Type: application/json")

        # Find the rule ID for the IP to unban
        RULE_ID=$(echo "$RESPONSE" | jq -r ".result[] | select(.configuration.value==\"$IP\") | .id")

        if [ -z "$RULE_ID" ]; then
            echo "IP $IP not found in firewall rules for Account ID $ACCOUNT_ID. Nothing to unban."
        else
            # Delete the rule to unblock the IP
            DELETE_RESPONSE=$(curl -s -X DELETE "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/firewall/access_rules/rules/$RULE_ID" \
                                -H "X-Auth-Email: $CF_EMAIL" \
                                -H "X-Auth-Key: $CF_API_KEY" \
                                -H "Content-Type: application/json")

            # Check if the unban was successful
            if echo "$DELETE_RESPONSE" | jq -e '.success' > /dev/null; then
                echo "Successfully unblocked $IP for Account ID $ACCOUNT_ID."
            else
                echo "Failed to unblock $IP for Account ID $ACCOUNT_ID. Response: $DELETE_RESPONSE"
            fi
        fi
    fi
done
