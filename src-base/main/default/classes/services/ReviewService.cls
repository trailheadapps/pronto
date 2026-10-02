/**
 * Service layer for customer review operations. Encapsulates all
 * SOQL/DML and job orchestration related to Review__c records so that invocable
 * actions and other callers remain free of data-access logic.
 */
public virtual with sharing class ReviewService {
  /**
   * Retrieves customer reviews for a given storefront, most recent first.
   * @param storefrontId The ID of the storefront to retrieve reviews for
   * @return List of reviews for the storefront
   * @throws ReviewException if storefrontId is null
   * @example
   * ReviewService service = new ReviewService();
   * List<Review__c> reviews = service.getReviewsForStorefront(storefrontId);
   */
  public virtual List<Review__c> getReviewsForStorefront(Id storefrontId) {
    if (storefrontId == null) {
      throw new ReviewException('A storefront ID must be provided.');
    }

    return [
      SELECT
        Id,
        Name,
        Comments__c,
        Rating__c,
        Customer__r.Name,
        Customer_Email__c,
        Order_Date__c,
        Positive_or_Negative__c,
        Status__c,
        Category__c,
        Restaurant_Response__c,
        Storefront__r.Name
      FROM Review__c
      WHERE Storefront__c = :storefrontId
      WITH USER_MODE
      ORDER BY Order_Date__c DESC NULLS LAST, CreatedDate DESC
      LIMIT 10
    ];
  }

  /**
   * Posts the restaurant's reply to a specific customer review.
   * @param reviewId The ID of the review to reply to
   * @param responseText The restaurant's reply text
   * @return The updated review
   * @throws ReviewException if reviewId or responseText is blank, or if no matching review is found
   * @example
   * ReviewService service = new ReviewService();
   * Review__c review = service.replyToReview(reviewId, 'Thank you for your feedback!');
   */
  public virtual Review__c replyToReview(Id reviewId, String responseText) {
    if (reviewId == null) {
      throw new ReviewException('A review ID must be provided.');
    }
    if (String.isBlank(responseText)) {
      throw new ReviewException('A response text must be provided.');
    }

    List<Review__c> reviews = [SELECT Id, Name FROM Review__c WHERE Id = :reviewId WITH USER_MODE LIMIT 1];
    if (reviews.isEmpty()) {
      throw new ReviewException('No review found with ID: ' + reviewId);
    }
    Review__c review = reviews[0];

    review.Restaurant_Response__c = responseText;
    update as user new Review__c(Id = review.Id, Restaurant_Response__c = responseText);
    return review;
  }

  /**
   * Starts the asynchronous job that regenerates store review summaries.
   * @param forceRefresh Whether to force a refresh even if summaries already exist
   * @example
   * ReviewService service = new ReviewService();
   * service.refreshStoreReviewSummaries(true);
   */
  public virtual void refreshStoreReviewSummaries(Boolean forceRefresh) {
    StoreReviewSummaryAiJob.startJob(forceRefresh == true);
  }

  /**
   * Exception thrown when a review operation cannot be completed.
   */
  public class ReviewException extends Exception {
  }
}
