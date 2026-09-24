@IsTest
private class RefreshStoreReviewSummariesActionTest {
  private class MockReviewService extends ReviewService {
    public Boolean shouldThrowException = false;
    public String exceptionMessage = 'Test exception';

    public override void refreshStoreReviewSummaries(Boolean forceRefresh) {
      if (shouldThrowException) {
        throw new ReviewException(exceptionMessage);
      }
    }
  }

  @IsTest
  static void testRefreshStoreReviewSummaries_Success() {
    MockReviewService mockService = new MockReviewService();
    RefreshStoreReviewSummariesAction.reviewService = mockService;

    RefreshStoreReviewSummariesAction.Input request = new RefreshStoreReviewSummariesAction.Input();
    request.forceRefresh = true;

    Test.startTest();
    List<RefreshStoreReviewSummariesAction.Output> results = RefreshStoreReviewSummariesAction.refreshStoreReviewSummaries(
      new List<RefreshStoreReviewSummariesAction.Input>{ request }
    );
    Test.stopTest();

    Assert.areEqual(1, results.size());
    Assert.isTrue(results[0].isSuccess);
    Assert.areEqual('Store review summaries refresh job has been started successfully.', results[0].message);
  }

  @IsTest
  static void testRefreshStoreReviewSummaries_Failure() {
    MockReviewService mockService = new MockReviewService();
    mockService.shouldThrowException = true;
    mockService.exceptionMessage = 'Job failed';
    RefreshStoreReviewSummariesAction.reviewService = mockService;

    RefreshStoreReviewSummariesAction.Input request = new RefreshStoreReviewSummariesAction.Input();
    request.forceRefresh = true;

    Test.startTest();
    List<RefreshStoreReviewSummariesAction.Output> results = RefreshStoreReviewSummariesAction.refreshStoreReviewSummaries(
      new List<RefreshStoreReviewSummariesAction.Input>{ request }
    );
    Test.stopTest();

    Assert.areEqual(1, results.size());
    Assert.isFalse(results[0].isSuccess);
    Assert.isTrue(results[0].message.contains('Error starting store review summaries refresh job'));
  }
}
