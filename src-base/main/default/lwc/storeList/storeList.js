import { LightningElement, wire } from "lwc";
import { publish, subscribe, unsubscribe, MessageContext } from "lightning/messageService";
import FILTERS_CHANGE_MC from "@salesforce/messageChannel/FiltersChange__c";
import STORE_SELECTED_MC from "@salesforce/messageChannel/StoreSelected__c";
import getPagedStoreList from "@salesforce/apex/StoreController.getPagedStoreList";

const PAGE_SIZE = 9;

export default class StoreList extends LightningElement {
  pageNumber = 1;
  pageSize = PAGE_SIZE;

  searchKey = "";
  type = "";
  cuisine = "";
  minReviewScore = 0;

  @wire(MessageContext)
  messageContext;

  @wire(getPagedStoreList, {
    searchKey: "$searchKey",
    type: "$type",
    cuisine: "$cuisine",
    minReviewScore: "$minReviewScore",
    pageSize: "$pageSize",
    pageNumber: "$pageNumber"
  })
  stores;

  connectedCallback() {
    this.subscription = subscribe(this.messageContext, FILTERS_CHANGE_MC, (message) => {
      this.handleFilterChange(message);
    });
  }

  disconnectedCallback() {
    unsubscribe(this.subscription);
    this.subscription = null;
  }

  handleFilterChange(filters) {
    this.searchKey = filters.searchKey;
    this.type = filters.type;
    this.cuisine = filters.cuisine;
    this.minReviewScore = filters.minReviewScore;
    this.pageNumber = 1;
  }

  handlePreviousPage() {
    this.pageNumber = this.pageNumber - 1;
  }

  handleNextPage() {
    this.pageNumber = this.pageNumber + 1;
  }

  handleStoreSelected(event) {
    const message = { storeId: event.detail };
    publish(this.messageContext, STORE_SELECTED_MC, message);
  }
}
