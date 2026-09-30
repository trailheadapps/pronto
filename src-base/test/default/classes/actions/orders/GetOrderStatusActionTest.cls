@IsTest
private class GetOrderStatusActionTest {
  private class MockOrderService extends OrderService {
    public Order__c mockOrder;
    public List<Order_Item__c> mockOrderItems;
    public Boolean shouldThrowException = false;
    public String exceptionMessage;
    public Boolean shouldDenyAccess = false;

    public override void assertCustomerHasAccessToOrder(Id customerId, Id orderId) {
      if (shouldDenyAccess) {
        throw new OrderService.OrderException('You do not have access to this order');
      }
    }

    public override Order__c getOrderFromId(Id orderId) {
      if (shouldThrowException) {
        throw new OrderService.OrderException(exceptionMessage);
      }
      return mockOrder;
    }

    public override List<Order_Item__c> getOrderItems(Id orderId) {
      if (mockOrderItems != null) {
        return mockOrderItems;
      }
      return new List<Order_Item__c>();
    }
  }

  @IsTest
  static void testGetOrderStatus_Success() {
    MockOrderService mockService = new MockOrderService();

    Order__c mockOrder = new Order__c(
      Id = TestDataFactory.getFakeId(Order__c.SObjectType),
      Status__c = 'Confirmed',
      Total_Amount__c = 45.99
    );

    List<Order_Item__c> mockItems = new List<Order_Item__c>{
      new Order_Item__c(Id = TestDataFactory.getFakeId(Order_Item__c.SObjectType), Quantity__c = 2)
    };

    mockService.mockOrder = mockOrder;
    mockService.mockOrderItems = mockItems;
    GetOrderStatusAction.orderService = mockService;

    GetOrderStatusAction.Input input = new GetOrderStatusAction.Input();
    input.customerId = TestDataFactory.getFakeId(Contact.SObjectType);
    input.orderId = mockOrder.Id;
    List<GetOrderStatusAction.Input> inputs = new List<GetOrderStatusAction.Input>{ input };

    Test.startTest();
    List<GetOrderStatusAction.Output> outputs = GetOrderStatusAction.getOrderStatus(inputs);
    Test.stopTest();

    System.assertEquals(1, outputs.size());
    System.assertNotEquals(null, outputs[0].orderStatus);
    System.assertEquals(
      URL.getOrgDomainUrl().toExternalForm() + '/lightning/r/Order__c/' + mockOrder.Id + '/view',
      outputs[0].orderStatus.orderRecordLink
    );
    System.assertEquals(1, outputs[0].orderStatus.items.size());
    System.assertEquals(mockItems[0].Id, outputs[0].orderStatus.items[0].id);
    System.assertEquals(2, outputs[0].orderStatus.items[0].quantity);
  }

  @IsTest
  static void testGetOrderStatus_Failure() {
    MockOrderService mockService = new MockOrderService();
    mockService.shouldThrowException = true;
    mockService.exceptionMessage = 'No order found with ID: 001000000000000AAA';
    GetOrderStatusAction.orderService = mockService;

    GetOrderStatusAction.Input input = new GetOrderStatusAction.Input();
    input.customerId = TestDataFactory.getFakeId(Contact.SObjectType);
    input.orderId = TestDataFactory.getFakeId(Order__c.SObjectType);
    List<GetOrderStatusAction.Input> inputs = new List<GetOrderStatusAction.Input>{ input };

    Test.startTest();
    try {
      GetOrderStatusAction.getOrderStatus(inputs);
      System.assert(false, 'Expected OrderException to be thrown');
    } catch (OrderService.OrderException e) {
      System.assert(e.getMessage().contains('No order found with ID'));
    }
    Test.stopTest();
  }

  @IsTest
  static void testGetOrderStatus_FailsWhenNoAccess() {
    MockOrderService mockService = new MockOrderService();
    mockService.shouldDenyAccess = true;
    GetOrderStatusAction.orderService = mockService;

    GetOrderStatusAction.Input input = new GetOrderStatusAction.Input();
    input.customerId = TestDataFactory.getFakeId(Contact.SObjectType);
    input.orderId = TestDataFactory.getFakeId(Order__c.SObjectType);
    List<GetOrderStatusAction.Input> inputs = new List<GetOrderStatusAction.Input>{ input };

    Test.startTest();
    try {
      GetOrderStatusAction.getOrderStatus(inputs);
      System.assert(false, 'Expected OrderException to be thrown');
    } catch (OrderService.OrderException e) {
      System.assertEquals('You do not have access to this order', e.getMessage());
    }
    Test.stopTest();
  }
}
