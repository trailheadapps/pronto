/**
 * Invocable action to create a draft order for a customer at a storefront
 */
global with sharing class CreateOrderAction {
  @TestVisible
  private static OrderService orderService = new OrderService();

  /**
   * Creates a draft order
   * @param inputs List of Input parameters
   * @return List of Output results
   */
  @InvocableMethod(label='Create Order' description='Creates a draft order' category='Order Management')
  global static List<Output> createOrder(List<Input> inputs) {
    List<Output> responses = new List<Output>();
    for (Input request : inputs) {
      Output response = new Output();
      try {
        Order__c order = orderService.createDraftOrder(request.customerId, request.storefrontId);
        response.isSuccess = true;
        response.orderId = order.Id;
        response.message = 'Draft order ' + order.Name + ' created successfully. You can now add items to the order.';
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
    @InvocableVariable(
      label='Customer ID'
      description='ID of the customer (Contact) to create the order for'
      required=true
    )
    public String customerId;

    @InvocableVariable(label='Storefront ID' description='ID of the storefront to create the order for' required=true)
    public String storefrontId;
  }

  /**
   * Output wrapper for the invocable action
   */
  global class Output {
    @InvocableVariable(label='Is Success' description='Indicates whether the order was created successfully')
    public Boolean isSuccess;

    @InvocableVariable(label='Order ID' description='ID of the created order (if successful)')
    public String orderId;

    @InvocableVariable(label='Message' description='Success or error message')
    public String message;
  }

  /**
   * Exception thrown when a draft order cannot be created
   */
  public class CreateOrderException extends Exception {
  }
}
