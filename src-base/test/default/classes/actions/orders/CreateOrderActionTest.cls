@IsTest
private class CreateOrderActionTest {
  private class MockOrderService extends OrderService {
    public Boolean shouldThrowException = false;
    public String exceptionMessage = 'Test exception';
    public Order__c mockOrder;

    public override Order__c createDraftOrder(Id customerId, Id storefrontId) {
      if (shouldThrowException) {
        throw new OrderService.OrderException(exceptionMessage);
      }
      return mockOrder;
    }
  }

  @IsTest
  static void testCreateOrder_Success() {
    MockOrderService mockService = new MockOrderService();
    Order__c testOrder = new Order__c(Id = TestDataFactory.getFakeId(Order__c.SObjectType));
    mockService.mockOrder = testOrder;
    CreateOrderAction.orderService = mockService;

    CreateOrderAction.Input input = new CreateOrderAction.Input();
    input.customerId = TestDataFactory.getFakeId(Contact.SObjectType);
    input.storefrontId = TestDataFactory.getFakeId(Storefront__c.getSObjectType());

    Test.startTest();
    List<CreateOrderAction.Output> results = CreateOrderAction.createOrder(new List<CreateOrderAction.Input>{ input });
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Should return one result');
    CreateOrderAction.Output result = results[0];
    System.assertEquals(true, result.isSuccess, 'Should be successful');
    System.assertEquals(testOrder.Id, result.orderId, 'Should return the correct order ID');
    System.assert(result.message.contains('created successfully'), 'Message should indicate success');
  }

  @IsTest
  static void testCreateOrder_Failure() {
    MockOrderService mockService = new MockOrderService();
    mockService.shouldThrowException = true;
    mockService.exceptionMessage = 'Customer not found';
    CreateOrderAction.orderService = mockService;

    CreateOrderAction.Input input = new CreateOrderAction.Input();
    input.customerId = TestDataFactory.getFakeId(Contact.SObjectType);
    input.storefrontId = TestDataFactory.getFakeId(Storefront__c.SObjectType);

    Test.startTest();
    List<CreateOrderAction.Output> results = CreateOrderAction.createOrder(new List<CreateOrderAction.Input>{ input });
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Should return one result');
    CreateOrderAction.Output result = results[0];
    System.assertEquals(false, result.isSuccess, 'Should not be successful');
    System.assertEquals(null, result.orderId, 'Order ID should be null on error');
    System.assert(result.message.contains('Customer not found'), 'Message should contain exception details');
  }
}
