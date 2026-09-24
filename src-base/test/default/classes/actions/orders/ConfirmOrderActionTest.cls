@IsTest
private class ConfirmOrderActionTest {
  private class MockOrderService extends OrderService {
    public Boolean shouldThrowException = false;
    public String exceptionMessage = '';
    public Boolean shouldDenyAccess = false;
    public Order__c mockOrder;

    public override void assertCustomerHasAccessToOrder(Id customerId, Id orderId) {
      if (shouldDenyAccess) {
        throw new OrderService.OrderException('You do not have access to this order');
      }
    }

    public override Order__c confirmOrder(Id orderId) {
      if (shouldThrowException) {
        throw new OrderService.OrderException(exceptionMessage);
      }
      return mockOrder;
    }
  }

  @IsTest
  static void testConfirmOrder_Success() {
    MockOrderService mockService = new MockOrderService();
    Order__c mockOrder = new Order__c(
      Id = TestDataFactory.getFakeId(Order__c.SObjectType),
      Status__c = 'Confirmed',
      Order_Time__c = System.now()
    );
    mockService.mockOrder = mockOrder;
    ConfirmOrderAction.orderService = mockService;

    ConfirmOrderAction.Input input = new ConfirmOrderAction.Input();
    input.customerId = TestDataFactory.getFakeId(Contact.SObjectType);
    input.orderId = mockOrder.Id;
    List<ConfirmOrderAction.Input> inputs = new List<ConfirmOrderAction.Input>{ input };

    Test.startTest();
    List<ConfirmOrderAction.Output> outputs = ConfirmOrderAction.confirmOrder(inputs);
    Test.stopTest();

    System.assertEquals(1, outputs.size(), 'Should return one output');
    System.assertEquals(true, outputs[0].success, 'Operation should be successful');
    System.assert(outputs[0].message.contains('has been confirmed'), 'Should return success message');
  }

  @IsTest
  static void testConfirmOrder_Failure() {
    MockOrderService mockService = new MockOrderService();
    mockService.shouldThrowException = true;
    mockService.exceptionMessage = 'Order not found';
    ConfirmOrderAction.orderService = mockService;

    ConfirmOrderAction.Input input = new ConfirmOrderAction.Input();
    input.customerId = TestDataFactory.getFakeId(Contact.SObjectType);
    input.orderId = TestDataFactory.getFakeId(Order__c.SObjectType);
    List<ConfirmOrderAction.Input> inputs = new List<ConfirmOrderAction.Input>{ input };

    Test.startTest();
    List<ConfirmOrderAction.Output> outputs = ConfirmOrderAction.confirmOrder(inputs);
    Test.stopTest();

    System.assertEquals(1, outputs.size(), 'Should return one output');
    System.assertEquals(false, outputs[0].success, 'Operation should fail');
    System.assertEquals('Order not found', outputs[0].message, 'Should return error message');
  }

  @IsTest
  static void testConfirmOrder_FailsWhenNoAccess() {
    MockOrderService mockService = new MockOrderService();
    mockService.shouldDenyAccess = true;
    ConfirmOrderAction.orderService = mockService;

    ConfirmOrderAction.Input input = new ConfirmOrderAction.Input();
    input.customerId = TestDataFactory.getFakeId(Contact.SObjectType);
    input.orderId = TestDataFactory.getFakeId(Order__c.SObjectType);
    List<ConfirmOrderAction.Input> inputs = new List<ConfirmOrderAction.Input>{ input };

    Test.startTest();
    List<ConfirmOrderAction.Output> outputs = ConfirmOrderAction.confirmOrder(inputs);
    Test.stopTest();

    System.assertEquals(1, outputs.size(), 'Should return one output');
    System.assertEquals(false, outputs[0].success, 'Operation should fail when customer lacks access');
    System.assertEquals(
      'You do not have access to this order',
      outputs[0].message,
      'Should return access denied message'
    );
  }
}
