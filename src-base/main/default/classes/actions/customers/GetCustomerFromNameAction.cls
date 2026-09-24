/**
 * Invocable Action for retrieving a customer by its name
 */
global with sharing class GetCustomerFromNameAction {
  @TestVisible
  private static CustomerService customerService = new CustomerService();

  /**
   * Retrieves a customer record from its name
   * @param inputs List of request objects containing customer name
   * @return List of response objects containing the customer data
   */
  @InvocableMethod(
    label='Get Customer From Name'
    description='Retrieves a customer record by its name'
    category='Customer Management'
  )
  global static List<Output> getCustomerFromName(List<Input> inputs) {
    List<Output> responses = new List<Output>();

    for (Input request : inputs) {
      Output response = new Output();
      try {
        response.customer = customerService.getCustomerFromName(request.customerName);
        response.customerId = response.customer.Id;
        response.message = 'Customer retrieved successfully';
        response.isSuccess = true;
      } catch (CustomerService.CustomerException e) {
        response.message = e.getMessage();
        response.isSuccess = false;
      }
      responses.add(response);
    }

    return responses;
  }

  /**
   * Input parameters for the invocable action
   */
  global class Input {
    @InvocableVariable(label='Customer Name' description='The name of the customer to retrieve' required=true)
    public String customerName;
  }

  /**
   * Response from the invocable action
   */
  global class Output {
    @InvocableVariable(label='Customer' description='The retrieved customer record')
    public Contact customer;

    @InvocableVariable(label='Customer ID' description='The ID of the retrieved customer')
    public String customerId;

    @InvocableVariable(label='Message' description='Success or error message')
    public String message;

    @InvocableVariable(label='Is Success' description='Indicates whether the customer was retrieved successfully')
    public Boolean isSuccess;
  }
}
