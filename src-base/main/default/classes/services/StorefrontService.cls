/**
 * Service layer for storefront operations. Encapsulates all SOQL related
 * to Storefront__c records so that controllers and other callers remain
 * free of data-access logic.
 */
public virtual with sharing class StorefrontService {
  private final static Integer DEFAULT_STOREFRONT_LIMIT = 10;
  private final static Integer DEFAULT_PAGE_SIZE = 9;

  /**
   * Retrieves a storefront record by its name.
   * @param storefrontName The name of the storefront to retrieve.
   * @return The matching `Storefront__c` record.
   */
  public virtual Storefront__c getStorefrontFromName(String storefrontName) {
    String cleanedName = cleanStorefrontName(storefrontName);
    if (String.isBlank(cleanedName)) {
      throw new StorefrontException('A storefront name must be provided.');
    }

    // Any apostrophe style (' or a typographic one) matches any other via the single-character wildcard
    String likeName = '%' + straightenQuotes(cleanedName).replace('\'', '_') + '%';
    List<Storefront__c> storefronts = [
      SELECT
        Id,
        Name,
        Description__c,
        Cuisine__c,
        Address__c,
        Address__Street__s,
        Address__City__s,
        Address__StateCode__s,
        Phone__c,
        Thumbnail__c,
        Status__c,
        Type__c,
        Average_Review_Score__c,
        Total_Reviews__c,
        Review_Summary__c
      FROM Storefront__c
      WHERE Name LIKE :likeName
      WITH USER_MODE
    ];

    if (storefronts.isEmpty()) {
      throw new StorefrontException('No storefront found with name: ' + cleanedName);
    }

    // Single match: return it directly
    if (storefronts.size() == 1) {
      return storefronts[0];
    }

    // Multiple matches: resolve to the exact name match or surface the options
    Set<String> storefrontNames = new Set<String>();
    for (Storefront__c storefront : storefronts) {
      if (straightenQuotes(storefront.Name).equalsIgnoreCase(straightenQuotes(cleanedName))) {
        return storefront;
      }
      storefrontNames.add(storefront.Name);
    }

    // No exact match: surface the possible matches
    throw new StorefrontException(
      'Multiple storefronts found. Possible matches: ' + String.join(storefrontNames, ', ')
    );
  }

  /**
   * Trims whitespace and strips wrapping quotes or trailing punctuation that
   * callers (including LLM agents) often include around a name, such as
   * "Trailside Deli," or 'Trailside Deli'.
   */
  private static String cleanStorefrontName(String storefrontName) {
    if (storefrontName == null) {
      return null;
    }
    String edgeChars = '[\\s"\'`\\u2018\\u2019\\u201C\\u201D.,;:!?]+';
    return storefrontName.replaceAll('^' + edgeChars + '|' + edgeChars + '$', '');
  }

  /**
   * Converts typographic apostrophes and quotes to a straight apostrophe so
   * names like Artisan's and Artisan\u2019s compare as equal.
   */
  private static String straightenQuotes(String value) {
    return value.replaceAll('[`\\u2018\\u2019\\u201B\\u00B4]', '\'');
  }

  /**
   * Retrieves the first storefronts, ordered by name.
   * @param recordLimit Optional maximum number of storefronts to return. Defaults to 10.
   * @return A list of matching `Storefront__c` records.
   */
  public virtual List<Storefront__c> getStorefronts(Integer recordLimit) {
    Integer resolvedLimit = (recordLimit == null || recordLimit <= 0) ? DEFAULT_STOREFRONT_LIMIT : recordLimit;

    return [
      SELECT
        Id,
        Name,
        Description__c,
        Cuisine__c,
        Address__c,
        Phone__c,
        Thumbnail__c,
        Status__c,
        Type__c,
        Average_Review_Score__c,
        Total_Reviews__c,
        Review_Summary__c
      FROM Storefront__c
      WITH USER_MODE
      ORDER BY Name
      LIMIT :resolvedLimit
    ];
  }

  /**
   * Retrieves a paged and filtered list of storefronts.
   * @param searchKey String used for searching on storefront name and city
   * @param type Storefront type
   * @param cuisine Storefront cuisine
   * @param minReviewScore Minimum review score
   * @param pageSize Number of storefronts per page
   * @param pageNumber Page number
   * @return PagedResult object holding the paged and filtered list of storefronts
   * @example
   * PagedResult result = new StorefrontService().searchStorefronts('pizza', null, null, null, 9, 1);
   */
  public virtual PagedResult searchStorefronts(
    String searchKey,
    String type,
    String cuisine,
    Integer minReviewScore,
    Integer pageSize,
    Integer pageNumber
  ) {
    // Normalize inputs
    Integer safePageSize = pageSize ?? DEFAULT_PAGE_SIZE;
    Integer safePageNumber = pageNumber ?? 1;
    String searchPattern = '%' + searchKey + '%';
    Integer offset = (safePageNumber - 1) * safePageSize;

    // Prepare filter conditions
    List<String> conditions = new List<String>();
    if (!String.isBlank(searchKey)) {
      conditions.add('(Name LIKE :searchPattern OR Address__City__s LIKE :searchPattern)');
    }
    if (!String.isBlank(type)) {
      conditions.add('Type__c = :type');
    }
    if (!String.isBlank(cuisine)) {
      conditions.add('Cuisine__c = :cuisine');
    }
    if (minReviewScore != null) {
      conditions.add('Average_Review_Score__c >= :minReviewScore');
    }

    // Count records
    String countQuery = 'SELECT COUNT() FROM Storefront__c ';
    if (conditions.size() > 0) {
      countQuery += 'WHERE ' + String.join(conditions, ' AND ');
    }
    countQuery += ' WITH USER_MODE';
    Integer totalItemCount = Database.countQuery(countQuery);

    // Retrieve records
    String query = 'SELECT Id, Name, Account__c, Address__City__s, Average_Review_Score__c, Description__c, Menu_Count__c, Phone__c, Primary_Contact__c, Status__c, Total_Reviews__c, Total_Score__c, Type__c, Thumbnail__c FROM Storefront__c ';
    if (conditions.size() > 0) {
      query += 'WHERE ' + String.join(conditions, ' AND ');
    }
    query += ' WITH USER_MODE' + ' ORDER BY Name' + ' LIMIT :safePageSize' + ' OFFSET :offset';
    List<Storefront__c> storefronts = Database.query(query);

    // Return paginated results
    PagedResult result = new PagedResult();
    result.pageSize = safePageSize;
    result.pageNumber = safePageNumber;
    result.totalItemCount = totalItemCount;
    result.records = storefronts;
    return result;
  }

  /**
   * Retrieves the hours of operation for a storefront by its Id.
   * @param storefrontId The Id of the storefront whose hours of operation are retrieved
   * @return The hours of operation for the storefront, ordered by opening time
   * @throws StorefrontException if storefrontId is null
   */
  public virtual List<Storefront_Hours_of_Operation__c> getStorefrontHours(Id storefrontId) {
    if (storefrontId == null) {
      throw new StorefrontException('A storefront ID must be provided.');
    }

    return [
      SELECT Id, Day_of_Week__c, Opening_Time__c, Closing_Time__c, Storefront__c
      FROM Storefront_Hours_of_Operation__c
      WHERE Storefront__c = :storefrontId
      WITH USER_MODE
      ORDER BY Opening_Time__c
    ];
  }

  /**
   * Retrieves the available menu items for a storefront by its Id.
   * Menu items are resolved through their parent Menu's Storefront lookup and
   * only records flagged as available are returned.
   * @param storefrontId The Id of the storefront whose menu items are retrieved
   * @return The available menu items for the storefront
   * @throws StorefrontException if storefrontId is null
   * @example
   * List<Menu_Item__c> items = new StorefrontService().getMenuItems(storefrontId);
   */
  public virtual List<Menu_Item__c> getMenuItems(Id storefrontId) {
    if (storefrontId == null) {
      throw new StorefrontException('A storefront ID must be provided.');
    }

    return [
      SELECT Id, Name, Description__c, Price__c, Calories__c, Image_URL__c, Available__c, Menu__c
      FROM Menu_Item__c
      WHERE Menu__r.Storefront__c = :storefrontId AND Available__c = TRUE
      WITH USER_MODE
      ORDER BY Name
    ];
  }

  /**
   * Exception thrown when a storefront operation cannot be completed.
   */
  public class StorefrontException extends Exception {
  }
}
