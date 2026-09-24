/**
 * Invocable action to get an order by its order number (Name)
 */
global with sharing class GetOrderFromNameAction {
  @TestVisible
  private static OrderService orderService = new OrderService();

  /**
   * Gets the details of an order by its order number (Name)
   * @param inputs List of Input parameters
   * @return List of Output results
   */
  @InvocableMethod(
    label='Get Order From Name'
    description='Gets the details of an order by its order number (Name)'
    category='Order Management'
  )
  global static List<Output> getOrderFromName(List<Input> inputs) {
    List<Output> outputs = new List<Output>();
    for (Input input : inputs) {
      Output output = new Output();
      try {
        Order__c order = orderService.getOrderFromName(input.orderName);
        if (String.isNotEmpty(input.customerId)) {
          orderService.assertCustomerHasAccessToOrder(input.customerId, order.Id);
        }
        output.orderId = order.Id;
        output.success = true;
        output.order = order;
      } catch (Exception e) {
        output.success = false;
        output.message = e.getMessage();
      }
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

    @InvocableVariable(
      label='Order Number'
      description='The order number (Name) of the order to retrieve'
      required=true
    )
    public String orderName;
  }

  /**
   * Output parameters for the invocable action
   */
  global class Output {
    @InvocableVariable(label='Success' description='Whether the order was successfully retrieved')
    public Boolean success;

    @InvocableVariable(label='Message' description='Result message')
    public String message;

    @InvocableVariable(label='Order ID' description='The ID of the retrieved order')
    public String orderId;

    @InvocableVariable(label='Order' description='The order details')
    public Order__c order;
  }
}
