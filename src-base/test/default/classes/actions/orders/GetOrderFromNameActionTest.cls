@IsTest
private class GetOrderFromNameActionTest {
  private class MockOrderService extends OrderService {
    public Boolean shouldThrowException = false;
    public String exceptionMessage = '';
    public Boolean shouldDenyAccess = false;
    public Order__c orderToReturn;

    public override void assertCustomerHasAccessToOrder(Id customerId, Id orderId) {
      if (shouldDenyAccess) {
        throw new OrderService.OrderException('You do not have access to this order');
      }
    }

    public override Order__c getOrderFromName(String orderName) {
      if (shouldThrowException) {
        throw new OrderException(exceptionMessage);
      }
      return orderToReturn;
    }
  }

  @IsTest
  static void testGetOrderFromName_Success() {
    Order__c testOrder = new Order__c(Status__c = 'Confirmed', Total_Amount__c = 45.50);

    MockOrderService mockService = new MockOrderService();
    mockService.orderToReturn = testOrder;
    GetOrderFromNameAction.orderService = mockService;

    GetOrderFromNameAction.Input input = new GetOrderFromNameAction.Input();
    input.orderName = 'ORD-12345';
    List<GetOrderFromNameAction.Input> inputs = new List<GetOrderFromNameAction.Input>{ input };

    Test.startTest();
    List<GetOrderFromNameAction.Output> outputs = GetOrderFromNameAction.getOrderFromName(inputs);
    Test.stopTest();

    System.assertEquals(1, outputs.size());
    System.assertNotEquals(null, outputs[0].order);
  }

  @IsTest
  static void testGetOrderFromName_FailsWhenOrderNotFound() {
    MockOrderService mockService = new MockOrderService();
    mockService.shouldThrowException = true;
    mockService.exceptionMessage = 'No order found with number: ORD-INVALID';
    GetOrderFromNameAction.orderService = mockService;

    GetOrderFromNameAction.Input input = new GetOrderFromNameAction.Input();
    input.orderName = 'ORD-INVALID';
    List<GetOrderFromNameAction.Input> inputs = new List<GetOrderFromNameAction.Input>{ input };

    Test.startTest();
    List<GetOrderFromNameAction.Output> outputs = GetOrderFromNameAction.getOrderFromName(inputs);
    Test.stopTest();

    System.assertEquals(1, outputs.size(), 'Expected one output result');
    GetOrderFromNameAction.Output output = outputs[0];
    System.assertEquals(false, output.success, 'Expected success to be false when order is not found');
    System.assertEquals('No order found with number: ORD-INVALID', output.message, 'Expected not-found message');
  }

  @IsTest
  static void testGetOrderFromName_FailsWhenNoAccess() {
    Order__c testOrder = new Order__c(Status__c = 'Confirmed', Total_Amount__c = 45.50);

    MockOrderService mockService = new MockOrderService();
    mockService.orderToReturn = testOrder;
    mockService.shouldDenyAccess = true;
    GetOrderFromNameAction.orderService = mockService;

    GetOrderFromNameAction.Input input = new GetOrderFromNameAction.Input();
    input.customerId = TestDataFactory.getFakeId(Contact.SObjectType);
    input.orderName = 'SOME_ORDER_NAME';
    List<GetOrderFromNameAction.Input> inputs = new List<GetOrderFromNameAction.Input>{ input };

    Test.startTest();
    List<GetOrderFromNameAction.Output> outputs = GetOrderFromNameAction.getOrderFromName(inputs);
    Test.stopTest();

    System.assertEquals(1, outputs.size(), 'Expected one output result');
    GetOrderFromNameAction.Output output = outputs[0];
    System.assertEquals(false, output.success, 'Expected success to be false when customer lacks access');
    System.assertEquals('You do not have access to this order', output.message, 'Expected access denied message');
  }
}
