/**
 * Invocable action to confirm orders that are in Draft status
 */
global with sharing class ConfirmOrderAction {
  @TestVisible
  private static OrderService orderService = new OrderService();

  /**
   * Confirms an order by setting its status to Confirmed
   * @param inputs List of Input containing order IDs
   * @return List of Output with results
   */
  @InvocableMethod(
    label='Confirm Order'
    description='Confirms an order by setting its status to Confirmed'
    category='Order Management'
  )
  global static List<Output> confirmOrder(List<Input> inputs) {
    List<Output> outputs = new List<Output>();

    for (Input input : inputs) {
      Output output = new Output();
      try {
        if (String.isNotEmpty(input.customerId)) {
          orderService.assertCustomerHasAccessToOrder(input.customerId, input.orderId);
        }
        Order__c order = orderService.confirmOrder(input.orderId);
        output.orderId = order.Id;
        output.success = true;
        output.message = 'Order ' + order.Name + ' has been confirmed';
      } catch (Exception e) {
        output.success = false;
        output.message = e.getMessage();
      }
      outputs.add(output);
    }
    return outputs;
  }

  /**
   * Input parameters for the confirm order action
   */
  global class Input {
    @InvocableVariable(label='Customer ID' description='The ID of the customer who placed the order')
    public String customerId;

    @InvocableVariable(label='Order ID' description='The order ID of the order to confirm' required=true)
    public String orderId;
  }

  /**
   * Output parameters for the confirm order action
   */
  global class Output {
    @InvocableVariable(label='Success' description='Whether the order was successfully confirmed')
    public Boolean success;

    @InvocableVariable(label='Message' description='Result message')
    public String message;

    @InvocableVariable(label='Order ID' description='The ID of the processed order')
    public String orderId;
  }
}
