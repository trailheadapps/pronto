#!/bin/bash
SCRIPT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd $SCRIPT_PATH/..

# Set parameters
ORG_ALIAS="pronto-scratch"

# Checks that the previous command succeeded
check_status() {
  local status=$?
  if [ $status -ne 0 ]; then
    echo "Install failed: $1 failed" >&2
    exit $status
  fi
}

# Checks that a variable has a value
check_var() {
  if [ -z "$2" ] || [ "$2" == "null" ]; then
    echo "Install failed: Failed to retrieve $1" >&2
    exit 1
  fi
}

# Checks whether an agent (GenAiPlannerDefinition) already exists for a given DeveloperName
agent_exists() {
  local developer_name="$1"
  local result_json
  result_json=$(sf data query --query "SELECT Id FROM GenAiPlannerDefinition WHERE DeveloperName LIKE '$developer_name%'" --json)
  check_status "Querying for existing agent $developer_name"
  local id
  id=$(echo "$result_json" | jq -r '.result.records[0].Id')
  [ -n "$id" ] && [ "$id" != "null" ]
}

# Prints a numbered step header
next_step() {
  STEP=$((STEP+1))
  echo "[$STEP/$TOTAL_STEPS] $1"
}

echo ""
echo "Pronto installer"
echo ""
echo "Select installation type:"
echo "  1) DE Org, Trailhead Playground or existing org (deploys to your current default org)"
echo "  2) Scratch org (creates a fresh scratch org named \"$ORG_ALIAS\")"
echo ""
read -p "Enter choice [1-2]: " INSTALL_CHOICE
echo ""

case "$INSTALL_CHOICE" in
  1) INSTALL_TYPE="prod" ;;
  2) INSTALL_TYPE="scratch" ;;
  *)
    echo "Install failed: invalid choice \"$INSTALL_CHOICE\"" >&2
    exit 1
    ;;
esac

if [ "$INSTALL_TYPE" == "scratch" ]; then
  TOTAL_STEPS=25
else
  TOTAL_STEPS=23
fi
STEP=0

if [ "$INSTALL_TYPE" == "prod" ]; then
  next_step "Validating default org..."
  PRONTO_DEFAULT_ORG_JSON=$(sf org display --json)
  check_status "Validating default org"
  ORG_ALIAS=$(echo "$PRONTO_DEFAULT_ORG_JSON" | jq -r '.result.alias')
  check_var "org alias" "$ORG_ALIAS"
  echo ""
fi

echo "Ready to install Pronto to org alias $ORG_ALIAS"
echo ""

if [ "$INSTALL_TYPE" == "prod" ]; then
  echo "Please confirm that you've enabled all the required features listed in the README."
  echo "Installation will fail if any of these features are not enabled."
  echo ""
fi

read -p "Continue? [y/N]: " CONFIRM_INSTALL
if [[ ! "$CONFIRM_INSTALL" =~ ^[Yy]$ ]]; then
  echo "Install cancelled." >&2
  exit 1
fi
echo ""

if [ "$INSTALL_TYPE" == "scratch" ]; then
  next_step "Removing previous scratch org (if any exists)..."
  sf org delete scratch --no-prompt --target-org $ORG_ALIAS &> /dev/null
  echo ""
fi

next_step "Cleaning previous org-specific metadata..."
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

if [ "$INSTALL_TYPE" == "scratch" ]; then
  next_step "Creating scratch org..."
  sf org create scratch --definition-file config/project-scratch-def.json --alias $ORG_ALIAS --set-default --duration-days 30 --wait 10
  check_status "Creating scratch org"
  echo ""

  next_step "Sleeping for 5 minutes while waiting for HXL provisioning..."
  sleep 300
  echo ""
fi

next_step "Extracting org info..."
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

next_step "Looking for existing agent user..."
PRONTO_AGENT_USER_QUERY_JSON=$(sf data query --query "SELECT Id, Username FROM User WHERE Username LIKE 'agent.user.%' LIMIT 1" --json)
check_status "Querying for existing agent user"
PRONTO_AGENT_USER_ID_FROM_QUERY=$(echo "$PRONTO_AGENT_USER_QUERY_JSON" | jq -r '.result.records[0].Id')
if [ -n "$PRONTO_AGENT_USER_ID_FROM_QUERY" ] && [ "$PRONTO_AGENT_USER_ID_FROM_QUERY" != "null" ]; then
  echo "Found existing agent user."
  export PRONTO_AGENT_USERNAME=$(echo "$PRONTO_AGENT_USER_QUERY_JSON" | jq -r '.result.records[0].Username')
else
  echo "No existing agent user found, creating one..."
  export PRONTO_AGENT_USER_JSON=$(sf org create agent-user --json)
  check_status "Creating agent user"
  export PRONTO_AGENT_USERNAME=$(echo "$PRONTO_AGENT_USER_JSON" | jq -r '.result.username')
fi
echo ""

