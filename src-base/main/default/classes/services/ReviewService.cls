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
