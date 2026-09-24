@IsTest
private class AddItemToOrderActionTest {
  private class MockOrderService extends OrderService {
    public Boolean shouldThrowException = false;
    public String exceptionMessage = 'Test exception';
    public Boolean shouldDenyAccess = false;
    public Order_Item__c mockOrderItem;

    public override void assertCustomerHasAccessToOrder(Id customerId, Id orderId) {
      if (shouldDenyAccess) {
        throw new OrderException('You do not have access to this order');
      }
    }

    public override Order_Item__c addItemToOrder(Id orderId, String orderItemName, Decimal quantity) {
      if (shouldThrowException) {
        throw new OrderException(exceptionMessage);
      }
      return mockOrderItem;
    }
  }

  @IsTest
  static void testAddToOrder_Success() {
    MockOrderService mockService = new MockOrderService();
    Order_Item__c mockOrderItem = new Order_Item__c(
      Id = TestDataFactory.getFakeId(Order_Item__c.SObjectType),
      Quantity__c = 2
    );
    mockService.mockOrderItem = mockOrderItem;
    AddItemToOrderAction.orderService = mockService;

    AddItemToOrderAction.Input input = new AddItemToOrderAction.Input();
    input.customerId = TestDataFactory.getFakeId(Contact.SObjectType);
    input.orderId = TestDataFactory.getFakeId(Order__c.SObjectType);
    input.orderItemName = 'Pepperoni Pizza';
    input.quantity = 2;

    Test.startTest();
    List<AddItemToOrderAction.Output> results = AddItemToOrderAction.addToOrder(
      new List<AddItemToOrderAction.Input>{ input }
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Should return one output');
    AddItemToOrderAction.Output output = results[0];
    System.assertEquals(true, output.isSuccess, 'Should be successful');
    System.assertEquals(input.orderId, output.orderId, 'Should return correct order ID');
    System.assert(output.message.contains('Added'), 'Should contain success message');
  }

  @IsTest
  static void testAddToOrder_Failure() {
    MockOrderService mockService = new MockOrderService();
    mockService.shouldThrowException = true;
    mockService.exceptionMessage = 'Order not found';
    AddItemToOrderAction.orderService = mockService;

    AddItemToOrderAction.Input input = new AddItemToOrderAction.Input();
    input.customerId = TestDataFactory.getFakeId(Contact.SObjectType);
    input.orderId = TestDataFactory.getFakeId(Order__c.SObjectType);
    input.orderItemName = 'Pizza';
    input.quantity = 1;

    Test.startTest();
    List<AddItemToOrderAction.Output> results = AddItemToOrderAction.addToOrder(
      new List<AddItemToOrderAction.Input>{ input }
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Should return one output');
    AddItemToOrderAction.Output output = results[0];
    System.assertEquals(false, output.isSuccess, 'Should not be successful');
    System.assertEquals('Order not found', output.message, 'Should contain error message');
  }

  @IsTest
  static void testAddToOrder_FailsWhenNoAccess() {
    MockOrderService mockService = new MockOrderService();
    mockService.shouldDenyAccess = true;
    AddItemToOrderAction.orderService = mockService;

    AddItemToOrderAction.Input input = new AddItemToOrderAction.Input();
    input.customerId = TestDataFactory.getFakeId(Contact.SObjectType);
    input.orderId = TestDataFactory.getFakeId(Order__c.SObjectType);
    input.orderItemName = 'Pizza';
    input.quantity = 1;

    Test.startTest();
    List<AddItemToOrderAction.Output> results = AddItemToOrderAction.addToOrder(
      new List<AddItemToOrderAction.Input>{ input }
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Should return one output');
    AddItemToOrderAction.Output output = results[0];
    System.assertEquals(false, output.isSuccess, 'Should not be successful when customer lacks access');
    System.assertEquals('You do not have access to this order', output.message, 'Should contain access denied message');
  }
}
