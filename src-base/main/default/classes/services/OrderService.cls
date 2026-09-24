/**
 * Service class for managing `Order__c` records and their line items,
 * including lifecycle transitions (draft, confirm, cancel) and item handling.
 */
public virtual with sharing class OrderService {
  private static Set<String> orderStatusValues;

  /**
   * Checks whether a customer has access to an order
   * @param customerId ID of the customer or null in case the check is run for an employee
   * @param orderId ID of the order to check.
   * @throws OrderException if the customer does not have access or if the order does not exist.
   */
  public virtual void assertCustomerHasAccessToOrder(Id customerId, Id orderId) {
    if (customerId == null) {
      return; // Employees have access to all orders
    }
    List<Order__c> orders = [
      SELECT Id, Customer__c
      FROM Order__c
      WHERE Id = :orderId AND Customer__c = :customerId
      WITH USER_MODE
      LIMIT 1
    ];
    if (orders.isEmpty()) {
      throw new OrderService.OrderException('You do not have access to this order');
    }
  }

  /**
   * Retrieves a single order by its record ID.
   * @param orderId ID of the order to retrieve.
   * @return The matching `Order__c` record.
   * @throws OrderException If no order exists with the given ID.
   */
  public virtual Order__c getOrderFromId(Id orderId) {
    List<Order__c> orders = [
      SELECT
        Id,
        Name,
        Status__c,
        Customer__r.Name,
        Storefront__r.Name,
        Total_Amount__c,
        Order_Time__c,
        Delivery_Time__c,
        Cancelation_Reason__c
      FROM Order__c
      WHERE Id = :orderId
      WITH USER_MODE
      LIMIT 1
    ];
    if (orders.isEmpty()) {
      throw new OrderException('No order found with ID: ' + orderId);
    }
    return orders[0];
  }

  /**
   * Retrieves a single order by its auto-generated order number (Name).
   * @param orderName Order number to look up.
   * @return The matching `Order__c` record.
   * @throws OrderException If no order exists with the given number.
   */
  public virtual Order__c getOrderFromName(String orderName) {
    List<Order__c> orders = [
      SELECT
        Id,
        Name,
        Status__c,
        Customer__r.Name,
        Storefront__r.Name,
        Total_Amount__c,
        Order_Time__c,
        Delivery_Time__c,
        Cancelation_Reason__c
      FROM Order__c
      WHERE Name = :orderName
      WITH USER_MODE
      LIMIT 1
    ];
    if (orders.isEmpty()) {
      throw new OrderException('No order found with number: ' + orderName);
    }
    return orders[0];
  }

  /**
   * Cancels an order, recording the reason. Only `Draft` or `Confirmed`
   * orders can be canceled.
   * @param orderId ID of the order to cancel.
   * @param cancelationReason Reason for the cancellation.
   * @return The canceled `Order__c` record.
   * @throws OrderException If the order is not found or cannot be canceled in its current status.
   */
  public virtual Order__c cancelOrder(Id orderId, String cancelationReason) {
    List<Order__c> orders = [SELECT Id, Name, Status__c FROM Order__c WHERE Id = :orderId WITH USER_MODE LIMIT 1];
    if (orders.isEmpty()) {
      throw new OrderException('No order found with ID: ' + orderId);
    }
    Order__c order = orders[0];

    // Check if order can be canceled
    if (order.Status__c != 'Draft' && order.Status__c != 'Confirmed') {
      throw new OrderException(
        'Order ' + order.Name + ' cannot be canceled because of its current status: ' + order.Status__c + '.'
      );
    }

    // Update order status to Canceled
    order.Status__c = 'Canceled';
    order.Cancelation_Reason__c = cancelationReason;
    update as user new Order__c(
      Id = order.Id,
      Status__c = order.Status__c,
      Cancelation_Reason__c = order.Cancelation_Reason__c
    );
    return order;
  }

  /**
   * Confirms a draft order and stamps its order time. Only `Draft` orders
   * can be confirmed.
   * @param orderId ID of the order to confirm.
   * @return The confirmed `Order__c` record.
   * @throws OrderException If the order is not found or is not in `Draft` status.
   */
  public virtual Order__c confirmOrder(Id orderId) {
    List<Order__c> orders = [SELECT Id, Name, Status__c FROM Order__c WHERE Id = :orderId WITH USER_MODE LIMIT 1];
    if (orders.isEmpty()) {
      throw new OrderException('No order found with ID: ' + orderId);
    }
    Order__c order = orders[0];

    // Check if order can be confirmed
    if (order.Status__c != 'Draft') {
      throw new OrderException(
        'Order ' +
          order.Name +
          ' cannot be confirmed because of its current status: ' +
          order.Status__c +
          '. Only Draft orders can be confirmed.'
      );
    }

    // Update order status to Confirmed
    order.Order_Time__c = System.now();
    order.Status__c = 'Confirmed';
    update as user new Order__c(Id = order.Id, Order_Time__c = order.Order_Time__c, Status__c = order.Status__c);
    return order;
  }

  /**
   * Creates a draft order for a customer, copying the delivery address from
   * the customer's mailing address.
   * @param customerId ID of the customer (Contact) placing the order.
   * @param storefrontId ID of the storefront the order is placed with.
   * @return The newly created `Order__c` record with its generated Name.
   */
  public virtual Order__c createDraftOrder(Id customerId, Id storefrontId) {
    // Get contact with delivery address
    Contact customer = [
      SELECT Id, MailingStreet, MailingCity, MailingStateCode, MailingPostalCode, MailingCountryCode
      FROM Contact
      WHERE Id = :customerId
      WITH USER_MODE
      LIMIT 1
    ];

    // Create the draft order
    Order__c newOrder = new Order__c();
    newOrder.Customer__c = customerId;
    newOrder.Storefront__c = storefrontId;
    newOrder.Status__c = 'Draft';
    newOrder.Delivery_Address__Street__s = customer.MailingStreet;
    newOrder.Delivery_Address__City__s = customer.MailingCity;
    newOrder.Delivery_Address__CountryCode__s = customer.MailingCountryCode;
    newOrder.Delivery_Address__StateCode__s = customer.MailingStateCode;
    newOrder.Delivery_Address__PostalCode__s = customer.MailingPostalCode;
    insert as user newOrder;

    // Return the inserted order with its generated Name
    return [SELECT Id, Name FROM Order__c WHERE Id = :newOrder.Id WITH USER_MODE LIMIT 1];
  }

  /**
   * Adds a line item to a draft order, matching the menu item by a partial name search.
   * @param orderId ID of the order to add the item to.
   * @param orderItemName Name (or partial name) of the menu item to add.
   * @param quantity Quantity to order; must be greater than 0.
   * @return The newly created `Order_Item__c` record.
   * @throws OrderException If the quantity is invalid, the order is not found or not in `Draft` status, or the menu item is not found.
   */
  public virtual Order_Item__c addItemToOrder(Id orderId, String orderItemName, Decimal quantity) {
    // Validate quantity
    if (quantity == null || quantity <= 0) {
      throw new OrderException('Quantity must be greater than 0.');
    }

    // Get the order
    List<Order__c> orders = [
      SELECT Id, Name, Status__c, Storefront__c
      FROM Order__c
      WHERE Id = :orderId
      WITH USER_MODE
      LIMIT 1
    ];
    if (orders.isEmpty()) {
      throw new OrderException('No order found with ID: ' + orderId);
    }
    Order__c order = orders[0];

    // Validate order status - only allow adding items to Draft orders
    if (order.Status__c != 'Draft') {
      throw new OrderException(
        'Cannot add items to order ' +
          order.Name +
          ' because it is in ' +
          order.Status__c +
          ' status. Only Draft orders can be modified.'
      );
    }

    // Find the menu item by name, restricted to the order's storefront
    String menuItemSearch = '%' + orderItemName + '%';
    List<Menu_Item__c> menuItems = [
      SELECT Id, Name
      FROM Menu_Item__c
      WHERE Name LIKE :menuItemSearch AND Menu__r.Storefront__c = :order.Storefront__c
      WITH USER_MODE
      LIMIT 1
    ];
    if (menuItems.isEmpty()) {
      throw new OrderException('Menu item "' + orderItemName + '" not found.');
    }

    // Create the order item
    Order_Item__c orderItem = new Order_Item__c(
      Order__c = order.Id,
      Menu_Item__c = menuItems[0].Id,
      Quantity__c = quantity
    );
    insert as user orderItem;
    return orderItem;
  }

  /**
   * Retrieves the 10 most recent orders for a customer, optionally filtered by status.
   * @param customerId ID of the customer (Contact) whose orders to retrieve.
   * @param orderStatus Optional status to filter by; blank returns all statuses.
   * @return A list of matching `Order__c` records, newest first.
   * @throws OrderException If customerId is null or the provided status is not a valid picklist value.
   */
  public virtual List<Order__c> getOrdersFromCustomer(Id customerId, String orderStatus) {
    if (customerId == null) {
      throw new OrderException('A customer ID must be provided.');
    }

    if (!isValidOrderStatus(orderStatus)) {
      throw new OrderException('Invalid status value: ' + orderStatus);
    }

    // Build dynamic SOQL query based on optional order status parameter
    String soqlQuery =
      'SELECT Id, Name, Customer__c, Storefront__c, Order_Time__c, Status__c, Total_Amount__c, Storefront__r.Name ' +
      'FROM Order__c ' +
      'WHERE Customer__c = :customerId';
    if (String.isNotBlank(orderStatus)) {
      soqlQuery += ' AND Status__c = :orderStatus';
    }
    soqlQuery += ' ORDER BY Order_Time__c DESC LIMIT 10';

    return Database.query(soqlQuery, AccessLevel.USER_MODE);
  }

  /**
   * Retrieves all line items for a given order.
   * @param orderId ID of the order whose items to retrieve.
   * @return A list of `Order_Item__c` records for the order.
   * @throws OrderException If orderId is null.
   */
  public virtual List<Order_Item__c> getOrderItems(Id orderId) {
    if (orderId == null) {
      throw new OrderException('An order ID must be provided.');
    }

    return [
      SELECT Id, Item_Name__c, Quantity__c, Total_Amount__c
      FROM Order_Item__c
      WHERE Order__c = :orderId
      WITH USER_MODE
      ORDER BY Name
    ];
  }

  /**
   * Checks whether a value is a valid, active `Status__c` picklist value.
   * A blank value is considered valid (no filter). Picklist values are
   * lazy-loaded and cached for the transaction.
   * @param value The status value to validate.
   * @return `true` if the value is blank or an active picklist value; otherwise `false`.
   */
  private Boolean isValidOrderStatus(String value) {
    // A blank value means "no status filter", which is valid
    if (String.isBlank(value)) {
      return true;
    }

    // Lazy-load the active picklist values once per transaction
    if (orderStatusValues == null) {
      orderStatusValues = new Set<String>();
      for (Schema.PicklistEntry entry : Order__c.Status__c.getDescribe().getPicklistValues()) {
        if (entry.isActive()) {
          orderStatusValues.add(entry.getValue());
        }
      }
    }
    return orderStatusValues.contains(value);
  }

  /**
   * Exception thrown when an order operation cannot be completed.
   */
  public class OrderException extends Exception {
  }
}
