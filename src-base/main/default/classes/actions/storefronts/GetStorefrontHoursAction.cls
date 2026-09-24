/**
 * Invocable Action for retrieving a storefront's operating hours by its Id
 */
global with sharing class GetStorefrontHoursAction {
  @TestVisible
  private static StorefrontService storefrontService = new StorefrontService();

  /**
   * Retrieves the operating hours for a storefront by its Id
   * @param inputs List of request objects containing the storefront Id
   * @return List of response objects containing the operating hours data
   * @example
   * List<GetStorefrontHoursAction.Output> results =
   *   GetStorefrontHoursAction.getStorefrontHours(inputs);
   */
  @InvocableMethod(
    label='Get Storefront Hours'
    description='Retrieves the operating hours for a storefront by its Id'
    category='Storefront Management'
  )
  global static List<Output> getStorefrontHours(List<Input> inputs) {
    List<Output> responses = new List<Output>();
    for (Input request : inputs) {
      Output response = new Output();
      try {
        List<Storefront_Hours_of_Operation__c> hours = storefrontService.getStorefrontHours(request.storefrontId);
        if (hours.isEmpty()) {
          response.hours = hours;
          response.isSuccess = false;
          response.message = 'No operating hours found for storefront: ' + request.storefrontId;
        } else {
          response.hours = hours;
          response.isSuccess = true;
          response.message = 'Operating hours retrieved successfully';
        }
      } catch (Exception e) {
        response.hours = new List<Storefront_Hours_of_Operation__c>();
        response.isSuccess = false;
        response.message = 'Error retrieving operating hours: ' + e.getMessage();
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
      label='Storefront Id'
      description='The Id of the storefront whose operating hours are retrieved'
      required=true
    )
    public String storefrontId;
  }

  /**
   * Response from the invocable action
   */
  global class Output {
    @InvocableVariable(
      label='Is Success'
      description='Indicates whether the operating hours were retrieved successfully'
    )
    public Boolean isSuccess;

    @InvocableVariable(label='Message' description='Success or error message')
    public String message;

    @InvocableVariable(
      label='Hours of Operation'
      description='The retrieved operating hours records for the storefront'
    )
    public List<Storefront_Hours_of_Operation__c> hours;
  }
}
