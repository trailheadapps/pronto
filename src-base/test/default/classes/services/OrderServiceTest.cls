/**
 * Test class for OrderService.
 */
@IsTest
private class OrderServiceTest {
  @TestSetup
  static void setupTestData() {
    Storefront__c storefront = TestDataFactory.createStorefronts(1, true)[0];
    Contact customer = TestDataFactory.createCustomers(1, true)[0];
    Menu__c menu = TestDataFactory.createMenu(storefront.Id, true);
    TestDataFactory.createMenuItems(menu.Id, 3, true);
    TestDataFactory.createOrders(customer.Id, storefront.Id, 'Draft', 2, true);
  }

  @IsTest
  static void shouldGetOrderFromId_WhenOrderExists() {
    // Given
    OrderService service = new OrderService();
    Order__c order = [SELECT Id FROM Order__c LIMIT 1];

    // When
    Test.startTest();
    Order__c result = service.getOrderFromId(order.Id);
    Test.stopTest();

    // Then
    Assert.areEqual(order.Id, result.Id, 'Should return the correct order');
    Assert.isNotNull(result.Name, 'Should include order name');
    Assert.isNotNull(result.Status__c, 'Should include order status');
  }

  @IsTest
  static void shouldThrowException_WhenGetOrderFromIdNotFound() {
    // Given
    OrderService service = new OrderService();
    Id nonExistentId = TestDataFactory.getFakeId(Order__c.SObjectType);

    // When / Then
    Test.startTest();
    try {
      service.getOrderFromId(nonExistentId);
      Assert.fail('Should have thrown OrderException');
    } catch (OrderService.OrderException e) {
      Assert.isTrue(e.getMessage().contains('No order found'), 'Exception message should indicate order not found');
    }
    Test.stopTest();
  }

  @IsTest
  static void shouldGetOrderFromName_WhenOrderExists() {
    // Given
    OrderService service = new OrderService();
    Order__c order = [SELECT Id, Name FROM Order__c LIMIT 1];

    // When
    Test.startTest();
    Order__c result = service.getOrderFromName(order.Name);
    Test.stopTest();

    // Then
    Assert.areEqual(order.Id, result.Id, 'Should return the correct order');
    Assert.areEqual(order.Name, result.Name, 'Should match the order name');
  }

