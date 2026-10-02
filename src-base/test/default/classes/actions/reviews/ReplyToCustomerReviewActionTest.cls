@IsTest
private class ReplyToCustomerReviewActionTest {
  private class MockReviewService extends ReviewService {
    public Boolean shouldThrowException = false;
    public String exceptionMessage = 'Test exception';
    public Review__c reviewToReturn;

    public override Review__c replyToReview(Id reviewId, String responseText) {
      if (shouldThrowException) {
        throw new ReviewException(exceptionMessage);
      }
      return reviewToReturn;
    }
  }

  @IsTest
  static void testReplyToCustomerReview_Success() {
    Id reviewId = TestDataFactory.getFakeId(Review__c.SObjectType);
    MockReviewService mockService = new MockReviewService();
    mockService.reviewToReturn = new Review__c(Id = reviewId);
    ReplyToCustomerReviewAction.reviewService = mockService;

    ReplyToCustomerReviewAction.Input input = new ReplyToCustomerReviewAction.Input();
    input.reviewId = reviewId;
    input.responseText = 'Thank you for your feedback!';

    Test.startTest();
    List<ReplyToCustomerReviewAction.Output> results = ReplyToCustomerReviewAction.replyToCustomerReview(
      new List<ReplyToCustomerReviewAction.Input>{ input }
    );
    Test.stopTest();

    System.assertEquals(1, results.size());
    ReplyToCustomerReviewAction.Output result = results[0];
    System.assertEquals(true, result.isSuccess);
    System.assertEquals(reviewId, result.reviewId);
    System.assertEquals('Reply posted to review ' + mockService.reviewToReturn.Name, result.message);
  }

  @IsTest
  static void testReplyToCustomerReview_Failure() {
    MockReviewService mockService = new MockReviewService();
    mockService.shouldThrowException = true;
    mockService.exceptionMessage = 'No review found with ID: ' + TestDataFactory.getFakeId(Review__c.SObjectType);
    ReplyToCustomerReviewAction.reviewService = mockService;

    ReplyToCustomerReviewAction.Input input = new ReplyToCustomerReviewAction.Input();
    input.reviewId = TestDataFactory.getFakeId(Review__c.SObjectType);
    input.responseText = 'Thank you for your feedback!';

    Test.startTest();
    List<ReplyToCustomerReviewAction.Output> results = ReplyToCustomerReviewAction.replyToCustomerReview(
      new List<ReplyToCustomerReviewAction.Input>{ input }
    );
    Test.stopTest();

    System.assertEquals(1, results.size());
    ReplyToCustomerReviewAction.Output result = results[0];
    System.assertEquals(false, result.isSuccess);
    System.assertEquals(null, result.reviewId);
    System.assert(result.message.contains('Error replying to customer review'));
  }
}
