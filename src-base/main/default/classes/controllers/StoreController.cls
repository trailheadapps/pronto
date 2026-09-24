/**
 * Controller that exposes storefront listing endpoints to Lightning components.
 */
global with sharing class StoreController {
  /**
   * Endpoint that retrieves a paged and filtered list of stores
   * @param searchKey String used for searching on store name and owner
   * @param type Storefront type
   * @param cuisine Storefront cuisine
   * @param minReviewScore Minimum review score
   * @param pageSize Number of stores per page
   * @param pageNumber Page number
   * @return PagedResult object holding the paged and filtered list of stores
   */
  @AuraEnabled(cacheable=true scope='global')
  global static PagedResult getPagedStoreList(
    String searchKey,
    String type,
    String cuisine,
    Integer minReviewScore,
    Integer pageSize,
    Integer pageNumber
  ) {
    return new StorefrontService().searchStorefronts(searchKey, type, cuisine, minReviewScore, pageSize, pageNumber);
  }
}
