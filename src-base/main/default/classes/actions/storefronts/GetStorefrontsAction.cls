/**
 * Invocable Action for retrieving the first storefronts
 */
global with sharing class GetStorefrontsAction {
  @TestVisible
  private static StorefrontService storefrontService = new StorefrontService();

  /**
   * Retrieves the first 10 storefronts
   * @param inputs List of request objects
   * @return List of response objects containing the storefront data
   */
  @InvocableMethod(
    label='Get Storefronts'
    description='Retrieves the first 10 storefronts'
    category='Storefront Management'
  )
  global static List<Output> getStorefronts(List<Input> inputs) {
    List<Output> responses = new List<Output>();

    for (Input request : inputs) {
      Output response = new Output();
      try {
        response.storefronts = storefrontService.getStorefronts(request.recordLimit);
        response.message = 'Found ' + response.storefronts.size() + ' storefronts.';
        response.isSuccess = true;
      } catch (Exception e) {
        response.message = 'Error retrieving storefronts: ' + e.getMessage();
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
      description='Optional maximum number of storefronts to return. Defaults to 10.'
      required=false
    )
    public Integer recordLimit;
  }

  /**
   * Response from the invocable action
   */
  global class Output {
    @InvocableVariable(label='Storefronts' description='The retrieved storefront records')
    public List<Storefront__c> storefronts;

    @InvocableVariable(label='Message' description='Success or error message')
    public String message;

    @InvocableVariable(label='Is Success' description='Indicates whether the storefronts were retrieved successfully')
    public Boolean isSuccess;
  }
}
