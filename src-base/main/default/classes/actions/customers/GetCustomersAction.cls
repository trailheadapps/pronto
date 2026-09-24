/**
 * Invocable Action for retrieving the first customers
 */
global with sharing class GetCustomersAction {
  @TestVisible
  private static CustomerService customerService = new CustomerService();

  /**
   * Retrieves the first 10 customers
   * @param inputs List of request objects
   * @return List of response objects containing the customer data
   */
  @InvocableMethod(label='Get Customers' description='Retrieves the first 10 customers' category='Customer Management')
  global static List<Output> getCustomers(List<Input> inputs) {
    List<Output> responses = new List<Output>();

    for (Input request : inputs) {
      Output response = new Output();
      try {
        response.customers = customerService.getCustomers(request.recordLimit);
        response.message = 'Found ' + response.customers.size() + ' customers.';
        response.isSuccess = true;
      } catch (Exception e) {
        response.message = 'Error retrieving customers: ' + e.getMessage();
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
    @InvocableVariable(
      label='Record Limit'
      description='Optional maximum number of customers to return. Defaults to 10.'
      required=false
    )
    public Integer recordLimit;
  }

  /**
   * Response from the invocable action
   */
  global class Output {
    @InvocableVariable(label='Customers' description='The retrieved customer records')
    public List<Contact> customers;

    @InvocableVariable(label='Message' description='Success or error message')
    public String message;

    @InvocableVariable(label='Is Success' description='Indicates whether the customers were retrieved successfully')
    public Boolean isSuccess;
  }
}
