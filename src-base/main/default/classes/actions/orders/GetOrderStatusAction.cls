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
      orderStatus.items = orderService.getOrderItems(order.Id);

      Output output = new Output();
      output.orderStatus = orderStatus;
      outputs.add(output);
    }

    return outputs;
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
    public String id;
    public String name;
    public String status;
    public String customerName;
    public String storefrontName;
    public Decimal totalAmount;
    public Datetime orderTime;
    public Datetime deliveryTime;
    public List<Order_Item__c> items;
  }
}