  @IsTest
  static void shouldThrowException_WhenGetOrderFromNameNotFound() {
    // Given
    OrderService service = new OrderService();
    String nonExistentName = 'ORD-999999';

    // When / Then
    Test.startTest();
    try {
      service.getOrderFromName(nonExistentName);
      Assert.fail('Should have thrown OrderException');
    } catch (OrderService.OrderException e) {
      Assert.isTrue(
        e.getMessage().contains('No order found with number'),
        'Exception message should indicate order not found'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void shouldCancelOrder_WhenOrderIsDraft() {
    // Given
    OrderService service = new OrderService();
    Order__c order = [SELECT Id FROM Order__c WHERE Status__c = 'Draft' LIMIT 1];
    String reason = 'Customer changed their mind';

    // When
    Test.startTest();
    Order__c result = service.cancelOrder(order.Id, reason);
    Test.stopTest();

    // Then
    Assert.areEqual('Canceled', result.Status__c, 'Order status should be Canceled');
    Assert.areEqual(reason, result.Cancelation_Reason__c, 'Cancelation reason should be stored');
    Order__c updated = [SELECT Status__c, Cancelation_Reason__c FROM Order__c WHERE Id = :order.Id];
    Assert.areEqual('Canceled', updated.Status__c, 'Order should be persisted as Canceled');
  }

  @IsTest
  static void shouldThrowException_WhenCancelOrderInvalidStatus() {
    // Given
    OrderService service = new OrderService();
    Order__c order = [SELECT Id FROM Order__c LIMIT 1];
    order.Status__c = 'Delivered';
    update order;

    // When / Then
    Test.startTest();
    try {
      service.cancelOrder(order.Id, 'Too late');
      Assert.fail('Should have thrown OrderException');
    } catch (OrderService.OrderException e) {
      Assert.isTrue(
        e.getMessage().contains('cannot be canceled'),
        'Exception should indicate order cannot be canceled'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void shouldConfirmOrder_WhenOrderIsDraft() {
    // Given
    OrderService service = new OrderService();
    Order__c order = [SELECT Id FROM Order__c WHERE Status__c = 'Draft' LIMIT 1];

    // When
    Test.startTest();
    Order__c result = service.confirmOrder(order.Id);
    Test.stopTest();

    // Then
    Assert.areEqual('Confirmed', result.Status__c, 'Order status should be Confirmed');
    Assert.isNotNull(result.Order_Time__c, 'Order time should be set');
    Order__c updated = [SELECT Status__c, Order_Time__c FROM Order__c WHERE Id = :order.Id];
    Assert.areEqual('Confirmed', updated.Status__c, 'Order should be persisted as Confirmed');
    Assert.isNotNull(updated.Order_Time__c, 'Order time should be persisted');
  }

  @IsTest
  static void shouldThrowException_WhenConfirmOrderNotDraft() {
    // Given
    OrderService service = new OrderService();
    Order__c order = [SELECT Id FROM Order__c LIMIT 1];
    order.Status__c = 'Confirmed';
    update order;

    // When / Then
    Test.startTest();
    try {
      service.confirmOrder(order.Id);
      Assert.fail('Should have thrown OrderException');
    } catch (OrderService.OrderException e) {
      Assert.isTrue(
        e.getMessage().contains('cannot be confirmed'),
        'Exception should indicate order cannot be confirmed'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void shouldCreateDraftOrder_WhenValidInput() {
    // Given
    OrderService service = new OrderService();
    Contact customer = [
      SELECT Id, MailingStreet, MailingCity, MailingStateCode, MailingPostalCode, MailingCountryCode
      FROM Contact
      LIMIT 1
    ];
    Storefront__c storefront = [SELECT Id FROM Storefront__c LIMIT 1];

    // When
    Test.startTest();
    Order__c result = service.createDraftOrder(customer.Id, storefront.Id);
    Test.stopTest();

    // Then
    Assert.isNotNull(result.Id, 'Order should be created');
    Assert.isNotNull(result.Name, 'Order name should be generated');
    Order__c created = [
      SELECT Status__c, Customer__c, Storefront__c, Delivery_Address__City__s
      FROM Order__c
      WHERE Id = :result.Id
    ];
    Assert.areEqual('Draft', created.Status__c, 'Order should be in Draft status');
    Assert.areEqual(customer.Id, created.Customer__c, 'Customer should be set');
    Assert.areEqual(storefront.Id, created.Storefront__c, 'Storefront should be set');
    Assert.areEqual(
      'San Francisco',
      created.Delivery_Address__City__s,
      'Delivery address should be copied from customer'
    );
  }

  @IsTest
  static void shouldAddItemToOrder_WhenOrderIsDraft() {
    // Given
    OrderService service = new OrderService();
    Order__c order = [SELECT Id FROM Order__c WHERE Status__c = 'Draft' LIMIT 1];
    Menu_Item__c menuItem = [SELECT Id, Name FROM Menu_Item__c LIMIT 1];

    // When
    Test.startTest();
    Order_Item__c result = service.addItemToOrder(order.Id, menuItem.Name, 2);
    Test.stopTest();

    // Then
    Assert.isNotNull(result.Id, 'Order item should be created');
    Assert.areEqual(order.Id, result.Order__c, 'Order item should reference the order');
    Assert.areEqual(menuItem.Id, result.Menu_Item__c, 'Order item should reference the menu item');
    Assert.areEqual(2, result.Quantity__c, 'Quantity should be set');
  }

  @IsTest
  static void shouldThrowException_WhenAddItemToOrderInvalidQuantity() {
    // Given
    OrderService service = new OrderService();
    Order__c order = [SELECT Id FROM Order__c WHERE Status__c = 'Draft' LIMIT 1];

    // When / Then
    Test.startTest();
    try {
      service.addItemToOrder(order.Id, 'Some Item', 0);
      Assert.fail('Should have thrown OrderException');
    } catch (OrderService.OrderException e) {
      Assert.isTrue(e.getMessage().contains('must be greater than 0'), 'Exception should indicate invalid quantity');
    }
    Test.stopTest();
  }

  @IsTest
  static void shouldThrowException_WhenAddItemToOrderNotDraft() {
    // Given
    OrderService service = new OrderService();
    Order__c order = [SELECT Id FROM Order__c LIMIT 1];
    order.Status__c = 'Confirmed';
    update order;

    // When / Then
    Test.startTest();
    try {
      service.addItemToOrder(order.Id, 'Some Item', 1);
      Assert.fail('Should have thrown OrderException');
    } catch (OrderService.OrderException e) {
      Assert.isTrue(
        e.getMessage().contains('Only Draft orders can be modified'),
        'Exception should indicate order cannot be modified'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void shouldThrowException_WhenAddItemToOrderMenuItemNotFound() {
    // Given
    OrderService service = new OrderService();
    Order__c order = [SELECT Id FROM Order__c WHERE Status__c = 'Draft' LIMIT 1];

    // When / Then
    Test.startTest();
    try {
      service.addItemToOrder(order.Id, 'Nonexistent Item', 1);
      Assert.fail('Should have thrown OrderException');
    } catch (OrderService.OrderException e) {
      Assert.isTrue(e.getMessage().contains('not found'), 'Exception should indicate menu item not found');
    }
    Test.stopTest();
  }

  @IsTest
  static void shouldThrowException_WhenAddItemToOrderFromDifferentStorefront() {
    // Given
    OrderService service = new OrderService();
    Order__c order = [SELECT Id FROM Order__c WHERE Status__c = 'Draft' LIMIT 1];
    Storefront__c otherStorefront = TestDataFactory.createStorefronts(1, true)[0];
    Menu__c otherMenu = TestDataFactory.createMenu(otherStorefront.Id, true);
    Menu_Item__c otherStorefrontItem = TestDataFactory.createMenuItems(otherMenu.Id, 1, false)[0];
    otherStorefrontItem.Name = 'Other Storefront Menu Item';
    insert otherStorefrontItem;

    // When / Then
    Test.startTest();
    try {
      service.addItemToOrder(order.Id, otherStorefrontItem.Name, 1);
      Assert.fail('Should have thrown OrderException');
    } catch (OrderService.OrderException e) {
      Assert.isTrue(
        e.getMessage().contains('not found'),
        'Exception should indicate the item is not on this order\'s storefront menu'
      );
    }
    Test.stopTest();
    Assert.areEqual(
      0,
      [SELECT COUNT() FROM Order_Item__c WHERE Order__c = :order.Id],
      'No order item should have been created from another storefront\'s menu'
    );
  }

  @IsTest
  static void shouldGetOrdersFromCustomer_WhenNoStatusFilter() {
    // Given
    OrderService service = new OrderService();
    Contact customer = [SELECT Id FROM Contact LIMIT 1];

    // When
    Test.startTest();
    List<Order__c> results = service.getOrdersFromCustomer(customer.Id, '');
    Test.stopTest();

    // Then
    Assert.isTrue(results.size() > 0, 'Should return orders');
    for (Order__c order : results) {
      Assert.areEqual(customer.Id, order.Customer__c, 'All orders should belong to the customer');
    }
  }

  @IsTest
  static void shouldGetOrdersFromCustomer_WhenStatusFilterApplied() {
    // Given
    OrderService service = new OrderService();
    Contact customer = [SELECT Id FROM Contact LIMIT 1];
    Storefront__c storefront = [SELECT Id FROM Storefront__c LIMIT 1];
    TestDataFactory.createOrders(customer.Id, storefront.Id, 'Confirmed', 1, true);

    // When
    Test.startTest();
    List<Order__c> draftOrders = service.getOrdersFromCustomer(customer.Id, 'Draft');
    List<Order__c> confirmedOrders = service.getOrdersFromCustomer(customer.Id, 'Confirmed');
    Test.stopTest();

    // Then
    Assert.isTrue(draftOrders.size() > 0, 'Should return draft orders');
    Assert.isTrue(confirmedOrders.size() > 0, 'Should return confirmed orders');
    for (Order__c order : draftOrders) {
      Assert.areEqual('Draft', order.Status__c, 'All orders should have Draft status');
    }
    for (Order__c order : confirmedOrders) {
      Assert.areEqual('Confirmed', order.Status__c, 'All orders should have Confirmed status');
    }
  }

  @IsTest
  static void shouldThrowException_WhenGetOrdersInvalidStatus() {
    // Given
    OrderService service = new OrderService();
    Contact customer = [SELECT Id FROM Contact LIMIT 1];

    // When / Then
    Test.startTest();
    try {
      service.getOrdersFromCustomer(customer.Id, 'InvalidStatus');
      Assert.fail('Should have thrown OrderException');
    } catch (OrderService.OrderException e) {
      Assert.isTrue(e.getMessage().contains('Invalid status value'), 'Exception should indicate invalid status');
    }
    Test.stopTest();
  }

  @IsTest
  static void shouldGetOrderItems_WhenOrderHasItems() {
    // Given
    OrderService service = new OrderService();
    Order__c order = [SELECT Id FROM Order__c LIMIT 1];
    Menu_Item__c menuItem = [SELECT Id FROM Menu_Item__c LIMIT 1];
    Order_Item__c item = new Order_Item__c(Order__c = order.Id, Menu_Item__c = menuItem.Id, Quantity__c = 1);
    insert item;

    // When
    Test.startTest();
    List<Order_Item__c> results = service.getOrderItems(order.Id);
    Test.stopTest();

    // Then
    Assert.areEqual(1, results.size(), 'Should return one order item');
    // Re-query to get the Order__c field
    Order_Item__c queriedItem = [SELECT Order__c FROM Order_Item__c WHERE Id = :results[0].Id LIMIT 1];
    Assert.areEqual(order.Id, queriedItem.Order__c, 'Order item should belong to the order');
  }

  @IsTest
  static void shouldReturnEmptyList_WhenOrderHasNoItems() {
    // Given
    OrderService service = new OrderService();
    Order__c order = [SELECT Id FROM Order__c LIMIT 1];

    // When
    Test.startTest();
    List<Order_Item__c> results = service.getOrderItems(order.Id);
    Test.stopTest();

    // Then
    Assert.areEqual(0, results.size(), 'Should return empty list when no items exist');
  }

  @IsTest
  static void shouldThrowException_WhenGetOrderItemsOrderIdIsNull() {
    // Given
    OrderService service = new OrderService();

    // When / Then
    Test.startTest();
    try {
      service.getOrderItems(null);
      Assert.fail('Should have thrown OrderException');
    } catch (OrderService.OrderException e) {
      Assert.isTrue(e.getMessage().contains('must be provided'), 'Exception should indicate ID is required');
    }
    Test.stopTest();
  }

  @IsTest
  static void shouldThrowException_WhenGetOrdersFromCustomerIdIsNull() {
    // Given
    OrderService service = new OrderService();

    // When / Then
    Test.startTest();
    try {
      service.getOrdersFromCustomer(null, '');
      Assert.fail('Should have thrown OrderException');
    } catch (OrderService.OrderException e) {
      Assert.isTrue(e.getMessage().contains('must be provided'), 'Exception should indicate ID is required');
    }
    Test.stopTest();
  }

  @IsTest
  static void shouldPassAssertion_WhenCustomerHasAccessToOrder() {
    // Given
    OrderService service = new OrderService();
    Contact customer = [SELECT Id FROM Contact LIMIT 1];
    Order__c order = [SELECT Id FROM Order__c WHERE Customer__c = :customer.Id LIMIT 1];

    // When / Then
    Test.startTest();
    service.assertCustomerHasAccessToOrder(customer.Id, order.Id);
    Test.stopTest();
  }

  @IsTest
  static void shouldThrowException_WhenOrderDoesNotExist() {
    // Given
    OrderService service = new OrderService();
    Contact customer = [SELECT Id FROM Contact LIMIT 1];
    Id nonExistentOrderId = TestDataFactory.getFakeId(Order__c.SObjectType);

    // When / Then
    Test.startTest();
    try {
      service.assertCustomerHasAccessToOrder(customer.Id, nonExistentOrderId);
      Assert.fail('Should have thrown OrderException');
    } catch (OrderService.OrderException e) {
      Assert.areEqual('You do not have access to this order', e.getMessage(), 'Exception should indicate no access');
    }
    Test.stopTest();
  }

  @IsTest
  static void shouldThrowException_WhenCustomerNotAllowedToAccessOrder() {
    // Given
    OrderService service = new OrderService();
    Contact otherCustomer = TestDataFactory.createCustomers(1, true)[0];
    Order__c order = [SELECT Id FROM Order__c LIMIT 1];

    // When / Then
    Test.startTest();
    try {
      service.assertCustomerHasAccessToOrder(otherCustomer.Id, order.Id);
      Assert.fail('Should have thrown OrderException');
    } catch (OrderService.OrderException e) {
      Assert.areEqual('You do not have access to this order', e.getMessage(), 'Exception should indicate no access');
    }
    Test.stopTest();
  }
}
