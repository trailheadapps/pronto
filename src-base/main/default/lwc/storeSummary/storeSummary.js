import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { gql, graphql } from "lightning/graphql";
import { NavigationMixin } from "lightning/navigation";
import { subscribe, unsubscribe, MessageContext } from "lightning/messageService";
import STORE_SELECTED_MC from "@salesforce/messageChannel/StoreSelected__c";

// Storefront fields
import NAME_FIELD from "@salesforce/schema/Storefront__c.Name";
import TYPE_FIELD from "@salesforce/schema/Storefront__c.Type__c";
import CUISINE_FIELD from "@salesforce/schema/Storefront__c.Cuisine__c";
import DESCRIPTION_FIELD from "@salesforce/schema/Storefront__c.Description__c";
import SCORE_FIELD from "@salesforce/schema/Storefront__c.Average_Review_Score__c";
import TOTAL_REVIEWS_FIELD from "@salesforce/schema/Storefront__c.Total_Reviews__c";
import PICTURE_FIELD from "@salesforce/schema/Storefront__c.Thumbnail__c";

export default class StoreSummary extends NavigationMixin(LightningElement) {
  storeId;
  storeFormFields = [TYPE_FIELD, CUISINE_FIELD, DESCRIPTION_FIELD];
  subscription = null;
  openingHoursError;
  openingHours = [];
  menus = [];
  menusError;

  @wire(MessageContext)
  messageContext;

  @wire(getRecord, {
    recordId: "$storeId",
    fields: [NAME_FIELD, PICTURE_FIELD, SCORE_FIELD, TOTAL_REVIEWS_FIELD]
  })
  store;

  @wire(graphql, {
    query: gql`
      query getStoreOpeningHours($storeId: ID) {
        uiapi {
          query {
            Storefront_Hours_of_Operation__c(
              where: { Storefront__c: { eq: $storeId } }
              orderBy: { Day_of_Week__c: { order: ASC } }
            ) {
              edges {
                node {
                  Id
                  Day_of_Week__c {
                    value
                  }
                  Opening_Time__c {
                    value
                  }
                  Closing_Time__c {
                    value
                  }
                }
              }
            }
          }
        }
      }
    `,
    variables: "$openingHoursVariables"
  })
  wiredOpeningHours({ data, errors }) {
    if (data) {
      this.openingHours = data.uiapi.query.Storefront_Hours_of_Operation__c.edges.map((edge) => ({
        id: edge.node.Id,
        dayOfWeek: edge.node.Day_of_Week__c.value,
        openingTime: edge.node.Opening_Time__c.value,
        closingTime: edge.node.Closing_Time__c.value
      }));
      this.openingHoursError = undefined;
    } else if (errors) {
      this.openingHours = [];
      this.openingHoursError = errors;
    }
  }

  @wire(graphql, {
    query: gql`
      query getStoreMenus($storeId: ID) {
        uiapi {
          query {
            Menu__c(
              where: { and: [{ Storefront__c: { eq: $storeId } }, { Active__c: { eq: true } }] }
              orderBy: { Menu_Display_Name__c: { order: ASC } }
            ) {
              edges {
                node {
                  Id
                  Menu_Display_Name__c {
                    value
                  }
                  Description__c {
                    value
                  }
                }
              }
            }
          }
        }
      }
    `,
    variables: "$menusVariables"
  })
  wiredMenus({ data, errors }) {
    if (data) {
      this.menus = data.uiapi.query.Menu__c.edges.map((edge) => ({
        id: edge.node.Id,
        displayName: edge.node.Menu_Display_Name__c.value,
        description: edge.node.Description__c.value
      }));
      this.menusError = undefined;
    } else if (errors) {
      this.menus = [];
      this.menusError = errors;
    }
  }

  @api
  get recordId() {
    return this.storeId;
  }

  set recordId(storeId) {
    this.storeId = storeId;
  }

  connectedCallback() {
    this.subscription = subscribe(this.messageContext, STORE_SELECTED_MC, (message) => {
      this.handleStoreSelected(message);
    });
  }

  disconnectedCallback() {
    unsubscribe(this.subscription);
    this.subscription = null;
  }

  handleStoreSelected(message) {
    this.storeId = message.storeId;
  }

  handleNavigateToRecord() {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: this.storeId,
        objectApiName: "Storefront__c",
        actionName: "view"
      }
    });
  }

  handleMenuClick(event) {
    const menuId = event.currentTarget.dataset.menuId;
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: menuId,
        objectApiName: "Menu__c",
        actionName: "view"
      }
    });
  }

  get openingHoursVariables() {
    return { storeId: this.storeId };
  }

  get menusVariables() {
    return { storeId: this.storeId };
  }

  get hasOpeningHours() {
    return this.openingHours.length > 0;
  }

  get hasMenus() {
    return this.menus.length > 0;
  }

  get hasNoStoreId() {
    return this.storeId === undefined;
  }

  get storeName() {
    return getFieldValue(this.store.data, NAME_FIELD);
  }

  get pictureURL() {
    return getFieldValue(this.store.data, PICTURE_FIELD);
  }

  get reviewScore() {
    return getFieldValue(this.store.data, SCORE_FIELD);
  }

  get numberOfReviews() {
    return getFieldValue(this.store.data, TOTAL_REVIEWS_FIELD);
  }
}
