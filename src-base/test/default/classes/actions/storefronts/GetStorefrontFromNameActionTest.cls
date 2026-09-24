@IsTest
private class GetStorefrontFromNameActionTest {
  private class MockStorefrontService extends StorefrontService {
    public Boolean shouldThrowException = false;
    public String exceptionMessage;
    public Storefront__c mockStorefront;

    public override Storefront__c getStorefrontFromName(String storefrontName) {
      if (shouldThrowException) {
        throw new StorefrontService.StorefrontException(exceptionMessage);
      }
      return mockStorefront;
    }
  }

  @IsTest
  static void testgetStorefrontFromName_Success() {
    Storefront__c mockStorefront = new Storefront__c(
      Id = TestDataFactory.getFakeId(Storefront__c.SObjectType),
      Name = 'Test Storefront',
      Description__c = 'A test storefront',
      Cuisine__c = 'Italian',
      Status__c = 'Open'
    );

    MockStorefrontService mockService = new MockStorefrontService();
    mockService.mockStorefront = mockStorefront;
    GetStorefrontFromNameAction.storefrontService = mockService;

    GetStorefrontFromNameAction.Input input = new GetStorefrontFromNameAction.Input();
    input.storefrontName = 'Test Storefront';
    List<GetStorefrontFromNameAction.Input> inputs = new List<GetStorefrontFromNameAction.Input>{ input };

    Test.startTest();
    List<GetStorefrontFromNameAction.Output> outputs = GetStorefrontFromNameAction.getStorefrontFromName(inputs);
    Test.stopTest();

    System.assertEquals(1, outputs.size());
    GetStorefrontFromNameAction.Output output = outputs[0];
    System.assertEquals(true, output.isSuccess);
    System.assertEquals('Storefront retrieved successfully', output.message);
    System.assertNotEquals(null, output.storefront);
    System.assertEquals('Test Storefront', output.storefront.Name);
  }

  @IsTest
  static void testgetStorefrontFromName_Failure() {
    MockStorefrontService mockService = new MockStorefrontService();
    mockService.shouldThrowException = true;
    mockService.exceptionMessage = 'No storefront found with name: NonExistent';
    GetStorefrontFromNameAction.storefrontService = mockService;

    GetStorefrontFromNameAction.Input input = new GetStorefrontFromNameAction.Input();
    input.storefrontName = 'NonExistent';
    List<GetStorefrontFromNameAction.Input> inputs = new List<GetStorefrontFromNameAction.Input>{ input };

    Test.startTest();
    List<GetStorefrontFromNameAction.Output> outputs = GetStorefrontFromNameAction.getStorefrontFromName(inputs);
    Test.stopTest();

    System.assertEquals(1, outputs.size());
    GetStorefrontFromNameAction.Output output = outputs[0];
    System.assertEquals(false, output.isSuccess);
    System.assertEquals('No storefront found with name: NonExistent', output.message);
    System.assertEquals(null, output.storefront);
  }
}
