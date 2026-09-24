@IsTest
private class GetMenuItemsActionTest {
  private class MockStorefrontService extends StorefrontService {
    private List<Menu_Item__c> menuItemsToReturn;
    private Boolean shouldThrowException = false;
    private String exceptionMessage;

    /**
     * Creates a mock that returns the given menu items.
     * @param menuItems Menu items to return from getMenuItems
     */
    public MockStorefrontService(List<Menu_Item__c> menuItems) {
      this.menuItemsToReturn = menuItems;
    }

    /**
     * Creates a mock that throws a StorefrontException.
     * @param exceptionMessage Message of the StorefrontException to throw from getMenuItems
     */
    public MockStorefrontService(String exceptionMessage) {
      this.shouldThrowException = true;
      this.exceptionMessage = exceptionMessage;
    }

    public override List<Menu_Item__c> getMenuItems(Id storefrontId) {
      if (shouldThrowException) {
        throw new StorefrontException(exceptionMessage);
      }
      return menuItemsToReturn;
    }
  }

  @IsTest
  static void testGetMenuItems_Success() {
    Id testStorefrontId = TestDataFactory.getFakeId(Storefront__c.SObjectType);
    Id fakeMenuId = TestDataFactory.getFakeId(Menu__c.SObjectType);
    List<Menu_Item__c> mockItems = TestDataFactory.createMenuItems(fakeMenuId, 3, false);

    MockStorefrontService mockService = new MockStorefrontService(mockItems);
    GetMenuItemsAction.storefrontService = mockService;

    GetMenuItemsAction.Input request = new GetMenuItemsAction.Input();
    request.storefrontId = testStorefrontId;

    Test.startTest();
    List<GetMenuItemsAction.Output> results = GetMenuItemsAction.getMenuItems(
      new List<GetMenuItemsAction.Input>{ request }
    );
    Test.stopTest();

    GetMenuItemsAction.Output response = results[0];
    Assert.areEqual(true, response.isSuccess, 'Should indicate success');
    Assert.areEqual(3, response.menuItems.size(), 'Should return the mocked menu items');
  }

  @IsTest
  static void testGetMenuItems_NoItems() {
    Id testStorefrontId = TestDataFactory.getFakeId(Storefront__c.SObjectType);
    MockStorefrontService mockService = new MockStorefrontService(new List<Menu_Item__c>());
    GetMenuItemsAction.storefrontService = mockService;

    GetMenuItemsAction.Input request = new GetMenuItemsAction.Input();
    request.storefrontId = testStorefrontId;

    Test.startTest();
    List<GetMenuItemsAction.Output> results = GetMenuItemsAction.getMenuItems(
      new List<GetMenuItemsAction.Input>{ request }
    );
    Test.stopTest();

    GetMenuItemsAction.Output response = results[0];
    Assert.areEqual(false, response.isSuccess, 'Should indicate no items were found');
    Assert.areEqual(0, response.menuItems.size(), 'Should return an empty list');
  }

  @IsTest
  static void testGetMenuItems_Failure() {
    String errorMessage = 'Database query failed';
    MockStorefrontService mockService = new MockStorefrontService(errorMessage);
    GetMenuItemsAction.storefrontService = mockService;

    Id testStorefrontId = TestDataFactory.getFakeId(Storefront__c.SObjectType);
    GetMenuItemsAction.Input request = new GetMenuItemsAction.Input();
    request.storefrontId = testStorefrontId;

    Test.startTest();
    List<GetMenuItemsAction.Output> results = GetMenuItemsAction.getMenuItems(
      new List<GetMenuItemsAction.Input>{ request }
    );
    Test.stopTest();

    GetMenuItemsAction.Output response = results[0];
    Assert.areEqual(false, response.isSuccess, 'Should indicate failure');
    Assert.isTrue(response.message.contains(errorMessage), 'Message should surface the underlying error');
  }
}
