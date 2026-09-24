import { LightningElement, api } from "lwc";
import storeTileSquare from "./storeTileSquare.html";
import storeTileHorizontal from "./storeTileHorizontal.html";

export default class valueTile extends LightningElement {
  /**
   * The record value to display (Storefront__c object)
   */
  @api value;

  /**
   * The format of the tile (square or horizontal)
   */
  @api format;

  render() {
    return this.format === "square" ? storeTileSquare : storeTileHorizontal;
  }

  handleStoreSelected() {
    // In other devices, send message to other cmps on the page
    const selectedEvent = new CustomEvent("selected", {
      detail: this.value.Id
    });
    this.dispatchEvent(selectedEvent);
  }

  get backgroundImageStyle() {
    return `background-image:url(${this.value.Thumbnail__c})`;
  }
}
