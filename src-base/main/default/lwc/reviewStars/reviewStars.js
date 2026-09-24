import { LightningElement, api } from "lwc";

const DISPLAY_MODE_COMPACT = "compact";
const DISPLAY_MODE_FULL = "full";

export default class ReviewStars extends LightningElement {
  @api reviewScore;
  @api numberOfReviews;
  @api displayMode;

  get stars() {
    const stars = [];
    const reviewScore = this.reviewScore === undefined ? 0 : Math.round(this.reviewScore);
    for (let i = 0; i < 5; i++) {
      stars.push({
        index: i,
        iconName: i < reviewScore ? "utility:favorite" : "utility:favorite_alt"
      });
    }
    return stars;
  }

  get overviewLabel() {
    return `${this.reviewScore}/5 based on ${this.numberOfReviews} reviews`;
  }

  get isCompactDisplay() {
    return this.displayMode === DISPLAY_MODE_COMPACT;
  }

  get isFullDisplay() {
    return this.displayMode === DISPLAY_MODE_FULL;
  }
}
