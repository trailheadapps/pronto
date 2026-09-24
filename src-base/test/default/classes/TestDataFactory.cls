/**
 * Central factory for building test records. Keeps @TestSetup blocks free of
 * inline record construction so test data stays consistent across test classes.
 */
@IsTest
public class TestDataFactory {
  public static final String STOREFRONT_NAME_PREFIX = 'Test Storefront ';
  public static final String CONTACT_LAST_NAME_PREFIX = 'Test Customer ';
  public static final String MENU_ITEM_NAME_PREFIX = 'Test Menu Item ';
  public static final Decimal MENU_ITEM_PRICE = 10;

  public static final List<String> WEEK_DAYS = new List<String>{
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  };

  private static Integer fakeRecordCount = 0;
  private static Map<Schema.SObjectType, String> sObjectKeyPrefixes = new Map<Schema.SObjectType, String>();

  /**
   * Generates a fake ID for the given SObject
   * @param sObjectType SObject type to generate a fake ID for
   * @return fake ID
   */
  public static Id getFakeId(Schema.SObjectType sObjectType) {
    // Lazily cache the 3-character prefix unique to the object type
    if (!sObjectKeyPrefixes.containsKey(sObjectType)) {
      sObjectKeyPrefixes.put(sObjectType, sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getKeyPrefix());
    }
    String prefix = sObjectKeyPrefixes.get(sObjectType);
    // Format the counter into a string
    String currentCount = String.valueOf(fakeRecordCount++);
    // Pad with zeros to create a standard 18-character Salesforce ID format
    String fakeIdSuffix = '0'.repeat(12 - currentCount.length()) + currentCount;
    return (Id) (prefix + fakeIdSuffix);
  }

  /**
   * Builds Storefront records.
   * @param count Number of storefronts to build
   * @param doInsert Whether to insert the records
   * @return The built (and optionally inserted) storefronts
   */
  public static List<Storefront__c> createStorefronts(Integer count, Boolean doInsert) {
    List<Storefront__c> storefronts = new List<Storefront__c>();
    for (Integer i = 0; i < count; i++) {
      storefronts.add(new Storefront__c(Name = STOREFRONT_NAME_PREFIX + i));
    }
    if (doInsert && !storefronts.isEmpty()) {
      insert storefronts;
    }
    return storefronts;
  }

  /**
   * Builds one Hours of Operation record per weekday for the given storefront.
   * @param storefrontId The parent storefront Id
   * @param doInsert Whether to insert the records
   * @return The built (and optionally inserted) hours records
   */
  public static List<Storefront_Hours_of_Operation__c> createWeekdayHours(Id storefrontId, Boolean doInsert) {
    List<Storefront_Hours_of_Operation__c> hours = new List<Storefront_Hours_of_Operation__c>();
    for (String day : WEEK_DAYS) {
      hours.add(
        new Storefront_Hours_of_Operation__c(
          Storefront__c = storefrontId,
          Day_of_Week__c = day,
          Opening_Time__c = '09:00',
          Closing_Time__c = '17:00'
        )
      );
    }
    if (doInsert) {
      insert hours;
    }
    return hours;
  }

  /**
   * Builds Contact records to act as order customers, each with a mailing address.
   * @param count Number of contacts to build
   * @param doInsert Whether to insert the records
   * @return The built (and optionally inserted) contacts
   */
  public static List<Contact> createCustomers(Integer count, Boolean doInsert) {
    List<Contact> customers = new List<Contact>();
    for (Integer i = 0; i < count; i++) {
      customers.add(
        new Contact(
          LastName = CONTACT_LAST_NAME_PREFIX + i,
          MailingStreet = '415 Mission St',
          MailingCity = 'San Francisco',
          MailingStateCode = 'CA',
          MailingPostalCode = '94105',
          MailingCountryCode = 'US'
        )
      );
    }
    if (doInsert && !customers.isEmpty()) {
      insert customers;
    }
    return customers;
  }

  /**
   * Builds a Menu for the given storefront.
   * @param storefrontId The parent storefront Id
   * @param doInsert Whether to insert the record
   * @return The built (and optionally inserted) menu
   */
  public static Menu__c createMenu(Id storefrontId, Boolean doInsert) {
    Menu__c menu = new Menu__c(Storefront__c = storefrontId, Active__c = true);
    if (doInsert) {
      insert menu;
    }
    return menu;
  }

