/**
 * Invocable Action for retrieving a storefront by its name
 */
global with sharing class GetStorefrontFromNameAction {
  @TestVisible
  private static StorefrontService storefrontService = new StorefrontService();

  /**
   * Retrieves a storefront record by its name
   * @param inputs List of request objects containing storefront name
   * @return List of response objects containing the storefront data
   */
  @InvocableMethod(
    label='Get Storefront From Name'
    description='Retrieves a storefront record by its name'
    category='Storefront Management'
  )
  global static List<Output> getStorefrontFromName(List<Input> inputs) {
    List<Output> responses = new List<Output>();

    for (Input request : inputs) {
      Output response = new Output();
      try {
        response.storefront = storefrontService.getStorefrontFromName(request.storefrontName);
        response.storefrontId = response.storefront.Id;
        response.storefrontDetails = new StorefrontDetails(response.storefront);
        response.message = 'Storefront retrieved successfully';
        response.isSuccess = true;
      } catch (StorefrontService.StorefrontException e) {
        response.message = e.getMessage();
        response.isSuccess = false;
      }
      responses.add(response);
    }

    return responses;
  }

  /**
   * Input parameters for the invocable action
   */
  global class Input {
    @InvocableVariable(label='Storefront Name' description='The name of the storefront to retrieve' required=true)
    public String storefrontName;
  }

  /**
   * Response from the invocable action
   */
  global class Output {
    @InvocableVariable(label='Storefront' description='The retrieved storefront record')
    public Storefront__c storefront;

    @InvocableVariable(label='Storefront ID' description='The ID of the retrieved storefront')
    public String storefrontId;

    @InvocableVariable(label='Message' description='Success or error message')
    public String message;

    @InvocableVariable(label='Is Success' description='Indicates whether the storefront was retrieved successfully')
    public Boolean isSuccess;

    @InvocableVariable(
      label='Storefront Details'
      description='Display-ready storefront details, rendered as the storefront profile card widget'
    )
    public StorefrontDetails storefrontDetails;
  }

  /**
   * Display-ready storefront details. Widgets can't compute values, so labels are built here.
   */
  global class StorefrontDetails {
    public StorefrontDetails() {
    }
    public StorefrontDetails(Storefront__c storefront) {
      this.name = storefront.Name;
      this.description = storefront.Description__c;
      this.cuisine = storefront.Cuisine__c;
      this.status = storefront.Status__c;
      this.statusVariant = getStatusVariant(storefront.Status__c);
      this.ratingLabel = getRatingLabel(storefront.Average_Review_Score__c, storefront.Total_Reviews__c);
      this.address = getAddressLabel(storefront);
      this.phone = storefront.Phone__c;
    }

    @InvocableVariable
    public String name;
    @InvocableVariable
    public String description;
    @InvocableVariable
    public String cuisine;
    @InvocableVariable
    public String status;
    @InvocableVariable
    public String statusVariant;
    @InvocableVariable
    public String ratingLabel;
    @InvocableVariable
    public String address;
    @InvocableVariable
    public String phone;
  }

  @TestVisible
  private static String getStatusVariant(String status) {
    switch on status {
      when 'Active' {
        return 'success';
      }
      when 'Pending Activation' {
        return 'warning';
      }
      when 'Suspended', 'Closed' {
        return 'error';
      }
      when else {
        return 'secondary';
      }
    }
  }

  @TestVisible
  private static String getRatingLabel(Decimal averageScore, Decimal reviewCount) {
    if (averageScore == null || reviewCount == null || reviewCount == 0) {
      return 'No reviews yet';
    }
    Integer count = reviewCount.intValue();
    return averageScore.setScale(1) + ' (' + count + (count == 1 ? ' review)' : ' reviews)');
  }

  @TestVisible
  private static String getAddressLabel(Storefront__c storefront) {
    List<String> parts = new List<String>();
    for (
      String part : new List<String>{
        storefront.Address__Street__s,
        storefront.Address__City__s,
        storefront.Address__StateCode__s
      }
    ) {
      if (String.isNotBlank(part)) {
        parts.add(part);
      }
    }
    return String.join(parts, ', ');
  }
}
