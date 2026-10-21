@echo off
setlocal enabledelayedexpansion

set "SCRIPT_PATH=%~dp0"
cd /d "%SCRIPT_PATH%.."

rem Set parameters
set "ORG_ALIAS=pronto-scratch"
set "TMPJSON=%TEMP%\pronto_install.json"
set "STEP=0"

echo.
echo Pronto installer
echo.
echo Select installation type:
echo   1) DE Org, Trailhead Playground or existing org (deploys to your current default org)
echo   2) Scratch org (creates a fresh scratch org named "%ORG_ALIAS%")
echo.
set /p "INSTALL_CHOICE=Enter choice [1-2]: "
echo.

if "%INSTALL_CHOICE%"=="1" (
    set "INSTALL_TYPE=prod"
) else if "%INSTALL_CHOICE%"=="2" (
    set "INSTALL_TYPE=scratch"
) else (
    echo Install failed: invalid choice "%INSTALL_CHOICE%" 1>&2
    exit /b 1
)

if "%INSTALL_TYPE%"=="scratch" (
    set "TOTAL_STEPS=25"
) else (
    set "TOTAL_STEPS=23"
)

if "%INSTALL_TYPE%"=="prod" (
    call :next_step "Validating default org..."
    sf org display --json > "%TMPJSON%"
    call :check_status "Validating default org"
    if errorlevel 1 exit /b 1
    call :json_get "%TMPJSON%" "$j.result.alias" ORG_ALIAS
    call :check_var "org alias" "%ORG_ALIAS%"
    if errorlevel 1 exit /b 1
    echo.
)

echo Ready to install Pronto to org alias %ORG_ALIAS%
echo.

if "%INSTALL_TYPE%"=="prod" (
    echo Please confirm that you've enabled all the required features listed in the README.
    echo Installation will fail if any of these features are not enabled.
    echo.
)

set /p "CONFIRM_INSTALL=Continue? [y/N]: "
if /i not "%CONFIRM_INSTALL%"=="y" (
    echo Install cancelled. 1>&2
    exit /b 1
)
echo.

if "%INSTALL_TYPE%"=="scratch" (
    call :next_step "Removing previous scratch org (if any exists)..."
    sf org delete scratch --no-prompt --target-org %ORG_ALIAS% >nul 2>&1
    echo.
)

call :next_step "Cleaning previous org-specific metadata..."
node bin\clean-hardcoded-values.js ^
  "src-base/main/default/aiAuthoringBundles/**/*.agent" ^
  "src-base/main/default/flows/*.flow-meta.xml" ^
  "src-site/main/default/pages/ESWCustomerServiceAgent.page" ^
  "src-site/main/default/digitalExperiences/site/ESW_Customer_Service_Agent1/sfdc_cms__trustedSites/trustedSites/content.json" ^
  "src-site/main/default/digitalExperiences/site/Pronto_Customer_Site1/sfdc_cms__themeLayout/scopedHeaderAndFooter/content.json" ^
  "src-site/main/default/digitalExperiences/site/Pronto_Customer_Site1/sfdc_cms__view/home/content.json" ^
  "src-site/main/default/sites/*.site-meta.xml"
call :check_status "Cleaning previous org-specific metadata"
if errorlevel 1 exit /b 1
echo.

if "%INSTALL_TYPE%"=="scratch" (
    call :next_step "Creating scratch org..."
    sf org create scratch --definition-file config/project-scratch-def.json --alias %ORG_ALIAS% --set-default --duration-days 30 --wait 10
    call :check_status "Creating scratch org"
    if errorlevel 1 exit /b 1
    echo.

    call :next_step "Sleeping for 5 minutes while waiting for HXL provisioning..."
    timeout /t 300 /nobreak >nul
    echo.
)

