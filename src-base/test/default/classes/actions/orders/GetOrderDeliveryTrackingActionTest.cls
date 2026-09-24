@IsTest
private class GetOrderDeliveryTrackingActionTest {
  private class MockOrderService extends OrderService {
    public Boolean shouldDenyAccess = false;

    public override void assertCustomerHasAccessToOrder(Id customerId, Id orderId) {
      if (shouldDenyAccess) {
        throw new OrderException('You do not have access to this order');
      }
    }
  }

  @IsTest
  static void testGetDeliveryTracking_Success() {
    GetOrderDeliveryTrackingAction.orderService = new MockOrderService();

    String testOrderId = TestDataFactory.getFakeId(Order.SObjectType);
    GetOrderDeliveryTrackingAction.Input input = new GetOrderDeliveryTrackingAction.Input();
    input.customerId = TestDataFactory.getFakeId(Contact.SObjectType);
    input.orderId = testOrderId;
    List<GetOrderDeliveryTrackingAction.Input> inputs = new List<GetOrderDeliveryTrackingAction.Input>{ input };

    Test.startTest();
    List<GetOrderDeliveryTrackingAction.Output> outputs = GetOrderDeliveryTrackingAction.getDeliveryTracking(inputs);
    Test.stopTest();

    System.assertEquals(1, outputs.size());
    GetOrderDeliveryTrackingAction.Output output = outputs[0];
    System.assertNotEquals(null, output.deliveryTracking);
    System.assertEquals(testOrderId, output.deliveryTracking.orderId);
    System.assertEquals('In Progress', output.deliveryTracking.status);
    System.assertEquals(3, output.deliveryTracking.mapMarkers.size());
  }

  @IsTest
  static void testGetDeliveryTracking_Failure() {
    GetOrderDeliveryTrackingAction.orderService = new MockOrderService();

    GetOrderDeliveryTrackingAction.Input input = new GetOrderDeliveryTrackingAction.Input();
    input.customerId = TestDataFactory.getFakeId(Contact.SObjectType);
    input.orderId = null;
    List<GetOrderDeliveryTrackingAction.Input> inputs = new List<GetOrderDeliveryTrackingAction.Input>{ input };

    Test.startTest();
    List<GetOrderDeliveryTrackingAction.Output> outputs = GetOrderDeliveryTrackingAction.getDeliveryTracking(inputs);
    Test.stopTest();

    System.assertEquals(1, outputs.size());
    GetOrderDeliveryTrackingAction.Output output = outputs[0];
    System.assertNotEquals(null, output.deliveryTracking);
    System.assertEquals(null, output.deliveryTracking.orderId);
  }

  @IsTest
  static void testGetDeliveryTracking_FailsWhenNoAccess() {
    MockOrderService mockService = new MockOrderService();
    mockService.shouldDenyAccess = true;
    GetOrderDeliveryTrackingAction.orderService = mockService;

    GetOrderDeliveryTrackingAction.Input input = new GetOrderDeliveryTrackingAction.Input();
    input.customerId = TestDataFactory.getFakeId(Contact.SObjectType);
    input.orderId = TestDataFactory.getFakeId(Order__c.SObjectType);
    List<GetOrderDeliveryTrackingAction.Input> inputs = new List<GetOrderDeliveryTrackingAction.Input>{ input };

    Test.startTest();
    try {
      GetOrderDeliveryTrackingAction.getDeliveryTracking(inputs);
      System.assert(false, 'Expected OrderException to be thrown');
    } catch (OrderService.OrderException e) {
      System.assertEquals('You do not have access to this order', e.getMessage());
    }
    Test.stopTest();
  }
}
