@IsTest
private class GetOrdersFromCustomerActionTest {
  private class MockOrderService extends OrderService {
    public Boolean shouldThrowException = false;
    public String exceptionMessage = 'Mock exception';
    public List<Order__c> ordersToReturn = new List<Order__c>();

    public override List<Order__c> getOrdersFromCustomer(Id customerId, String orderStatus) {
      if (shouldThrowException) {
        throw new OrderService.OrderException(exceptionMessage);
      }
      return ordersToReturn;
    }
  }

  @IsTest
  static void testGetOrders_Success() {
    MockOrderService mockService = new MockOrderService();
    GetOrdersFromCustomerAction.orderService = mockService;

    Order__c order1 = new Order__c(Id = TestDataFactory.getFakeId(Order__c.SObjectType), Status__c = 'Delivered');
    Order__c order2 = new Order__c(Id = TestDataFactory.getFakeId(Order__c.SObjectType), Status__c = 'Delivered');
    mockService.ordersToReturn = new List<Order__c>{ order1, order2 };

    GetOrdersFromCustomerAction.Input input = new GetOrdersFromCustomerAction.Input();
    input.customerId = TestDataFactory.getFakeId(Contact.SObjectType);
    input.orderStatus = 'Delivered';

    Test.startTest();
    List<GetOrdersFromCustomerAction.Output> results = GetOrdersFromCustomerAction.getOrders(
      new List<GetOrdersFromCustomerAction.Input>{ input }
    );
    Test.stopTest();

    System.assertEquals(1, results.size());
    GetOrdersFromCustomerAction.Output output = results[0];
    System.assertEquals(true, output.isSuccess);
    System.assertEquals(2, output.orders.size());
  }

  @IsTest
  static void testGetOrders_Failure() {
    MockOrderService mockService = new MockOrderService();
    GetOrdersFromCustomerAction.orderService = mockService;
    mockService.shouldThrowException = true;
    mockService.exceptionMessage = 'Invalid status value';

    GetOrdersFromCustomerAction.Input input = new GetOrdersFromCustomerAction.Input();
    input.customerId = TestDataFactory.getFakeId(Contact.SObjectType);
    input.orderStatus = 'InvalidStatus';

    Test.startTest();
    List<GetOrdersFromCustomerAction.Output> results = GetOrdersFromCustomerAction.getOrders(
      new List<GetOrdersFromCustomerAction.Input>{ input }
    );
    Test.stopTest();

    System.assertEquals(1, results.size());
    GetOrdersFromCustomerAction.Output output = results[0];
    System.assertEquals(false, output.isSuccess);
    System.assert(output.message.contains('Invalid status value'));
  }
}
