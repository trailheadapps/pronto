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
        response.menu = new StorefrontMenu(menuItems);
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

    @InvocableVariable(label='Menu' description='Display-ready storefront menu, rendered as the storefront menu widget')
    public StorefrontMenu menu;
  }

  /**
   * Display-ready storefront menu. Widgets can't compute values, so labels are built here.
   */
  global class StorefrontMenu {
    public StorefrontMenu() {
    }
    public StorefrontMenu(List<Menu_Item__c> menuItems) {
      this.items = new List<MenuItemView>();
      Decimal lowestPrice;
      Decimal highestPrice;
      for (Menu_Item__c menuItem : menuItems) {
        this.items.add(new MenuItemView(menuItem));
        if (menuItem.Price__c != null) {
          lowestPrice = lowestPrice == null ? menuItem.Price__c : Math.min(lowestPrice, menuItem.Price__c);
          highestPrice = highestPrice == null ? menuItem.Price__c : Math.max(highestPrice, menuItem.Price__c);
        }
      }
      if (!menuItems.isEmpty() && menuItems[0].Menu__r?.Storefront__r != null) {
        this.storefrontName = menuItems[0].Menu__r.Storefront__r.Name;
      }
      this.summaryLabel = getSummaryLabel(menuItems.size(), lowestPrice, highestPrice);
    }

    @InvocableVariable
    public String storefrontName;
    @InvocableVariable
    public String summaryLabel;
    @InvocableVariable
    public List<MenuItemView> items;
  }

  /**
   * Display-ready menu item
   */
  global class MenuItemView {
    public MenuItemView() {
    }
    public MenuItemView(Menu_Item__c menuItem) {
      this.name = menuItem.Name;
      this.description = menuItem.Description__c;
      this.priceLabel = getPriceLabel(menuItem.Price__c);
    }

    @InvocableVariable
    public String name;
    @InvocableVariable
    public String description;
    @InvocableVariable
    public String priceLabel;
  }

  @TestVisible
  private static String getPriceLabel(Decimal price) {
    if (price == null) {
      return '';
    }
    return '$' + String.valueOf(price.setScale(2));
  }

  @TestVisible
  private static String getSummaryLabel(Integer itemCount, Decimal lowestPrice, Decimal highestPrice) {
    String label = itemCount + (itemCount == 1 ? ' dish' : ' dishes');
    if (lowestPrice == null) {
      return label;
    }
    if (lowestPrice == highestPrice) {
      return label + ' · ' + getPriceLabel(lowestPrice);
    }
    return label + ' · ' + getPriceLabel(lowestPrice) + '–' + getPriceLabel(highestPrice);
  }
}
