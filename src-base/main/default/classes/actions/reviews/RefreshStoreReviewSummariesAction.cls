/**
 * Invocable Action for refreshing store review summaries
 */
global with sharing class RefreshStoreReviewSummariesAction {
  @TestVisible
  private static ReviewService reviewService = new ReviewService();

  /**
   * Triggers a job to refresh customer review summaries for all storefronts
   * @param inputs List of Input parameters
   * @return List of Output results
   */
  @InvocableMethod(
    label='Refresh Store Review Summaries'
    description='Triggers a job to refresh customer review summaries for all storefronts'
    category='Customer Reviews Management'
  )
  global static List<Output> refreshStoreReviewSummaries(List<Input> inputs) {
    List<Output> responses = new List<Output>();
    for (Input request : inputs) {
      Output response = new Output();
      try {
        reviewService.refreshStoreReviewSummaries(request.forceRefresh);
        response.isSuccess = true;
        response.message = 'Store review summaries refresh job has been started successfully.';
      } catch (Exception e) {
        response.isSuccess = false;
        response.message = 'Error starting store review summaries refresh job: ' + e.getMessage();
      }
      responses.add(response);
    }
    return responses;
  }

  /**
   * Input parameters for the invocable action
   */
  global class Input {
    @InvocableVariable(
      label='Force Refresh'
      description='Whether to force refresh even if summaries already exist'
      required=false
    )
    public Boolean forceRefresh = false;
  }

  /**
   * Response from the invocable action
   */
  global class Output {
    @InvocableVariable(label='Success' description='Whether the operation was successful')
    public Boolean isSuccess;

    @InvocableVariable(label='Message' description='Success or error message')
    public String message;
  }
}
