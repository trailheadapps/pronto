/* eslint-disable @lwc/lwc/no-unexpected-wire-adapter-usages -- wire adapter mocks are driven directly in tests */
import { createElement } from "lwc";
import Reviews from "c/reviews";
import { getRelatedListRecords } from "lightning/uiRelatedListApi";

import COMMENTS_FIELD from "@salesforce/schema/Review__c.Comments__c";
import RATING_FIELD from "@salesforce/schema/Review__c.Rating__c";
import ORDER_DATE_FIELD from "@salesforce/schema/Review__c.Order_Date__c";

// Mock realistic data
import mockGetRelatedListRecords from "./data/getRelatedListRecords.json";

const STORE_ID = "a01xx000003DGb1AAG";

describe("c-reviews", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  // Helper function to wait until the microtask queue is empty.
  // Used when having to wait for asynchronous DOM updates.
  async function flushPromises() {
    return Promise.resolve();
  }

  function createComponent() {
    const element = createElement("c-reviews", {
      is: Reviews
    });
    element.storeId = STORE_ID;
    document.body.appendChild(element);
    return element;
  }

  function getReviewRows(element) {
    return Array.from(element.shadowRoot.querySelectorAll(".slds-grid"));
  }

  it("passes the expected config to the related list wire adapter", async () => {
    createComponent();
    await flushPromises();

    expect(getRelatedListRecords.getLastConfig()).toEqual({
      parentRecordId: STORE_ID,
      relatedListId: "Reviews__r",
      fields: [COMMENTS_FIELD, RATING_FIELD, ORDER_DATE_FIELD],
      sortBy: [ORDER_DATE_FIELD]
    });
  });

  it("renders the heading and no reviews before data is received", () => {
    const element = createComponent();

    const headingEl = element.shadowRoot.querySelector(".slds-text-heading_small");
    expect(headingEl.textContent).toBe("Reviews");
    expect(getReviewRows(element).length).toBe(0);
  });

  it("renders one row per review with comments and rating", async () => {
    const element = createComponent();

    getRelatedListRecords.emit(mockGetRelatedListRecords);
    await flushPromises();

    const rows = getReviewRows(element);
    expect(rows.length).toBe(mockGetRelatedListRecords.records.length);
    rows.forEach((row, index) => {
      const { fields } = mockGetRelatedListRecords.records[index];
      const cols = row.querySelectorAll(".slds-col");
      expect(cols[0].textContent).toBe(fields.Comments__c.value);
      expect(cols[1].textContent).toBe(String(fields.Rating__c.value));
    });
  });

  it("renders no reviews when the wire returns an empty list", async () => {
    const element = createComponent();

    getRelatedListRecords.emit({ ...mockGetRelatedListRecords, count: 0, records: [] });
    await flushPromises();

    expect(getReviewRows(element).length).toBe(0);
  });

  it("clears reviews when the wire returns an error", async () => {
    const element = createComponent();

    getRelatedListRecords.emit(mockGetRelatedListRecords);
    await flushPromises();
    expect(getReviewRows(element).length).toBe(2);

    getRelatedListRecords.error();
    await flushPromises();

    expect(getReviewRows(element).length).toBe(0);
    expect(element.shadowRoot.querySelector(".slds-text-heading_small").textContent).toBe("Reviews");
  });

  it("is accessible when reviews are displayed", async () => {
    const element = createComponent();

    getRelatedListRecords.emit(mockGetRelatedListRecords);
    await flushPromises();

    await expect(element).toBeAccessible();
  });

  it("is accessible when the wire returns an error", async () => {
    const element = createComponent();

    getRelatedListRecords.error();
    await flushPromises();

    await expect(element).toBeAccessible();
  });
});
