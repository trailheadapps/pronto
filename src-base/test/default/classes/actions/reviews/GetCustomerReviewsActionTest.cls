@IsTest
private class GetCustomerReviewsActionTest {
  private class MockReviewService extends ReviewService {
    public Boolean shouldThrowException = false;
    public String exceptionMessage = 'Test exception';
    public List<Review__c> reviewsToReturn = new List<Review__c>();

    public override List<Review__c> getReviewsForStorefront(Id storefrontId) {
      if (shouldThrowException) {
        throw new ReviewException(exceptionMessage);
      }
      return reviewsToReturn;
    }
  }

  @IsTest
  static void testGetCustomerReviews_Success() {
    MockReviewService mockService = new MockReviewService();
    mockService.reviewsToReturn = TestDataFactory.createMockReviews(3);
    GetCustomerReviewsAction.reviewService = mockService;

    GetCustomerReviewsAction.Input input = new GetCustomerReviewsAction.Input();
    input.storefrontId = TestDataFactory.getFakeId(Storefront__c.SObjectType);

    Test.startTest();
    List<GetCustomerReviewsAction.Output> results = GetCustomerReviewsAction.getCustomerReviews(
      new List<GetCustomerReviewsAction.Input>{ input }
    );
    Test.stopTest();

    System.assertEquals(1, results.size());
    GetCustomerReviewsAction.Output result = results[0];
    System.assertEquals(true, result.isSuccess);
    System.assertEquals(3, result.reviews.reviewCount);
    System.assertEquals(3, result.reviews.items.size());
  }

  @IsTest
  static void testGetCustomerReviews_Failure() {
    MockReviewService mockService = new MockReviewService();
    mockService.shouldThrowException = true;
    mockService.exceptionMessage = 'Storefront ID is required';
    GetCustomerReviewsAction.reviewService = mockService;

    GetCustomerReviewsAction.Input input = new GetCustomerReviewsAction.Input();
    input.storefrontId = TestDataFactory.getFakeId(Storefront__c.SObjectType);

    Test.startTest();
    List<GetCustomerReviewsAction.Output> results = GetCustomerReviewsAction.getCustomerReviews(
      new List<GetCustomerReviewsAction.Input>{ input }
    );
    Test.stopTest();

    System.assertEquals(1, results.size());
    GetCustomerReviewsAction.Output result = results[0];
    System.assertEquals(false, result.isSuccess);
    System.assertEquals(null, result.reviews);
    System.assert(result.message.contains('Error retrieving customer reviews'));
  }
}
