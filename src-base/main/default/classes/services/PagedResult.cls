/**
 * DTO holding a paged and filtered list of records along with pagination metadata.
 */
global with sharing class PagedResult {
  /**
   * Number of records per page.
   */
  @AuraEnabled
  public Integer pageSize { get; set; }

  /**
   * Current page number.
   */
  @AuraEnabled
  public Integer pageNumber { get; set; }

  /**
   * Total number of records matching the query, across all pages.
   */
  @AuraEnabled
  public Integer totalItemCount { get; set; }

  /**
   * Records for the current page.
   */
  @AuraEnabled
  public Object[] records { get; set; }
}
