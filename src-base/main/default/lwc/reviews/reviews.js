import { LightningElement, wire, api } from "lwc";
import { getRelatedListRecords } from "lightning/uiRelatedListApi";
import COMMENTS_FIELD from "@salesforce/schema/Review__c.Comments__c";
import RATING_FIELD from "@salesforce/schema/Review__c.Rating__c";
import ORDER_DATE_FIELD from "@salesforce/schema/Review__c.Order_Date__c";

export default class Reviews extends LightningElement {
  reviews = [];

  @api storeId;

  @wire(getRelatedListRecords, {
    parentRecordId: "$storeId",
    relatedListId: "Reviews__r",
    fields: [COMMENTS_FIELD, RATING_FIELD, ORDER_DATE_FIELD],
    sortBy: [ORDER_DATE_FIELD]
  })
  getReviews({ error, data }) {
    if (data) {
      this.reviews = data.records.map((review) => ({
        id: review.id,
        rating: review.fields.Rating__c.value,
        comments: review.fields.Comments__c.value
      }));
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.reviews = undefined;
    }
  }
}
