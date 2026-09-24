@IsTest
private class GetCustomerFromNameActionTest {
  private class MockCustomerService extends CustomerService {
    public Boolean shouldThrowException = false;
    public String exceptionMessage;
    public Contact mockCustomer;

    public override Contact getCustomerFromName(String customerName) {
      if (shouldThrowException) {
        throw new CustomerService.CustomerException(exceptionMessage);
      }
      return mockCustomer;
    }
  }

  @IsTest
  static void testGetCustomerFromName_Success() {
    Contact mockCustomer = new Contact(
      Id = TestDataFactory.getFakeId(Contact.SObjectType),
      LastName = 'Test Customer',
      Email = 'test@example.com'
    );

    MockCustomerService mockService = new MockCustomerService();
    mockService.mockCustomer = mockCustomer;
    GetCustomerFromNameAction.customerService = mockService;

    GetCustomerFromNameAction.Input input = new GetCustomerFromNameAction.Input();
    input.customerName = 'Test Customer';
    List<GetCustomerFromNameAction.Input> inputs = new List<GetCustomerFromNameAction.Input>{ input };

    Test.startTest();
    List<GetCustomerFromNameAction.Output> outputs = GetCustomerFromNameAction.getCustomerFromName(inputs);
    Test.stopTest();

    System.assertEquals(1, outputs.size());
    GetCustomerFromNameAction.Output output = outputs[0];
    System.assertEquals(true, output.isSuccess);
    System.assertEquals('Customer retrieved successfully', output.message);
    System.assertNotEquals(null, output.customer);
    System.assertEquals('Test Customer', output.customer.LastName);
  }

  @IsTest
  static void testGetCustomerFromName_Failure() {
    MockCustomerService mockService = new MockCustomerService();
    mockService.shouldThrowException = true;
    mockService.exceptionMessage = 'No customer found with name: NonExistent';
    GetCustomerFromNameAction.customerService = mockService;

    GetCustomerFromNameAction.Input input = new GetCustomerFromNameAction.Input();
    input.customerName = 'NonExistent';
    List<GetCustomerFromNameAction.Input> inputs = new List<GetCustomerFromNameAction.Input>{ input };

    Test.startTest();
    List<GetCustomerFromNameAction.Output> outputs = GetCustomerFromNameAction.getCustomerFromName(inputs);
    Test.stopTest();

    System.assertEquals(1, outputs.size());
    GetCustomerFromNameAction.Output output = outputs[0];
    System.assertEquals(false, output.isSuccess);
    System.assertEquals('No customer found with name: NonExistent', output.message);
    System.assertEquals(null, output.customer);
  }
}
