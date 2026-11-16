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
    Storefront__c baseStorefront = new Storefront__c(
      Id = TestDataFactory.getFakeId(Storefront__c.SObjectType),
      Name = 'Test Storefront',
      Description__c = 'A test storefront',
      Cuisine__c = 'Italian',
      Status__c = 'Active',
      Address__Street__s = '1 Main St',
      Address__City__s = 'Dallas',
      Address__StateCode__s = 'TX',
      Phone__c = '(214) 555-0100'
    );
    // Formula and roll-up fields aren't writeable, so set them through JSON
    Map<String, Object> storefrontFields = (Map<String, Object>) JSON.deserializeUntyped(
      JSON.serialize(baseStorefront)
    );
    storefrontFields.put('Average_Review_Score__c', 4.4);
    storefrontFields.put('Total_Reviews__c', 8);
    Storefront__c mockStorefront = (Storefront__c) JSON.deserialize(
      JSON.serialize(storefrontFields),
      Storefront__c.class
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

    GetStorefrontFromNameAction.StorefrontDetails details = output.storefrontDetails;
    Assert.isNotNull(details, 'Should return display-ready storefront details');
    Assert.areEqual('Test Storefront', details.name);
    Assert.areEqual('A test storefront', details.description);
    Assert.areEqual('Italian', details.cuisine);
    Assert.areEqual('Active', details.status);
    Assert.areEqual('success', details.statusVariant);
    Assert.areEqual('4.4 (8 reviews)', details.ratingLabel);
    Assert.areEqual('1 Main St, Dallas, TX', details.address);
    Assert.areEqual('(214) 555-0100', details.phone);
  }

  @IsTest
  static void testGetStatusVariant() {
    Assert.areEqual('success', GetStorefrontFromNameAction.getStatusVariant('Active'));
    Assert.areEqual('warning', GetStorefrontFromNameAction.getStatusVariant('Pending Activation'));
    Assert.areEqual('error', GetStorefrontFromNameAction.getStatusVariant('Suspended'));
    Assert.areEqual('error', GetStorefrontFromNameAction.getStatusVariant('Closed'));
    Assert.areEqual('secondary', GetStorefrontFromNameAction.getStatusVariant('Inactive'));
    Assert.areEqual('secondary', GetStorefrontFromNameAction.getStatusVariant(null));
  }

  @IsTest
  static void testGetRatingLabel() {
    Assert.areEqual('No reviews yet', GetStorefrontFromNameAction.getRatingLabel(null, null));
    Assert.areEqual('No reviews yet', GetStorefrontFromNameAction.getRatingLabel(4, 0));
    Assert.areEqual('5.0 (1 review)', GetStorefrontFromNameAction.getRatingLabel(5, 1));
  }

  @IsTest
  static void testGetAddressLabel_SkipsBlankParts() {
    Storefront__c storefront = new Storefront__c(Address__City__s = 'Dallas', Address__StateCode__s = 'TX');
    Assert.areEqual('Dallas, TX', GetStorefrontFromNameAction.getAddressLabel(storefront));
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
    Assert.isNull(output.storefrontDetails, 'Should not return storefront details on failure');
  }
}