call :next_step "Extracting org info..."
sf org display --json > "%TMPJSON%"
call :check_status "Extracting org info"
if errorlevel 1 exit /b 1
call :json_get "%TMPJSON%" "$j.result.id" PRONTO_ORG_ID
call :check_var "org ID" "%PRONTO_ORG_ID%"
if errorlevel 1 exit /b 1
echo Org ID:                    %PRONTO_ORG_ID%
call :json_get "%TMPJSON%" "$j.result.instanceUrl" PRONTO_ORG_INSTANCE_URL
call :check_var "org domain" "%PRONTO_ORG_INSTANCE_URL%"
if errorlevel 1 exit /b 1
for /f "usebackq delims=" %%D in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "'%PRONTO_ORG_INSTANCE_URL%' -replace '\.my\.salesforce\.com$',''"`) do set "PRONTO_ORG_DOMAIN=%%D"
echo Org Domain:                %PRONTO_ORG_DOMAIN%
echo.

call :next_step "Looking for existing agent user..."
sf data query --query "SELECT Id, Username FROM User WHERE Username LIKE 'agent.user.%%' LIMIT 1" --json > "%TMPJSON%"
call :check_status "Querying for existing agent user"
if errorlevel 1 exit /b 1
call :json_get "%TMPJSON%" "$j.result.records[0].Id" PRONTO_AGENT_USER_ID_FROM_QUERY
if defined PRONTO_AGENT_USER_ID_FROM_QUERY (
    if not "%PRONTO_AGENT_USER_ID_FROM_QUERY%"=="null" (
        echo Found existing agent user.
        call :json_get "%TMPJSON%" "$j.result.records[0].Username" PRONTO_AGENT_USERNAME
        goto :agent_user_done
    )
)
echo No existing agent user found, creating one...
sf org create agent-user --json > "%TMPJSON%"
call :check_status "Creating agent user"
if errorlevel 1 exit /b 1
call :json_get "%TMPJSON%" "$j.result.username" PRONTO_AGENT_USERNAME
:agent_user_done
echo.

call :next_step "Extracting agent user info..."
call :check_var "service agent user name" "%PRONTO_AGENT_USERNAME%"
if errorlevel 1 exit /b 1
echo Service agent user name:   %PRONTO_AGENT_USERNAME%
echo.

call :next_step "Deploying service agent queues source..."
sf project deploy start --source-dir src-queues --ignore-conflicts
call :check_status "Deploying service agent queues source"
if errorlevel 1 exit /b 1
echo.

call :next_step "Extracting service agent IDs..."
sf data query --query "SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Customer Service Messaging Queue'" --json > "%TMPJSON%"
call :check_status "Querying for service agent routing queue ID"
if errorlevel 1 exit /b 1
call :json_get "%TMPJSON%" "$j.result.records[0].Id" PRONTO_AGENT_ROUTING_QUEUE_ID
call :check_var "service agent routing queue ID" "%PRONTO_AGENT_ROUTING_QUEUE_ID%"
if errorlevel 1 exit /b 1
echo Service agent routing queue ID:        %PRONTO_AGENT_ROUTING_QUEUE_ID%
sf data query --query "SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Customer Service Escalation Queue'" --json > "%TMPJSON%"
call :check_status "Querying for service agent escalation queue ID"
if errorlevel 1 exit /b 1
call :json_get "%TMPJSON%" "$j.result.records[0].Id" PRONTO_ESCALATION_ROUTING_QUEUE_ID
call :check_var "service agent escalation queue ID" "%PRONTO_ESCALATION_ROUTING_QUEUE_ID%"
if errorlevel 1 exit /b 1
echo Service agent escalation queue ID:     %PRONTO_ESCALATION_ROUTING_QUEUE_ID%
echo.

call :next_step "Deploying base source..."
sf project deploy start --source-dir src-base --ignore-conflicts
call :check_status "Deploying base source"
if errorlevel 1 exit /b 1
echo.

call :next_step "Publishing and activating agent: Storefront_Explorer_Assistant..."
call :agent_exists "Storefront_Explorer_Assistant"
if !ERRORLEVEL!==0 (
    echo Agent Storefront_Explorer_Assistant already exists, skipping.
) else (
    sf agent publish authoring-bundle --api-name Storefront_Explorer_Assistant
    call :check_status "Publishing Storefront_Explorer_Assistant agent"
    if errorlevel 1 exit /b 1
    sf agent activate --api-name Storefront_Explorer_Assistant
    call :check_status "Activating Storefront_Explorer_Assistant agent"
    if errorlevel 1 exit /b 1
)
echo.

call :next_step "Publishing and activating agent: Customer_Order_Assistant..."
call :agent_exists "Customer_Order_Assistant"
if !ERRORLEVEL!==0 (
    echo Agent Customer_Order_Assistant already exists, skipping.
) else (
    sf agent publish authoring-bundle --api-name Customer_Order_Assistant
    call :check_status "Publishing Customer_Order_Assistant agent"
    if errorlevel 1 exit /b 1
    sf agent activate --api-name Customer_Order_Assistant
    call :check_status "Activating Customer_Order_Assistant agent"
    if errorlevel 1 exit /b 1
)
echo.

call :next_step "Publishing and activating agent: Employee_Assistant..."
call :agent_exists "Employee_Assistant"
if !ERRORLEVEL!==0 (
    echo Agent Employee_Assistant already exists, skipping.
) else (
    sf agent publish authoring-bundle --api-name Employee_Assistant
    call :check_status "Publishing Employee_Assistant agent"
    if errorlevel 1 exit /b 1
    sf agent activate --api-name Employee_Assistant
    call :check_status "Activating Employee_Assistant agent"
    if errorlevel 1 exit /b 1
)
echo.

call :next_step "Publishing and activating agent: Customer_Service_Assistant..."
call :agent_exists "Customer_Service_Assistant"
if !ERRORLEVEL!==0 (
    echo Agent Customer_Service_Assistant already exists, skipping.
) else (
    sf agent publish authoring-bundle --api-name Customer_Service_Assistant
    call :check_status "Publishing Customer_Service_Assistant agent"
    if errorlevel 1 exit /b 1
    sf agent activate --api-name Customer_Service_Assistant
    call :check_status "Activating Customer_Service_Assistant agent"
    if errorlevel 1 exit /b 1
)
echo.

call :next_step "Deploying site source..."
sf project deploy start --source-dir src-site --ignore-conflicts
call :check_status "Deploying site source"
if errorlevel 1 exit /b 1
echo.

call :next_step "Deploying headless source..."
sf project deploy start --source-dir src-headless --ignore-conflicts
call :check_status "Deploying headless source"
if errorlevel 1 exit /b 1
echo.

call :next_step "Activating messaging channel..."
sf apex run --file apex-scripts\activate-messaging-channel.apex
call :check_status "Activating messaging channel"
if errorlevel 1 exit /b 1
echo.

call :next_step "Assigning user permission set..."
sf org assign permset --name Merchant_Management_App
call :check_status "Assigning user permission set"
if errorlevel 1 exit /b 1
echo.

call :next_step "Assigning agent permission set..."
sf org assign permset --name Customer_Service_Assistant --on-behalf-of "%PRONTO_AGENT_USERNAME%"
call :check_status "Assigning agent permission set"
if errorlevel 1 exit /b 1
echo.

call :next_step "Importing sample data..."
sf data tree import --plan data\data-plan.json
call :check_status "Importing sample data"
if errorlevel 1 exit /b 1
echo.

call :next_step "Generating sample data: adding storefront thumbnails..."
sf apex run --file apex-scripts\set-storefront-thumbnails.apex
call :check_status "Adding storefront thumbnails"
if errorlevel 1 exit /b 1
echo.

call :next_step "Generating sample data: setting storefront operating hours..."
sf apex run --file apex-scripts\set-storefront-opening-hours.apex
call :check_status "Setting storefront operating hours"
if errorlevel 1 exit /b 1
echo.

call :next_step "Sleeping 30s for Experience Cloud deployment..."
timeout /t 30 /nobreak >nul
echo.

call :next_step "Publishing Experience Cloud site..."
sf community publish --name "Pronto Customer Site"
call :check_status "Publishing Experience Cloud site"
if errorlevel 1 exit /b 1
echo.

call :next_step "Opening org so that you can publish the Embedded Service Deployment..."
sf org open --path lightning/setup/EmbeddedServiceDeployments/home
echo.

echo Installation completed.
echo.

del /q "%TMPJSON%" >nul 2>&1
endlocal
exit /b 0

rem ---------------------------------------------------------------------
rem Subroutines
rem ---------------------------------------------------------------------

rem Checks that the previous command succeeded (relies on ERRORLEVEL
rem surviving the CALL, since CALL to a label does not spawn a process)
:check_status
if not "%ERRORLEVEL%"=="0" (
    echo Install failed: %~1 failed 1>&2
    exit /b 1
)
exit /b 0

rem Checks that a variable has a value
:check_var
if "%~2"=="" (
    echo Install failed: Failed to retrieve %~1 1>&2
    exit /b 1
)
if "%~2"=="null" (
    echo Install failed: Failed to retrieve %~1 1>&2
    exit /b 1
)
exit /b 0

rem Reads a value out of a JSON file into a variable using PowerShell.
rem %1 = json file path, %2 = PowerShell expression referencing $j, %3 = output variable name
:json_get
set "%~3="
for /f "usebackq delims=" %%J in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$j = Get-Content -Raw '%~1' | ConvertFrom-Json; try { %~2 } catch { '' }"`) do set "%~3=%%J"
exit /b 0

rem Checks whether an agent (GenAiPlannerDefinition) already exists for a given DeveloperName
rem Returns 0 if it exists, 1 if it does not, 2 on query failure
:agent_exists
set "_DEV_NAME=%~1"
sf data query --query "SELECT Id FROM GenAiPlannerDefinition WHERE DeveloperName LIKE '%_DEV_NAME%%%'" --json > "%TMPJSON%"
if errorlevel 1 (
    echo Install failed: Querying for existing agent %_DEV_NAME% failed 1>&2
    exit /b 2
)
call :json_get "%TMPJSON%" "$j.result.records[0].Id" _AGENT_ID
if defined _AGENT_ID (
    if not "%_AGENT_ID%"=="null" (
        exit /b 0
    )
)
exit /b 1

rem Prints a numbered step header
:next_step
set /a STEP+=1
echo [%STEP%/%TOTAL_STEPS%] %~1
exit /b 0
