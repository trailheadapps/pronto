/**
 * Test class for StorefrontService.
 */
@IsTest
private class StorefrontServiceTest {
  @TestSetup
  static void setupTestData() {
    List<Storefront__c> storefronts = TestDataFactory.createStorefronts(3, true);
    TestDataFactory.createWeekdayHours(storefronts[0].Id, true);
    Menu__c menu = TestDataFactory.createMenu(storefronts[0].Id, true);
    TestDataFactory.createMenuItems(menu.Id, 4, true);
  }

  @IsTest
  static void shouldGetStorefrontFromName_WhenSingleMatch() {
    // Given
    StorefrontService service = new StorefrontService();
    String name = TestDataFactory.STOREFRONT_NAME_PREFIX + '0';

    // When
    Test.startTest();
    Storefront__c result = service.getStorefrontFromName(name);
    Test.stopTest();

    // Then
    Assert.isNotNull(result, 'Should return a storefront');
    Assert.areEqual(name, result.Name, 'Should return the correct storefront');
  }

  @IsTest
  static void shouldGetStorefrontFromName_WhenApostropheStyleDiffers() {
    // Given
    StorefrontService service = new StorefrontService();
    String curlyApostrophe = String.fromCharArray(new List<Integer>{ 8217 });
    insert new Storefront__c(Name = 'Artisan' + curlyApostrophe + 's Edge Uptown');

    // When
    Test.startTest();
    Storefront__c result = service.getStorefrontFromName('Artisan\'s Edge Uptown');
    Test.stopTest();

    // Then
    Assert.areEqual(
      'Artisan' + curlyApostrophe + 's Edge Uptown',
      result.Name,
      'Should match across apostrophe styles'
    );
  }

  @IsTest
  static void shouldGetStorefrontFromName_WhenNameHasWrappingQuotesAndPunctuation() {
    // Given
    StorefrontService service = new StorefrontService();
    insert new Storefront__c(Name = 'Trailside Deli');
    String quotedName =
      String.fromCharArray(new List<Integer>{ 8220 }) +
      'Trailside Deli,' +
      String.fromCharArray(new List<Integer>{ 8221 });

    // When
    Test.startTest();
    Storefront__c result = service.getStorefrontFromName(quotedName);
    Test.stopTest();

    // Then
    Assert.areEqual('Trailside Deli', result.Name, 'Should ignore wrapping quotes and trailing punctuation');
  }

  @IsTest
  static void shouldGetStorefrontFromName_WhenExactMatchAmongMultiple() {
    // Given
    StorefrontService service = new StorefrontService();
    // Create storefronts 10 and 1, so querying '...1' matches both via LIKE
    Storefront__c sf10 = new Storefront__c(Name = TestDataFactory.STOREFRONT_NAME_PREFIX + '10');
    insert sf10;
    String exactName = TestDataFactory.STOREFRONT_NAME_PREFIX + '1';

    // When
    Test.startTest();
    Storefront__c result = service.getStorefrontFromName(exactName);
    Test.stopTest();

    // Then
    Assert.areEqual(exactName, result.Name, 'Should return the exact match');
  }