  /**
   * Builds Menu Item records for the given menu.
   * @param menuId The parent menu Id
   * @param count Number of menu items to build
   * @param doInsert Whether to insert the records
   * @return The built (and optionally inserted) menu items
   */
  public static List<Menu_Item__c> createMenuItems(Id menuId, Integer count, Boolean doInsert) {
    List<Menu_Item__c> menuItems = new List<Menu_Item__c>();
    for (Integer i = 0; i < count; i++) {
      menuItems.add(
        new Menu_Item__c(
          Name = MENU_ITEM_NAME_PREFIX + i,
          Menu__c = menuId,
          Price__c = MENU_ITEM_PRICE,
          Available__c = true
        )
      );
    }
    if (doInsert && !menuItems.isEmpty()) {
      insert menuItems;
    }
    return menuItems;
  }

  /**
   * Builds Order records for the given customer and storefront.
   * @param customerId The customer (Contact) Id
   * @param storefrontId The parent storefront Id
   * @param status The order status
   * @param count Number of orders to build
   * @param doInsert Whether to insert the records
   * @return The built (and optionally inserted) orders
   */
  public static List<Order__c> createOrders(
    Id customerId,
    Id storefrontId,
    String status,
    Integer count,
    Boolean doInsert
  ) {
    List<Order__c> orders = new List<Order__c>();
    for (Integer i = 0; i < count; i++) {
      orders.add(
        new Order__c(
          Customer__c = customerId,
          Storefront__c = storefrontId,
          Status__c = status,
          Order_Time__c = System.now()
        )
      );
    }
    if (doInsert && !orders.isEmpty()) {
      insert orders;
    }
    return orders;
  }

  /**
   * Builds Review records for the given storefront.
   * @param storefrontId The parent storefront Id
   * @param count Number of reviews to build
   * @param doInsert Whether to insert the records
   * @return The built (and optionally inserted) reviews
   */
  public static List<Review__c> createReviews(Id storefrontId, Integer count, Boolean doInsert) {
    List<Review__c> reviews = new List<Review__c>();
    for (Integer i = 0; i < count; i++) {
      reviews.add(
        new Review__c(
          Storefront__c = storefrontId,
          Rating__c = Math.mod(i, 5) + 1.0,
          Comments__c = 'Test review ' + i,
          Status__c = 'Published',
          Order_Date__c = Date.today().addDays(-i)
        )
      );
    }
    if (doInsert && !reviews.isEmpty()) {
      insert reviews;
    }
    return reviews;
  }

  /**
   * Builds mock Review records with fake IDs.
   * @param count Number of reviews to build
   * @return The built mock reviews
   */
  public static List<Review__c> createMockReviews(Integer count) {
    List<Review__c> reviews = new List<Review__c>();
    for (Integer i = 0; i < count; i++) {
      reviews.add(
        new Review__c(
          Id = getFakeId(Review__c.SObjectType),
          Rating__c = Math.mod(i, 5) + 1.0,
          Comments__c = 'Test review ' + i,
          Status__c = 'Published',
          Order_Date__c = Date.today().addDays(-i)
        )
      );
    }
    return reviews;
  }

  /**
   * Builds mock Storefront Hours of Operation records.
   * @param storefrontId The parent storefront Id
   * @param count Number of hours records to build (max 7 for days of week)
   * @return The built mock hours records
   */
  public static List<Storefront_Hours_of_Operation__c> createMockHours(Id storefrontId, Integer count) {
    List<Storefront_Hours_of_Operation__c> hours = new List<Storefront_Hours_of_Operation__c>();
    for (Integer i = 0; i < count && i < WEEK_DAYS.size(); i++) {
      hours.add(
        new Storefront_Hours_of_Operation__c(
          Storefront__c = storefrontId,
          Day_of_Week__c = WEEK_DAYS[i],
          Opening_Time__c = '09:00',
          Closing_Time__c = '17:00'
        )
      );
    }
    return hours;
  }

  /**
   * Builds mock Storefront records.
   * @param count Number of storefronts to build
   * @return The built mock storefronts
   */
  public static List<Storefront__c> createMockStorefronts(Integer count) {
    List<Storefront__c> storefronts = new List<Storefront__c>();
    for (Integer i = 0; i < count; i++) {
      storefronts.add(
        new Storefront__c(
          Name = 'Test Storefront ' + i,
          Description__c = 'Test Description ' + i,
          Cuisine__c = 'Test Cuisine',
          Status__c = 'Open'
        )
      );
    }
    return storefronts;
  }
}
