/**
 * Invocable action to get orders placed by a customer
 */
global with sharing class GetOrdersFromCustomerAction {
  @TestVisible
  private static OrderService orderService = new OrderService();

  /**
   * Get orders from a customer
   * @param inputs List of Input parameters
   * @return List of Output results
   */
  @InvocableMethod(label='Get Customer Orders' description='Get orders from a customer' category='Order Management')
  global static List<Output> getOrders(List<Input> inputs) {
    List<Output> responses = new List<Output>();
    for (Input request : inputs) {
      Output response = new Output();
      try {
        List<Order__c> orders = orderService.getOrdersFromCustomer(request.customerId, request.orderStatus);
        response.isSuccess = true;
        response.orders = orders;
        response.message = 'Found ' + orders.size() + ' orders.';
      } catch (Exception e) {
        response.isSuccess = false;
        response.message = 'Error creating draft order: ' + e.getMessage();
      }
      responses.add(response);
    }

    return responses;
  }

  /**
   * Input wrapper for the invocable action
   */
  global class Input {
    @InvocableVariable(label='Customer ID' description='Customer ID to retrieve orders from' required=true)
    public String customerId;

    @InvocableVariable(
      label='Order Status'
      description='Optional filter for order status (e.g., Delivered, Pending, Canceled)'
      required=false
    )
    public String orderStatus;
  }

  /**
   * Output wrapper for the invocable action
   */
  global class Output {
    @InvocableVariable(label='Success' description='Whether the operation was successful')
    public Boolean isSuccess;

    @InvocableVariable(label='Message' description='Result message')
    public String message;

    @InvocableVariable(label='Orders' description='List of customer orders')
    public List<Order__c> orders;
  }

  /**
   * Exception thrown when orders cannot be retrieved for a customer
   */
  public class OrderException extends Exception {
  }
}
