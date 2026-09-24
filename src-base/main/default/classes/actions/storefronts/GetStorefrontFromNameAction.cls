/**
 * Invocable Action for retrieving a storefront by its name
 */
global with sharing class GetStorefrontFromNameAction {
  @TestVisible
  private static StorefrontService storefrontService = new StorefrontService();

  /**
   * Retrieves a storefront record by its name
   * @param inputs List of request objects containing storefront name
   * @return List of response objects containing the storefront data
   */
  @InvocableMethod(
    label='Get Storefront From Name'
    description='Retrieves a storefront record by its name'
    category='Storefront Management'
  )
  global static List<Output> getStorefrontFromName(List<Input> inputs) {
    List<Output> responses = new List<Output>();

    for (Input request : inputs) {
      Output response = new Output();
      try {
        response.storefront = storefrontService.getStorefrontFromName(request.storefrontName);
        response.storefrontId = response.storefront.Id;
        response.message = 'Storefront retrieved successfully';
        response.isSuccess = true;
      } catch (StorefrontService.StorefrontException e) {
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
    @InvocableVariable(label='Storefront Name' description='The name of the storefront to retrieve' required=true)
    public String storefrontName;
  }

  /**
   * Response from the invocable action
   */
  global class Output {
    @InvocableVariable(label='Storefront' description='The retrieved storefront record')
    public Storefront__c storefront;

    @InvocableVariable(label='Storefront ID' description='The ID of the retrieved storefront')
    public String storefrontId;

    @InvocableVariable(label='Message' description='Success or error message')
    public String message;

    @InvocableVariable(label='Is Success' description='Indicates whether the storefront was retrieved successfully')
    public Boolean isSuccess;
  }
}
