@IsTest
private class GetCustomersActionTest {
  private class MockCustomerService extends CustomerService {
    public Boolean shouldThrowException = false;
    public String exceptionMessage = 'Mock exception';

    public override List<Contact> getCustomers(Integer recordLimit) {
      if (shouldThrowException) {
        throw new CustomerException(exceptionMessage);
      }
      return TestDataFactory.createCustomers(10, false);
    }
  }

  @IsTest
  static void testGetCustomers_Success() {
    MockCustomerService mockService = new MockCustomerService();
    GetCustomersAction.customerService = mockService;

    GetCustomersAction.Input request = new GetCustomersAction.Input();
    request.recordLimit = 10;

    Test.startTest();
    List<GetCustomersAction.Output> results = GetCustomersAction.getCustomers(
      new List<GetCustomersAction.Input>{ request }
    );
    Test.stopTest();

    System.assertEquals(1, results.size());
    GetCustomersAction.Output result = results[0];
    System.assertEquals(true, result.isSuccess);
    System.assertEquals(10, result.customers.size());
    System.assertEquals('Found 10 customers.', result.message);
  }

  @IsTest
  static void testGetCustomers_Failure() {
    MockCustomerService mockService = new MockCustomerService();
    mockService.shouldThrowException = true;
    mockService.exceptionMessage = 'Database connection failed';
    GetCustomersAction.customerService = mockService;

    GetCustomersAction.Input request = new GetCustomersAction.Input();
    request.recordLimit = 10;

    Test.startTest();
    List<GetCustomersAction.Output> results = GetCustomersAction.getCustomers(
      new List<GetCustomersAction.Input>{ request }
    );
    Test.stopTest();

    System.assertEquals(1, results.size());
    GetCustomersAction.Output result = results[0];
    System.assertEquals(false, result.isSuccess);
    System.assertEquals(null, result.customers);
    System.assert(result.message.contains('Error retrieving customers'));
    System.assert(result.message.contains('Database connection failed'));
  }
}
