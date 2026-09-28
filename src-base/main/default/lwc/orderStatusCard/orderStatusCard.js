import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";

const STATUS_OUT_FOR_DELIVERY = "Out for Delivery";
const STATUS_UNKNOWN_INDEX = 0;

// Status configuration for styling
const STATUS_CONFIG = [
  { label: "Unknown", variant: "base", icon: "utility:help" },
  { label: "Draft", variant: "base", icon: "utility:edit" },
  { label: "Confirmed", variant: "success", icon: "utility:approval" },
  { label: "Processed", variant: "success", icon: "utility:settings" },
  { label: "Out for Delivery", variant: "warning", icon: "utility:truck" },
  { label: "Delivered", variant: "success", icon: "utility:check" },
  { label: "Canceled", variant: "error", icon: "utility:close" }
];

export default class OrderStatusCard extends NavigationMixin(LightningElement) {
  @api value;

  getStatusInfo() {
    return STATUS_CONFIG.find((status) => status.label === this.value?.status) ?? STATUS_CONFIG[STATUS_UNKNOWN_INDEX];
  }

  get mapMarkers() {
    if (this.value?.status === STATUS_OUT_FOR_DELIVERY) {
      return [
        { latitude: 37.7897441, longitude: -122.4021046, title: "Storefront Location" },
        { latitude: 37.7875941, longitude: -122.400459, title: "Driver Location" },
        { latitude: 37.7835, longitude: -122.403, title: "Delivery Location" }
      ];
    }
    return null;
  }

  get cardTitle() {
    return `Order ${this.value?.name}`;
  }

  get statusIconName() {
    return this.getStatusInfo().icon;
  }

  get statusLabel() {
    return this.getStatusInfo().label;
  }

  get statusVariant() {
    return this.getStatusInfo().variant;
  }

  get statusBadgeClass() {
    return `status-variant-${this.statusVariant}`;
  }

  get storefrontName() {
    return this.value?.storefrontName;
  }

  get formattedTotalAmount() {
    if (!this.value?.totalAmount) {
      return "$0.00";
    }
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD"
    }).format(this.value.totalAmount);
  }

  get formattedOrderDate() {
    if (this.value?.orderTime) {
      return new Date(this.value.orderTime).toLocaleDateString();
    }
    return "";
  }

  get formattedOrderTime() {
    if (this.value?.orderTime) {
      return new Date(this.value.orderTime).toLocaleTimeString();
    }
    return "";
  }

  get hasDeliveryTime() {
    return this.value?.deliveryTime != null;
  }

  get formattedDeliveryDate() {
    if (this.hasDeliveryTime) {
      return new Date(this.value.deliveryTime).toLocaleDateString();
    }
    return "";
  }

  get formattedDeliveryTime() {
    if (this.hasDeliveryTime) {
      return new Date(this.value.deliveryTime).toLocaleTimeString();
    }
    return "";
  }

  get deliveryTime() {
    // Add fake delivery time in 10 minutes
    const now = new Date();
    const deliveryTime = new Date(now.getTime() + 10 * 60 * 1000); // 10 minutes from now

    const timeString = deliveryTime.toLocaleTimeString("en-US", {
      hour: "numeric",
      minute: "2-digit",
      hour12: true
    });

    return timeString;
  }

  handleNavigateToOrderRecord() {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: this.value?.id,
        objectApiName: "Order__c",
        actionName: "view"
      }
    });
  }
}
