[![CI](https://github.com/trailheadapps/pronto/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/trailheadapps/pronto/actions/workflows/ci.yml)

![Pronto illustration image](src-base/main/default/staticresources/pronto_org_images/pronto-org-images/pronto-business-account-hero.png)

# Pronto Sample App

## About

Pronto is a fictional, AI-driven food delivery platform that uses AIforce and the Salesforce Platform to serve their customers.

The sample app ships with the following:

- Custom data model (storefronts, orders, reviews, menus...) along with the related sample records
- Storefront Explorer Lightning page
- LWR Site for customer support
- Agentforce Agents with their actions:
  - Customer Service Assistant agent (browse storefronts, manage orders...)
  - Employee Assistant agent (browse storefronts, view orders, view reviews...)
- Custom hosted MCP server with
  - tools for order management and storefront browsing
  - Headless Experience Layer (HXL) widgets for rendering a rich UI in third party agents (order status) and Agentforce actions (customer reviews)

## Requirements

The Pronto app is set up via an installation script that requires the following:

- **Salesforce CLI**'s latest version. Here's how you can [install](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_install_cli.htm) or [update](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_update_cli.htm) it.
- **[Node.js LTS](https://nodejs.org/en/download)** (v22 or above)
- if running on macOS or Unix: **[jq](https://jqlang.org/)**
- if running on Windows: **[PowerShell](https://apps.microsoft.com/detail/9mz1snwt0n5d?hl=en-US&gl=LU)**

### Scratch Org Requirements

If installing the app on a scratch org, you will need a **[Dev Hub Org](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_setup_enable_devhub.htm)** configured with the Salesforce CLI. You can sign up for a free [Developer Edition Org](https://developer.salesforce.com/signup) for this.

### Requirements for Other Types of Orgs

If installing the app on a Sandbox, a Developer Edition org or a Trailhead Playground, enable all of the following features. Failure to do so will cause the installation to fail.

1. Go to **Setup > User Interface** and click **Enable Custom Addresses**
1. Go to **Setup > State and Country/Territory Picklists** and click **Enable State and Country/Territory Picklists**
1. Go to **Setup > Digital Experiences > Settings** and click **Enable ExperienceBundle Metadata API**
1. Go to **Setup > Omni-Channel Settings** and enable **Enable Omni-Channel**
1. Go to **Setup > Agentforce Studio > Agentforce Agents** and enable **Agentforce**
1. Go to **Setup > Messaging Settings** and enable **Messaging**
1. Go to **Setup > Einstein Platform > Einstein Bots** and enable **Bots**
1. Go to **Setup > Feature Settings > Headless Experience Layer Settings** and enable **Headless Experience Layer (Beta)**

## Setup Instructions

1. Clone the project from GitHub.
1. Open a terminal in the project folder.
1. If installing on a non-scratch org, authenticate to your org and set it as the default org for the project with the Salesforce CLI:

   ```sh
   sf auth web login --alias pronto --set-default
   ```

1. Run the installation script from the project root folder:

   macOS and Unix:

   ```sh
   ./bin/install.sh
   ```

   Windows PowerShell:

   ```bat
   bin\install.bat
   ```

1. Publish the `Customer_Service_Agent` Embedded Service Deployment:

   The installation script automatically opens the org on the **Embedded Service Deployment** setup page. If you close the page, you can find it in Salesforce Setup by searching for `embedded` in the Quick Find box and clicking **Embedded Service Deployments**.

   1. Click **Customer_Service_Agent**.
   1. Click **Publish**.

## Pronto Data Model

The Pronto app relies on the following objects (non-relationship fields are hidden from this diagram):

```mermaid
erDiagram
    CONTACT ||--o{ STOREFRONT__C : "is primary contact for"
    CONTACT ||--o{ ORDER__C : "places"
    CONTACT ||--o{ REVIEW__C : "writes"
    STOREFRONT__C ||--o{ MENU__C : "offers"
    STOREFRONT__C ||--o{ ORDER__C : "receives"
    STOREFRONT__C ||--o{ REVIEW__C : "receives"
    STOREFRONT__C ||--o{ STOREFRONT_HOURS_OF_OPERATION__C : "has"
    MENU__C ||--o{ MENU_ITEM__C : "contains"
    ORDER__C ||--o{ ORDER_ITEM__C : "contains"
    MENU_ITEM__C ||--o{ ORDER_ITEM__C : "ordered as"

    CONTACT {
        id Id PK
    }

    STOREFRONT__C {
        id Id PK
        lookup Account__c FK
        lookup Primary_Contact__c FK
    }

    MENU__C {
        id Id PK
        masterdetail Storefront__c FK
    }

    MENU_ITEM__C {
        id Id PK
        lookup Menu__c FK
    }

    ORDER__C {
        id Id PK
        lookup Customer__c FK
        masterdetail Storefront__c FK
    }

    ORDER_ITEM__C {
        id Id PK
        masterdetail Order__c FK
        lookup Menu_Item__c FK
    }

    REVIEW__C {
        id Id PK
        masterdetail Storefront__c FK
        lookup Customer__c FK
    }

    STOREFRONT_HOURS_OF_OPERATION__C {
        id Id PK
        masterdetail Storefront__c FK
    }
```
