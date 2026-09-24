import { LightningElement, wire } from "lwc";
import { publish, MessageContext } from "lightning/messageService";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import FILTERS_CHANGE_MC from "@salesforce/messageChannel/FiltersChange__c";
import TYPE_FIELD from "@salesforce/schema/Storefront__c.Type__c";
import CUISINE_FIELD from "@salesforce/schema/Storefront__c.Cuisine__c";

const DELAY = 350;

export default class StoreFilter extends LightningElement {
  searchKey = "";
  type = "";
  cuisine = "";
  minReviewScore = 0;
  typeOptions = [];
  cuisineOptions = [];

  @wire(MessageContext)
  messageContext;

  @wire(getObjectInfo, { objectApiName: "Storefront__c" })
  objectInfo;

  @wire(getPicklistValues, {
    recordTypeId: "$objectInfo.data.defaultRecordTypeId",
    fieldApiName: TYPE_FIELD
  })
  getTypes({ data, error }) {
    if (data) {
      this.typeOptions = data.values.map((value) => ({
        label: value.label,
        value: value.value
      }));
    } else if (error) {
      console.error("Error fetching types:", error);
    }
  }

  @wire(getPicklistValues, {
    recordTypeId: "$objectInfo.data.defaultRecordTypeId",
    fieldApiName: CUISINE_FIELD
  })
  getCuisines({ data, error }) {
    if (data) {
      this.cuisineOptions = data.values.map((value) => ({
        label: value.label,
        value: value.value
      }));
    } else if (error) {
      console.error("Error fetching cuisines:", error);
    }
  }

  handleReset() {
    this.searchKey = "";
    this.type = "";
    this.cuisine = "";
    this.minReviewScore = 0;
    this.fireChangeEvent();
  }

  handleSearchKeyChange(event) {
    this.searchKey = event.detail.value;
    this.fireChangeEvent();
  }

  handleTypeChange(event) {
    this.type = event.detail.value;
    this.fireChangeEvent();
  }

  handleCuisineChange(event) {
    this.cuisine = event.detail.value;
    this.fireChangeEvent();
  }

  handleMinReviewScoreChange(event) {
    this.minReviewScore = event.target.value;
    this.fireChangeEvent();
  }

  fireChangeEvent() {
    // Debouncing this method: Do not actually fire the event as long as this function is
    // being called within a delay of DELAY. This is to avoid a very large number of Apex
    // method calls in components listening to this event.
    window.clearTimeout(this.delayTimeout);
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.delayTimeout = setTimeout(() => {
      const filters = {
        searchKey: this.searchKey,
        type: this.type,
        cuisine: this.cuisine,
        minReviewScore: parseInt(this.minReviewScore, 10)
      };
      console.log("Searching: ", filters);
      publish(this.messageContext, FILTERS_CHANGE_MC, filters);
    }, DELAY);
  }
}
