/**
 * Invocable action to get the status of an order by its ID
 */
global with sharing class GetOrderStatusAction {
  @TestVisible
  private static OrderService orderService = new OrderService();

  /**
   * Gets the status and details of an order by its ID
   * @param inputs List of Input parameters
   * @return List of Output results
   */
  @InvocableMethod(
    label='Get Order Status'
    description='Gets the status and details of an order by its ID'
    category='Order Management'
  )
  global static List<Output> getOrderStatus(List<Input> inputs) {
    List<Output> outputs = new List<Output>();

    for (Input input : inputs) {
      // Use OrderService to get the order
      if (String.isNotEmpty(input.customerId)) {
        orderService.assertCustomerHasAccessToOrder(input.customerId, input.orderId);
      }
      Order__c order = orderService.getOrderFromId(input.orderId);

      OrderStatus orderStatus = new OrderStatus();
      orderStatus.id = order.Id;
      orderStatus.name = order.Name;
      orderStatus.status = order.Status__c;
      orderStatus.customerName = order.Customer__r?.Name;
      orderStatus.storefrontName = order.Storefront__r?.Name;
      orderStatus.totalAmount = order.Total_Amount__c;
      orderStatus.orderTime = order.Order_Time__c;
      orderStatus.deliveryTime = order.Delivery_Time__c;
      orderStatus.orderTimeLabel = order.Order_Time__c?.format('MMM d, yyyy, h:mm a');
      orderStatus.deliveryTimeLabel = order.Delivery_Time__c?.format('MMM d, yyyy, h:mm a');
      orderStatus.items = toOrderItems(orderService.getOrderItems(order.Id));
      orderStatus.orderRecordLink =
        URL.getOrgDomainUrl().toExternalForm() +
        '/lightning/r/Order__c/' +
        order.Id +
        '/view';

      Output output = new Output();
      output.orderStatus = orderStatus;
      outputs.add(output);
    }

    return outputs;
  }

  /**
   * Maps order line item records to their invocable-safe representation.
   * @param items Order_Item__c records to map
   * @return List of OrderItem wrappers, in the same order as the input
   */
  private static List<OrderItem> toOrderItems(List<Order_Item__c> items) {
    List<OrderItem> orderItems = new List<OrderItem>();
    for (Order_Item__c item : items) {
      OrderItem orderItem = new OrderItem();
      orderItem.id = item.Id;
      orderItem.itemName = item.Item_Name__c;
      orderItem.quantity = item.Quantity__c;
      orderItem.totalAmount = item.Total_Amount__c;
      orderItems.add(orderItem);
    }
    return orderItems;
  }

  /**
   * Input parameters for the invocable action
   */
  global class Input {
    @InvocableVariable(label='Customer ID' description='The ID of the customer who placed the order')
    public String customerId;

    @InvocableVariable(label='Order ID' description='The order ID of the order to get status for' required=true)
    public String orderId;
  }

  /**
   * Output parameters for the invocable action
   */
  global class Output {
    @InvocableVariable(label='Order Status' description='The status of the order')
    public OrderStatus orderStatus;
  }

  /**
   * Status and details of an order
   */
  global class OrderStatus {
    @InvocableVariable
    public String id;
    @InvocableVariable
    public String name;
    @InvocableVariable
    public String status;
    @InvocableVariable
    public String customerName;
    @InvocableVariable
    public String storefrontName;
    @InvocableVariable
    public Decimal totalAmount;
    @InvocableVariable
    public Datetime orderTime;
    @InvocableVariable
    public Datetime deliveryTime;
    @InvocableVariable
    public String orderTimeLabel;
    @InvocableVariable
    public String deliveryTimeLabel;
    @InvocableVariable
    public List<OrderItem> items;
    @InvocableVariable
    public String orderRecordLink;
  }

  /**
   * A single line item on an order
   */
  global class OrderItem {
    @InvocableVariable
    public String id;
    @InvocableVariable
    public String itemName;
    @InvocableVariable
    public Decimal quantity;
    @InvocableVariable
    public Decimal totalAmount;
  }
}