  @IsTest
  static void shouldThrowException_WhenMultipleMatchesButNoExactMatch() {
    // Given
    StorefrontService service = new StorefrontService();
    // Query just the prefix, which matches all storefronts but none exactly
    String prefix = TestDataFactory.STOREFRONT_NAME_PREFIX;

    // When / Then
    Test.startTest();
    try {
      service.getStorefrontFromName(prefix);
      Assert.fail('Should have thrown StorefrontException');
    } catch (StorefrontService.StorefrontException e) {
      Assert.isTrue(
        e.getMessage().contains('Multiple storefronts found'),
        'Exception should indicate multiple matches'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void shouldThrowException_WhenNoStorefrontFound() {
    // Given
    StorefrontService service = new StorefrontService();
    String nonExistentName = 'Nonexistent Storefront';

    // When / Then
    Test.startTest();
    try {
      service.getStorefrontFromName(nonExistentName);
      Assert.fail('Should have thrown StorefrontException');
    } catch (StorefrontService.StorefrontException e) {
      Assert.isTrue(e.getMessage().contains('No storefront found'), 'Exception should indicate storefront not found');
    }
    Test.stopTest();
  }

  @IsTest
  static void shouldThrowException_WhenStorefrontNameIsBlank() {
    // Given
    StorefrontService service = new StorefrontService();

    // When / Then
    Test.startTest();
    try {
      service.getStorefrontFromName('');
      Assert.fail('Should have thrown StorefrontException');
    } catch (StorefrontService.StorefrontException e) {
      Assert.isTrue(e.getMessage().contains('must be provided'), 'Exception should indicate name is required');
    }
    Test.stopTest();
  }

  @IsTest
  static void shouldGetStorefronts_WithDefaultLimit() {
    // Given
    StorefrontService service = new StorefrontService();

    // When
    Test.startTest();
    List<Storefront__c> results = service.getStorefronts(null);
    Test.stopTest();

    // Then
    Assert.isTrue(results.size() <= 10, 'Should return at most 10 storefronts (default limit)');
    Assert.isTrue(results.size() > 0, 'Should return some storefronts');
  }

  @IsTest
  static void shouldGetStorefronts_WithCustomLimit() {
    // Given
    StorefrontService service = new StorefrontService();

    // When
    Test.startTest();
    List<Storefront__c> results = service.getStorefronts(2);
    Test.stopTest();

    // Then
    Assert.areEqual(2, results.size(), 'Should return exactly 2 storefronts');
  }

  @IsTest
  static void shouldGetStorefronts_ApplyDefaultWhenInvalidLimit() {
    // Given
    StorefrontService service = new StorefrontService();

    // When
    Test.startTest();
    List<Storefront__c> results = service.getStorefronts(0);
    Test.stopTest();

    // Then
    Assert.isTrue(results.size() <= 10, 'Should apply default limit when invalid limit provided');
  }

  @IsTest
  static void shouldGetStorefrontHours_WhenHoursExist() {
    // Given
    StorefrontService service = new StorefrontService();
    Storefront__c storefront = [
      SELECT Id
      FROM Storefront__c
      WHERE Name = :TestDataFactory.STOREFRONT_NAME_PREFIX + '0'
      LIMIT 1
    ];

    // When
    Test.startTest();
    List<Storefront_Hours_of_Operation__c> results = service.getStorefrontHours(storefront.Id);
    Test.stopTest();

    // Then
    Assert.areEqual(7, results.size(), 'Should return hours for all 7 days');
    for (Storefront_Hours_of_Operation__c hours : results) {
      Assert.areEqual(storefront.Id, hours.Storefront__c, 'All hours should belong to the storefront');
      Assert.isNotNull(hours.Day_of_Week__c, 'Should include day of week');
      Assert.isNotNull(hours.Opening_Time__c, 'Should include opening time');
      Assert.isNotNull(hours.Closing_Time__c, 'Should include closing time');
    }
  }

  @IsTest
  static void shouldReturnEmptyList_WhenStorefrontHasNoHours() {
    // Given
    StorefrontService service = new StorefrontService();
    Storefront__c storefront = [
      SELECT Id
      FROM Storefront__c
      WHERE Name = :TestDataFactory.STOREFRONT_NAME_PREFIX + '1'
      LIMIT 1
    ];

    // When
    Test.startTest();
    List<Storefront_Hours_of_Operation__c> results = service.getStorefrontHours(storefront.Id);
    Test.stopTest();

    // Then
    Assert.areEqual(0, results.size(), 'Should return empty list when no hours exist');
  }

  @IsTest
  static void shouldThrowException_WhenStorefrontHoursIdIsNull() {
    // Given
    StorefrontService service = new StorefrontService();

    // When / Then
    Test.startTest();
    try {
      service.getStorefrontHours(null);
      Assert.fail('Should have thrown StorefrontException');
    } catch (StorefrontService.StorefrontException e) {
      Assert.isTrue(e.getMessage().contains('must be provided'), 'Exception should indicate ID is required');
    }
    Test.stopTest();
  }

  @IsTest
  static void shouldGetMenuItems_WhenItemsExist() {
    // Given
    StorefrontService service = new StorefrontService();
    Storefront__c storefront = [
      SELECT Id
      FROM Storefront__c
      WHERE Name = :TestDataFactory.STOREFRONT_NAME_PREFIX + '0'
      LIMIT 1
    ];

    // When
    Test.startTest();
    List<Menu_Item__c> results = service.getMenuItems(storefront.Id);
    Test.stopTest();

    // Then
    Assert.areEqual(4, results.size(), 'Should return all available menu items for the storefront');
    for (Menu_Item__c menuItem : results) {
      Assert.isTrue(menuItem.Available__c, 'Only available menu items should be returned');
      Assert.isNotNull(menuItem.Name, 'Should include menu item name');
      Assert.isNotNull(menuItem.Menu__c, 'Should include parent menu');
    }
  }

  @IsTest
  static void shouldExcludeUnavailableItems_WhenGettingMenuItems() {
    // Given
    StorefrontService service = new StorefrontService();
    Storefront__c storefront = [
      SELECT Id
      FROM Storefront__c
      WHERE Name = :TestDataFactory.STOREFRONT_NAME_PREFIX + '0'
      LIMIT 1
    ];
    List<Menu_Item__c> items = [SELECT Id FROM Menu_Item__c LIMIT 1];
    items[0].Available__c = false;
    update items;

    // When
    Test.startTest();
    List<Menu_Item__c> results = service.getMenuItems(storefront.Id);
    Test.stopTest();

    // Then
    Assert.areEqual(3, results.size(), 'Should exclude unavailable menu items');
  }

  @IsTest
  static void shouldReturnEmptyList_WhenStorefrontHasNoMenuItems() {
    // Given
    StorefrontService service = new StorefrontService();
    Storefront__c storefront = [
      SELECT Id
      FROM Storefront__c
      WHERE Name = :TestDataFactory.STOREFRONT_NAME_PREFIX + '1'
      LIMIT 1
    ];

    // When
    Test.startTest();
    List<Menu_Item__c> results = service.getMenuItems(storefront.Id);
    Test.stopTest();

    // Then
    Assert.areEqual(0, results.size(), 'Should return empty list when no menu items exist');
  }

  @IsTest
  static void shouldThrowException_WhenMenuItemsStorefrontIdIsNull() {
    // Given
    StorefrontService service = new StorefrontService();

    // When / Then
    Test.startTest();
    try {
      service.getMenuItems(null);
      Assert.fail('Should have thrown StorefrontException');
    } catch (StorefrontService.StorefrontException e) {
      Assert.isTrue(e.getMessage().contains('must be provided'), 'Exception should indicate ID is required');
    }
    Test.stopTest();
  }

  @IsTest
  static void shouldsearchStorefronts_WithDefaultPagination() {
    // Given
    StorefrontService service = new StorefrontService();

    // When
    Test.startTest();
    PagedResult result = service.searchStorefronts(null, null, null, null, null, null);
    Test.stopTest();

    // Then
    Assert.areEqual(9, result.pageSize, 'Should apply the default page size');
    Assert.areEqual(1, result.pageNumber, 'Should apply the default page number');
    Assert.areEqual(3, result.totalItemCount, 'Should count all storefronts created in setup');
    Assert.areEqual(3, result.records.size(), 'Should return all storefronts created in setup');
  }

  @IsTest
  static void shouldsearchStorefronts_WhenSearchKeyMatchesName() {
    // Given
    StorefrontService service = new StorefrontService();
    String searchKey = TestDataFactory.STOREFRONT_NAME_PREFIX + '0';

    // When
    Test.startTest();
    PagedResult result = service.searchStorefronts(searchKey, null, null, null, null, null);
    Test.stopTest();

    // Then
    Assert.areEqual(1, result.totalItemCount, 'Should only count the storefront matching the search key');
    Storefront__c matched = (Storefront__c) result.records[0];
    Assert.areEqual(searchKey, matched.Name, 'Should return the storefront matching the search key');
  }

  @IsTest
  static void shouldsearchStorefronts_WhenTypeFilterApplied() {
    // Given
    StorefrontService service = new StorefrontService();
    insert new List<Storefront__c>{
      new Storefront__c(Name = 'Bakery Storefront', Type__c = 'Bakery'),
      new Storefront__c(Name = 'Restaurant Storefront', Type__c = 'Restaurant')
    };

    // When
    Test.startTest();
    PagedResult result = service.searchStorefronts(null, 'Restaurant', null, null, null, null);
    Test.stopTest();

    // Then
    Assert.areEqual(1, result.totalItemCount, 'Should only count storefronts matching the type filter');
    Storefront__c matched = (Storefront__c) result.records[0];
    Assert.areEqual('Restaurant Storefront', matched.Name, 'Should return the storefront matching the type filter');
  }

  @IsTest
  static void shouldsearchStorefronts_WhenCuisineFilterApplied() {
    // Given
    StorefrontService service = new StorefrontService();
    insert new List<Storefront__c>{
      new Storefront__c(Name = 'Italian Storefront', Cuisine__c = 'Italian'),
      new Storefront__c(Name = 'Mexican Storefront', Cuisine__c = 'Mexican')
    };

    // When
    Test.startTest();
    PagedResult result = service.searchStorefronts(null, null, 'Italian', null, null, null);
    Test.stopTest();

    // Then
    Assert.areEqual(1, result.totalItemCount, 'Should only count storefronts matching the cuisine filter');
    Storefront__c matched = (Storefront__c) result.records[0];
    Assert.areEqual('Italian Storefront', matched.Name, 'Should return the storefront matching the cuisine filter');
  }

  @IsTest
  static void shouldsearchStorefronts_WhenMinReviewScoreFilterApplied() {
    // Given
    StorefrontService service = new StorefrontService();
    List<Storefront__c> storefronts = new List<Storefront__c>{
      new Storefront__c(Name = 'Low Score Storefront'),
      new Storefront__c(Name = 'High Score Storefront')
    };
    insert storefronts;
    // Average_Review_Score__c is a roll-up (Total_Score__c / Total_Reviews__c) derived from Review__c ratings
    insert new List<Review__c>{
      new Review__c(
        Storefront__c = storefronts[0].Id,
        Rating__c = 1,
        Status__c = 'Published',
        Order_Date__c = Date.today()
      ),
      new Review__c(
        Storefront__c = storefronts[0].Id,
        Rating__c = 2,
        Status__c = 'Published',
        Order_Date__c = Date.today()
      ),
      new Review__c(
        Storefront__c = storefronts[1].Id,
        Rating__c = 5,
        Status__c = 'Published',
        Order_Date__c = Date.today()
      ),
      new Review__c(
        Storefront__c = storefronts[1].Id,
        Rating__c = 5,
        Status__c = 'Published',
        Order_Date__c = Date.today()
      )
    };

    // When
    Test.startTest();
    PagedResult result = service.searchStorefronts(null, null, null, 4, null, null);
    Test.stopTest();

    // Then
    Assert.areEqual(1, result.totalItemCount, 'Should only count storefronts meeting the minimum review score');
    Storefront__c matched = (Storefront__c) result.records[0];
    Assert.areEqual(
      'High Score Storefront',
      matched.Name,
      'Should return the storefront meeting the minimum review score'
    );
  }

  @IsTest
  static void shouldsearchStorefronts_WithCustomPageSizeAndPageNumber() {
    // Given
    StorefrontService service = new StorefrontService();

    // When
    Test.startTest();
    PagedResult result = service.searchStorefronts(null, null, null, null, 2, 2);
    Test.stopTest();

    // Then
    Assert.areEqual(2, result.pageSize, 'Should apply the custom page size');
    Assert.areEqual(2, result.pageNumber, 'Should apply the custom page number');
    Assert.areEqual(3, result.totalItemCount, 'Should count all storefronts created in setup');
    Assert.areEqual(1, result.records.size(), 'Should return the remaining storefront on the second page');
  }

  @IsTest
  static void shouldsearchStorefronts_WhenNoMatchesFound() {
    // Given
    StorefrontService service = new StorefrontService();

    // When
    Test.startTest();
    PagedResult result = service.searchStorefronts('Nonexistent Storefront', null, null, null, null, null);
    Test.stopTest();

    // Then
    Assert.areEqual(0, result.totalItemCount, 'Should count no matches');
    Assert.areEqual(0, result.records.size(), 'Should return no records');
  }
}
