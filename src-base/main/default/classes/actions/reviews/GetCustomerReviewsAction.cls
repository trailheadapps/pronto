/**
 * Invocable Action for retrieving customer reviews for a given storefront
 */
global with sharing class GetCustomerReviewsAction {
  @TestVisible
  private static ReviewService reviewService = new ReviewService();

  /**
   * Retrieves customer reviews for a specific storefront
   * @param inputs List of request objects containing storefront ID
   * @return List of response objects containing the reviews and metadata
   */
  @InvocableMethod(
    label='Get Customer Reviews'
    description='Retrieves customer reviews for a specific storefront'
    category='Customer Reviews Management'
  )
  global static List<Output> getCustomerReviews(List<Input> inputs) {
    List<Output> responses = new List<Output>();

    for (Input request : inputs) {
      Output response = new Output();
      try {
        // Retrieve reviews via the service layer
        List<Review__c> reviews = reviewService.getReviewsForStorefront(request.storefrontId);

        // Format the response
        response.isSuccess = true;
        response.reviews = new ReviewWrapper(reviews);
        response.message = 'Successfully retrieved ' + reviews.size() + ' reviews';
      } catch (Exception e) {
        response.isSuccess = false;
        response.message = 'Error retrieving customer reviews: ' + e.getMessage();
        response.reviews = null;
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
      label='Storefront ID'
      description='The ID of the storefront to retrieve reviews for'
      required=true
    )
    public String storefrontId;
  }

  /**
   * Response from the invocable action
   */
  global class Output {
    @InvocableVariable(label='Success' description='Whether the operation was successful')
    public Boolean isSuccess;

    @InvocableVariable(label='Message' description='Success or error message')
    public String message;

    @InvocableVariable(label='Reviews' description='Customer reviews and related metadata')
    public ReviewWrapper reviews;
  }

  global class ReviewWrapper {
    public ReviewWrapper() {
    }
    public ReviewWrapper(List<Review__c> reviewRecords) {
      this.items = new List<ReviewItemWrapper>();
      Decimal ratingTotal = 0;
      for (Review__c reviewRecord : reviewRecords) {
        this.items.add(new ReviewItemWrapper(reviewRecord));
        ratingTotal += reviewRecord.Rating__c == null ? 0 : reviewRecord.Rating__c;
      }
      this.reviewCount = reviewRecords.size();
      this.averageRating = this.reviewCount == 0 ? 0 : ratingTotal / this.reviewCount;
    }

    @InvocableVariable
    public Integer reviewCount;
    @InvocableVariable
    public Decimal averageRating;
    @InvocableVariable
    public List<ReviewItemWrapper> items;
  }

  global class ReviewItemWrapper {
    public ReviewItemWrapper() {
    }
    public ReviewItemWrapper(Review__c reviewRecord) {
      this.customerName = reviewRecord.Customer__r?.Name;
      this.rating = reviewRecord.Rating__c;
      this.orderDate = reviewRecord.Order_Date__c;
      this.comments = reviewRecord.Comments__c;
    }

    @InvocableVariable
    public String customerName;
    @InvocableVariable
    public Decimal rating;
    @InvocableVariable
    public Date orderDate;
    @InvocableVariable
    public String comments;
  }
}
