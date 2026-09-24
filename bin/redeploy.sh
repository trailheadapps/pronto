#!/bin/bash
SCRIPT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd $SCRIPT_PATH/..

# Optional org alias param. Falls back to the current default org when omitted.
TARGET_ORG="$1"
SF_TARGET_ORG_ARGS=()
if [ -n "$TARGET_ORG" ]; then
  SF_TARGET_ORG_ARGS=(--target-org "$TARGET_ORG")
fi

# Checks that the previous command succeeded
check_status() {
  local status=$?
  if [ $status -ne 0 ]; then
    echo "Reploy failed: $1 failed" >&2
    exit $status
  fi
}

# Checks that a variable has a value
check_var() {
  if [ -z "$2" ] || [ "$2" == "null" ]; then
    echo "Reploy failed: Failed to retrieve $1" >&2
    exit 1
  fi
}

echo ""
if [ -n "$TARGET_ORG" ]; then
  echo "Redeploying Pronto to org: $TARGET_ORG"
else
  echo "Redeploying Pronto to default org"
fi
echo ""

echo "[1/6] Cleaning previous org-specific metadata..."
node bin/clean-hardcoded-values.js \
  "src-base/main/default/aiAuthoringBundles/**/*.agent" \
  "src-base/main/default/flows/*.flow-meta.xml" \
  "src-site/main/default/pages/ESWCustomerServiceAgent.page" \
  "src-site/main/default/digitalExperiences/site/ESW_Customer_Service_Agent1/sfdc_cms__trustedSites/trustedSites/content.json" \
  "src-site/main/default/digitalExperiences/site/Pronto_Customer_Site1/sfdc_cms__themeLayout/scopedHeaderAndFooter/content.json" \
  "src-site/main/default/digitalExperiences/site/Pronto_Customer_Site1/sfdc_cms__view/home/content.json" \
  "src-site/main/default/sites/*.site-meta.xml"
check_status "Cleaning previous org-specific metadata"
echo ""

echo "[2/6] Extracting org info..."
PRONTO_ORG_DISPLAY_JSON=$(sf org display --json)
check_status "Extracting org info"
export PRONTO_ORG_ID=$(echo "$PRONTO_ORG_DISPLAY_JSON" | jq -r '.result.id')
check_var "org ID" "$PRONTO_ORG_ID"
echo "Org ID:                    $PRONTO_ORG_ID"
PRONTO_ORG_INSTANCE_URL=$(echo "$PRONTO_ORG_DISPLAY_JSON" | jq -r '.result.instanceUrl')
check_var "org domain" "$PRONTO_ORG_INSTANCE_URL"
export PRONTO_ORG_DOMAIN="${PRONTO_ORG_INSTANCE_URL%.my.salesforce.com}"
echo "Org Domain:                $PRONTO_ORG_DOMAIN"
echo ""

echo "[3/6] Retrieving service agent user..."
SOQL_RESULTS=$(sf data query --query "SELECT Username FROM User WHERE Profile.Name = 'Einstein Agent User' AND IsActive = true" --json "${SF_TARGET_ORG_ARGS[@]}")
export PRONTO_AGENT_USERNAME=$(echo "$SOQL_RESULTS" | jq -r '.result.records[0].Username')
check_var "service agent username" "$PRONTO_AGENT_USERNAME"
echo "Service agent username:    $PRONTO_AGENT_USERNAME"
echo ""

echo "[4/6] Extracting service agent queues..."
export PRONTO_AGENT_ROUTING_QUEUE_ID=$(sf data query --query "SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Customer Service Messaging Queue'" --json "${SF_TARGET_ORG_ARGS[@]}" | grep -o '"Id": "[^"]*' | cut -d'"' -f4)  && \
check_var "service agent routing queue ID" "$PRONTO_AGENT_ROUTING_QUEUE_ID"
echo "Service agent routing queue ID:        $PRONTO_AGENT_ROUTING_QUEUE_ID"
export PRONTO_ESCALATION_ROUTING_QUEUE_ID=$(sf data query --query "SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Customer Service Escalation Queue'" --json "${SF_TARGET_ORG_ARGS[@]}" | grep -o '"Id": "[^"]*' | cut -d'"' -f4)  && \
check_var "service agent escalation queue ID" "$PRONTO_ESCALATION_ROUTING_QUEUE_ID"
echo "Service agent escalation queue ID:     $PRONTO_ESCALATION_ROUTING_QUEUE_ID" && \
echo ""

echo "[5/6] Pushing base source..."
sf project deploy start -d src-base "${SF_TARGET_ORG_ARGS[@]}" -c
check_status "Pushing base source"
echo ""

echo "[6/6] Pushing site source..."
sf project deploy start -d src-site "${SF_TARGET_ORG_ARGS[@]}" -c
check_status "Pushing site source"
echo ""

echo "Redeploy complete."
echo ""
exit 0