next_step "Extracting agent user info..."
check_var "service agent user name" "$PRONTO_AGENT_USERNAME"
echo "Service agent user name:   $PRONTO_AGENT_USERNAME"
echo ""

next_step "Deploying service agent queues source..."
sf project deploy start --source-dir src-queues --ignore-conflicts
check_status "Deploying service agent queues source"
echo ""

next_step "Extracting service agent IDs..."
export PRONTO_AGENT_ROUTING_QUEUE_ID=$(sf data query --query "SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Customer Service Messaging Queue'" --json | jq -r '.result.records[0].Id')
check_var "service agent routing queue ID" "$PRONTO_AGENT_ROUTING_QUEUE_ID"
echo "Service agent routing queue ID:        $PRONTO_AGENT_ROUTING_QUEUE_ID"
export PRONTO_ESCALATION_ROUTING_QUEUE_ID=$(sf data query --query "SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Customer Service Escalation Queue'" --json | jq -r '.result.records[0].Id')
check_var "service agent escalation queue ID" "$PRONTO_ESCALATION_ROUTING_QUEUE_ID"
echo "Service agent escalation queue ID:     $PRONTO_ESCALATION_ROUTING_QUEUE_ID"
echo ""

next_step "Deploying base source..."
sf project deploy start --source-dir src-base --ignore-conflicts
check_status "Deploying base source"
echo ""

next_step "Publishing and activating agent: Storefront_Explorer_Assistant..."
if agent_exists "Storefront_Explorer_Assistant"; then
  echo "Agent Storefront_Explorer_Assistant already exists, skipping."
else
  sf agent publish authoring-bundle --api-name Storefront_Explorer_Assistant
  check_status "Publishing Storefront_Explorer_Assistant agent"
  sf agent activate --api-name Storefront_Explorer_Assistant
  check_status "Activating Storefront_Explorer_Assistant agent"
fi
echo ""

next_step "Publishing and activating agent: Customer_Order_Assistant..."
if agent_exists "Customer_Order_Assistant"; then
  echo "Agent Customer_Order_Assistant already exists, skipping."
else
  sf agent publish authoring-bundle --api-name Customer_Order_Assistant
  check_status "Publishing Customer_Order_Assistant agent"
  sf agent activate --api-name Customer_Order_Assistant
  check_status "Activating Customer_Order_Assistant agent"
fi
echo ""

next_step "Publishing and activating agent: Employee_Assistant..."
if agent_exists "Employee_Assistant"; then
  echo "Agent Employee_Assistant already exists, skipping."
else
  sf agent publish authoring-bundle --api-name Employee_Assistant
  check_status "Publishing Employee_Assistant agent"
  sf agent activate --api-name Employee_Assistant
  check_status "Activating Employee_Assistant agent"
fi
echo ""

next_step "Publishing and activating agent: Customer_Service_Assistant..."
if agent_exists "Customer_Service_Assistant"; then
  echo "Agent Customer_Service_Assistant already exists, skipping."
else
  sf agent publish authoring-bundle --api-name Customer_Service_Assistant
  check_status "Publishing Customer_Service_Assistant agent"
  sf agent activate --api-name Customer_Service_Assistant
  check_status "Activating Customer_Service_Assistant agent"
fi
echo ""

next_step "Deploying site source..."
sf project deploy start --source-dir src-site --ignore-conflicts
check_status "Deploying site source"
echo ""

next_step "Deploying headless source..."
sf project deploy start --source-dir src-headless --ignore-conflicts
check_status "Deploying headless source"
echo ""

next_step "Activating messaging channel..."
sf apex run --file apex-scripts/activate-messaging-channel.apex
check_status "Activating messaging channel"
echo ""

next_step "Assigning user permission set..."
sf org assign permset --name Merchant_Management_App
check_status "Assigning user permission set"
echo ""

next_step "Assigning agent permission set..."
sf org assign permset --name Customer_Service_Assistant --on-behalf-of "$PRONTO_AGENT_USERNAME"
check_status "Assigning agent permission set"
echo ""

next_step "Importing sample data..."
sf data tree import --plan data/data-plan.json
check_status "Importing sample data"
echo ""

next_step "Generating sample data: adding storefront thumbnails..."
sf apex run --file apex-scripts/set-storefront-thumbnails.apex
check_status "Adding storefront thumbnails"
echo ""

next_step "Generating sample data: setting storefront operating hours..."
sf apex run --file apex-scripts/set-storefront-opening-hours.apex
check_status "Setting storefront operating hours"
echo ""

next_step "Sleeping 30s for Experience Cloud deployment..."
sleep 30
echo ""

next_step "Publishing Experience Cloud site..."
sf community publish --name "Pronto Customer Site"
check_status "Publishing Experience Cloud site"
echo ""

next_step "Opening org so that you can publish the Embedded Service Deployment..."
sf org open --path lightning/setup/EmbeddedServiceDeployments/home
echo ""

echo "Installation completed."
echo ""
