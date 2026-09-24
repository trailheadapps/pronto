@IsTest
private class GetStorefrontHoursActionTest {
  private class MockStorefrontService extends StorefrontService {
    private List<Storefront_Hours_of_Operation__c> hoursToReturn;
    private Boolean shouldThrowException = false;
    private String exceptionMessage;

    /**
     * Creates a mock that returns the given storefront hours.
     * @param hours Storefront hours to return from getStorefrontHours
     */
    public MockStorefrontService(List<Storefront_Hours_of_Operation__c> hours) {
      this.hoursToReturn = hours;
    }

    /**
     * Creates a mock that throws a StorefrontException.
     * @param exceptionMessage Message of the StorefrontException to throw from getStorefrontHours
     */
    public MockStorefrontService(String exceptionMessage) {
      this.shouldThrowException = true;
      this.exceptionMessage = exceptionMessage;
    }

    public override List<Storefront_Hours_of_Operation__c> getStorefrontHours(Id storefrontId) {
      if (shouldThrowException) {
        throw new StorefrontException(exceptionMessage);
      }
      return hoursToReturn;
    }
  }

  @IsTest
  static void testGetStorefrontHours_Success() {
    Id testStorefrontId = TestDataFactory.getFakeId(Storefront__c.SObjectType);
    List<Storefront_Hours_of_Operation__c> mockHours = TestDataFactory.createMockHours(testStorefrontId, 5);

    MockStorefrontService mockService = new MockStorefrontService(mockHours);
    GetStorefrontHoursAction.storefrontService = mockService;

    GetStorefrontHoursAction.Input request = new GetStorefrontHoursAction.Input();
    request.storefrontId = testStorefrontId;

    Test.startTest();
    List<GetStorefrontHoursAction.Output> results = GetStorefrontHoursAction.getStorefrontHours(
      new List<GetStorefrontHoursAction.Input>{ request }
    );
    Test.stopTest();

    GetStorefrontHoursAction.Output response = results[0];
    System.assertEquals(true, response.isSuccess);
    System.assertEquals(5, response.hours.size());
  }

  @IsTest
  static void testGetStorefrontHours_Failure() {
    String errorMessage = 'Database query failed';
    MockStorefrontService mockService = new MockStorefrontService(errorMessage);
    GetStorefrontHoursAction.storefrontService = mockService;

    Id testStorefrontId = TestDataFactory.getFakeId(Storefront__c.SObjectType);
    GetStorefrontHoursAction.Input request = new GetStorefrontHoursAction.Input();
    request.storefrontId = testStorefrontId;

    Test.startTest();
    List<GetStorefrontHoursAction.Output> results = GetStorefrontHoursAction.getStorefrontHours(
      new List<GetStorefrontHoursAction.Input>{ request }
    );
    Test.stopTest();

    GetStorefrontHoursAction.Output response = results[0];
    System.assertEquals(false, response.isSuccess);
    System.assert(response.message.contains(errorMessage));
  }
}
