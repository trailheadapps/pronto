@IsTest
private class GetStorefrontsActionTest {
  private class MockStorefrontService extends StorefrontService {
    public Boolean shouldThrowException = false;
    public String exceptionMessage = 'Mock exception';

    public override List<Storefront__c> getStorefronts(Integer recordLimit) {
      if (shouldThrowException) {
        throw new StorefrontException(exceptionMessage);
      }
      return TestDataFactory.createMockStorefronts(10);
    }
  }

  @IsTest
  static void testGetStorefronts_Success() {
    MockStorefrontService mockService = new MockStorefrontService();
    GetStorefrontsAction.storefrontService = mockService;

    GetStorefrontsAction.Input request = new GetStorefrontsAction.Input();
    request.recordLimit = 10;

    Test.startTest();
    List<GetStorefrontsAction.Output> results = GetStorefrontsAction.getStorefronts(
      new List<GetStorefrontsAction.Input>{ request }
    );
    Test.stopTest();

    System.assertEquals(1, results.size());
    GetStorefrontsAction.Output result = results[0];
    System.assertEquals(true, result.isSuccess);
    System.assertEquals(10, result.storefronts.size());
    System.assertEquals('Found 10 storefronts.', result.message);
  }

  @IsTest
  static void testGetStorefronts_Failure() {
    MockStorefrontService mockService = new MockStorefrontService();
    mockService.shouldThrowException = true;
    mockService.exceptionMessage = 'Database connection failed';
    GetStorefrontsAction.storefrontService = mockService;

    GetStorefrontsAction.Input request = new GetStorefrontsAction.Input();
    request.recordLimit = 10;

    Test.startTest();
    List<GetStorefrontsAction.Output> results = GetStorefrontsAction.getStorefronts(
      new List<GetStorefrontsAction.Input>{ request }
    );
    Test.stopTest();

    System.assertEquals(1, results.size());
    GetStorefrontsAction.Output result = results[0];
    System.assertEquals(false, result.isSuccess);
    System.assertEquals(null, result.storefronts);
    System.assert(result.message.contains('Error retrieving storefronts'));
    System.assert(result.message.contains('Database connection failed'));
  }
}
