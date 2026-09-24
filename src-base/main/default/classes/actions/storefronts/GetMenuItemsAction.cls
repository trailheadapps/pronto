/**
 * Invocable Action for retrieving a storefront's available menu items by its Id
 */
global with sharing class GetMenuItemsAction {
  @TestVisible
  private static StorefrontService storefrontService = new StorefrontService();

  /**
   * Retrieves the available menu items for a storefront by its Id
   * @param inputs List of request objects containing the storefront Id
   * @return List of response objects containing the menu item data
   * @example
   * List<GetMenuItemsAction.Output> results =
   *   GetMenuItemsAction.getMenuItems(inputs);
   */
  @InvocableMethod(
    label='Get Menu Items'
    description='Retrieves the available menu items for a storefront by its Id'
    category='Storefront Management'
  )
  global static List<Output> getMenuItems(List<Input> inputs) {
    List<Output> responses = new List<Output>();
    for (Input request : inputs) {
      Output response = new Output();
      try {
        List<Menu_Item__c> menuItems = storefrontService.getMenuItems(request.storefrontId);
        if (menuItems.isEmpty()) {
          response.menuItems = menuItems;
          response.isSuccess = false;
          response.message = 'No menu items found for storefront: ' + request.storefrontId;
        } else {
          response.menuItems = menuItems;
          response.isSuccess = true;
          response.message = 'Menu items retrieved successfully';
        }
      } catch (Exception e) {
        response.menuItems = new List<Menu_Item__c>();
        response.isSuccess = false;
        response.message = 'Error retrieving menu items: ' + e.getMessage();
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
      description='The Id of the storefront whose menu items are retrieved'
      required=true
    )
    public String storefrontId;
  }

  /**
   * Response from the invocable action
   */
  global class Output {
    @InvocableVariable(label='Is Success' description='Indicates whether the menu items were retrieved successfully')
    public Boolean isSuccess;

    @InvocableVariable(label='Message' description='Success or error message')
    public String message;

    @InvocableVariable(label='Menu Items' description='The retrieved available menu item records for the storefront')
    public List<Menu_Item__c> menuItems;
  }
}
