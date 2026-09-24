import { LightningElement, api } from "lwc";

export default class GenericPageHeader extends LightningElement {
  @api title;
  @api subtitle;
  @api iconName;
  @api showIcon;
  @api iconSize = "large";
  @api iconAlternativeText = "";
  @api headerClass = "";
  @api titleClass = "";
  @api subtitleClass = "";

  // Computed properties for conditional rendering
  get shouldShowIcon() {
    return this.showIcon !== false && this.iconName;
  }

  get iconAltText() {
    return this.iconAlternativeText || `${this.title || "Page"} Icon`;
  }

  get hasDetailsSlot() {
    // Check if details slot has content
    const detailsSlot = this.template.querySelector('slot[name="details"]');
    return detailsSlot && detailsSlot.assignedElements().length > 0;
  }
}
