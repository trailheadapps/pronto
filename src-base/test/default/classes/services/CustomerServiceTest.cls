/**
 * Test class for CustomerService.
 */
@IsTest
private class CustomerServiceTest {
  @TestSetup
  static void setupTestData() {
    TestDataFactory.createCustomers(CustomerService.DEFAULT_CUSTOMER_LIMIT + 1, true);
  }

  @IsTest
  static void shouldGetCustomers_WithDefaultLimit_WhenRecordLimitIsNoSet() {
    // Given
    CustomerService service = new CustomerService();

    // When
    Test.startTest();
    List<Contact> results = service.getCustomers(null);
    Test.stopTest();

    // Then
    Assert.areEqual(
      CustomerService.DEFAULT_CUSTOMER_LIMIT,
      results.size(),
      'Should return all customers within the default limit'
    );
  }

  @IsTest
  static void shouldGetCustomers_WithCustomLimit() {
    // Given
    CustomerService service = new CustomerService();

    // When
    Test.startTest();
    List<Contact> results = service.getCustomers(2);
    Test.stopTest();

    // Then
    Assert.areEqual(2, results.size(), 'Should return exactly 2 customers');
  }

  @IsTest
  static void shouldGetCustomerFromName_WhenSingleMatch() {
    // Given
    CustomerService service = new CustomerService();
    String name = TestDataFactory.CONTACT_LAST_NAME_PREFIX + '0';

    // When
    Test.startTest();
    Contact result = service.getCustomerFromName(name);
    Test.stopTest();

    // Then
    Assert.isNotNull(result, 'Should return a customer');
    Assert.areEqual(name, result.Name, 'Should return the correct customer');
  }

  @IsTest
  static void shouldGetCustomerFromName_WhenExactMatchAmongMultiple() {
    // Given
    CustomerService service = new CustomerService();
    // Setup created customers 0-10, so querying '...1' matches both '1' and '10' via LIKE
    String exactName = TestDataFactory.CONTACT_LAST_NAME_PREFIX + '1';

    // When
    Test.startTest();
    Contact result = service.getCustomerFromName(exactName);
    Test.stopTest();

    // Then
    Assert.areEqual(exactName, result.Name, 'Should return the exact match');
  }

  @IsTest
  static void shouldThrowException_WhenMultipleMatchesButNoExactMatch() {
    // Given
    CustomerService service = new CustomerService();
    // Query just the prefix, which matches all customers but none exactly
    String prefix = TestDataFactory.CONTACT_LAST_NAME_PREFIX;

    // When / Then
    Test.startTest();
    try {
      service.getCustomerFromName(prefix);
      Assert.fail('Should have thrown CustomerException');
    } catch (CustomerService.CustomerException e) {
      Assert.isTrue(e.getMessage().contains('Multiple customers found'), 'Exception should indicate multiple matches');
    }
    Test.stopTest();
  }

  @IsTest
  static void shouldThrowException_WhenNoCustomerFound() {
    // Given
    CustomerService service = new CustomerService();
    String nonExistentName = 'Nonexistent Customer';

    // When / Then
    Test.startTest();
    try {
      service.getCustomerFromName(nonExistentName);
      Assert.fail('Should have thrown CustomerException');
    } catch (CustomerService.CustomerException e) {
      Assert.isTrue(e.getMessage().contains('No customer found'), 'Exception should indicate customer not found');
    }
    Test.stopTest();
  }

  @IsTest
  static void shouldThrowException_WhenCustomerNameIsBlank() {
    // Given
    CustomerService service = new CustomerService();

    // When / Then
    Test.startTest();
    try {
      service.getCustomerFromName('');
      Assert.fail('Should have thrown CustomerException');
    } catch (CustomerService.CustomerException e) {
      Assert.isTrue(e.getMessage().contains('must be provided'), 'Exception should indicate name is required');
    }
    Test.stopTest();
  }
}
