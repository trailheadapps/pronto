/**
 * Invocable action to cancel orders that are in Draft or Confirmed status
 */
global with sharing class CancelOrderAction {
  @TestVisible
  private static OrderService orderService = new OrderService();

  /**
   * Cancels an order if it is in Draft or Confirmed status
   * @param inputs List of Input containing order IDs and optional cancelation reasons
   * @return List of Output with results
   */
  @InvocableMethod(
    label='Cancel Order'
    description='Cancels an order if it is in Draft or Confirmed status'
    category='Order Management'
  )
  global static List<Output> cancelOrder(List<Input> inputs) {
    List<Output> outputs = new List<Output>();
    for (Input input : inputs) {
      Output output = new Output();
      try {
        if (String.isNotEmpty(input.customerId)) {
          orderService.assertCustomerHasAccessToOrder(input.customerId, input.orderId);
        }
        Order__c order = orderService.cancelOrder(input.orderId, input.cancelationReason);
        output.isSuccess = true;
        output.message = 'Order ' + order.Name + ' was canceled';
      } catch (Exception e) {
        output.isSuccess = false;
        output.message = e.getMessage();
      }
      outputs.add(output);
    }
    return outputs;
  }

  /**
   * Input parameters for the cancel order action
   */
  global class Input {
    @InvocableVariable(label='Customer ID' description='The ID of the customer who placed the order')
    public String customerId;

    @InvocableVariable(label='Order ID' description='The order ID of the order to cancel' required=true)
    public String orderId;

    @InvocableVariable(label='Cancelation Reason' description='Optional reason for canceling the order' required=false)
    public String cancelationReason;
  }

  /**
   * Output parameters for the cancel order action
   */
  global class Output {
    @InvocableVariable(label='Success' description='Whether the order was successfully canceled')
    public Boolean isSuccess;

    @InvocableVariable(label='Message' description='Result message')
    public String message;

    @InvocableVariable(label='Order ID' description='The ID of the processed order')
    public String orderId;
  }
}
