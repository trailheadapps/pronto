/**
 * Invocable Action for posting a restaurant's reply to a customer review
 */
global with sharing class ReplyToCustomerReviewAction {
  @TestVisible
  private static ReviewService reviewService = new ReviewService();

  /**
   * Posts the restaurant's reply to a specific customer review
   * @param inputs List of request objects containing the review ID and reply text
   * @return List of response objects containing the result of the operation
   */
  @InvocableMethod(
    label='Reply To Customer Review'
    description='Posts the restaurant\'s reply to a specific customer review'
    category='Customer Reviews Management'
  )
  global static List<Output> replyToCustomerReview(List<Input> inputs) {
    List<Output> responses = new List<Output>();

    for (Input request : inputs) {
      Output response = new Output();
      try {
        Review__c review = reviewService.replyToReview(request.reviewId, request.responseText);
        response.isSuccess = true;
        response.message = 'Reply posted to review ' + review.Name;
        response.reviewId = review.Id;
      } catch (Exception e) {
        response.isSuccess = false;
        response.message = 'Error replying to customer review: ' + e.getMessage();
      }

      responses.add(response);
    }

    return responses;
  }

  /**
   * Input parameters for the invocable action
   */
  global class Input {
    @InvocableVariable(label='Review ID' description='The ID of the review to reply to' required=true)
    public String reviewId;

    @InvocableVariable(label='Response Text' description='The restaurant\'s reply text' required=true)
    public String responseText;
  }

  /**
   * Response from the invocable action
   */
  global class Output {
    @InvocableVariable(label='Success' description='Whether the operation was successful')
    public Boolean isSuccess;

    @InvocableVariable(label='Message' description='Success or error message')
    public String message;

    @InvocableVariable(label='Review ID' description='The ID of the review that was replied to')
    public String reviewId;
  }
}
