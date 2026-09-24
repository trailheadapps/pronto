@IsTest
private class StorefrontRestResourceTest {
  @TestSetup
  static void setupTestData() {
    TestDataFactory.createStorefronts(3, true);
  }

  @IsTest
  static void shouldReturnStorefronts_WhenNoParamsProvided() {
    // Given
    RestRequest req = new RestRequest();
    req.requestURI = '/services/apexrest/storefronts/v1';
    req.httpMethod = 'GET';
    RestContext.request = req;
    RestContext.response = new RestResponse();

    // When
    Test.startTest();
    StorefrontRestResource.doGet();
    Test.stopTest();

    // Then
    Map<String, Object> response = parseResponse();
    Assert.isTrue((Boolean) response.get('success'), 'Should return a successful response');
    Assert.areEqual(200, RestContext.response.statusCode, 'Should return HTTP 200');
    Map<String, Object> data = (Map<String, Object>) response.get('data');
    Assert.isNotNull(data, 'Should return paged result data');
    Assert.areEqual(3, (Integer) data.get('totalItemCount'), 'Should count all storefronts created in setup');
  }

  @IsTest
  static void shouldReturnFilteredStorefronts_WhenQueryParamsProvided() {
    // Given
    String searchKey = TestDataFactory.STOREFRONT_NAME_PREFIX + '0';
    RestRequest req = new RestRequest();
    req.requestURI = '/services/apexrest/storefronts/v1';
    req.httpMethod = 'GET';
    req.params.put('searchKey', searchKey);
    req.params.put('pageSize', '5');
    req.params.put('pageNumber', '1');
    RestContext.request = req;
    RestContext.response = new RestResponse();

    // When
    Test.startTest();
    StorefrontRestResource.doGet();
    Test.stopTest();

    // Then
    Map<String, Object> response = parseResponse();
    Assert.isTrue((Boolean) response.get('success'), 'Should return a successful response');
    Map<String, Object> data = (Map<String, Object>) response.get('data');
    Assert.areEqual(
      1,
      (Integer) data.get('totalItemCount'),
      'Should count only the storefront matching the search key'
    );
    Assert.areEqual(5, (Integer) data.get('pageSize'), 'Should apply the custom page size');
  }

  @IsTest
  static void shouldReturnBadRequest_WhenNumericParamIsInvalid() {
    // Given
    RestRequest req = new RestRequest();
    req.requestURI = '/services/apexrest/storefronts/v1';
    req.httpMethod = 'GET';
    req.params.put('pageSize', 'abc');
    RestContext.request = req;
    RestContext.response = new RestResponse();

    // When
    Test.startTest();
    StorefrontRestResource.doGet();
    Test.stopTest();

    // Then
    Map<String, Object> response = parseResponse();
    Assert.isFalse((Boolean) response.get('success'), 'Should return an unsuccessful response');
    Assert.areEqual(400, RestContext.response.statusCode, 'Should return HTTP 400 for an invalid numeric parameter');
  }

  private static Map<String, Object> parseResponse() {
    return (Map<String, Object>) JSON.deserializeUntyped(RestContext.response.responseBody.toString());
  }
}
