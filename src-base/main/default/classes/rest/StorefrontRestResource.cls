/**
 * REST API endpoint for searching Storefront records.
 * Exposes a paged and filtered storefront search at /services/apexrest/storefronts/v1/*
 */
@RestResource(urlMapping='/storefronts/v1/*')
global with sharing class StorefrontRestResource {
  /**
   * Searches for a paged and filtered list of storefronts.
   * GET /services/apexrest/storefronts/v1?searchKey=pizza&type=Restaurant&cuisine=Italian&minReviewScore=4&pageSize=9&pageNumber=1
   * Writes an ApiResponse JSON body to the response.
   */
  @HttpGet
  global static void doGet() {
    RestRequest req = RestContext.request;
    RestResponse res = RestContext.response;
    ApiResponse response;

    try {
      Integer minReviewScore = parseIntParam(req, 'minReviewScore');
      Integer pageSize = parseIntParam(req, 'pageSize');
      Integer pageNumber = parseIntParam(req, 'pageNumber');

      PagedResult pagedResult = new StorefrontService()
        .searchStorefronts(
          req.params.get('searchKey'),
          req.params.get('type'),
          req.params.get('cuisine'),
          minReviewScore,
          pageSize,
          pageNumber
        );

      res.statusCode = 200;
      response = new ApiResponse(true, 'Storefronts retrieved successfully.');
      response.data = pagedResult;
    } catch (TypeException e) {
      response = handleError(res, 400, 'Invalid numeric query parameter.');
    } catch (Exception e) {
      response = handleError(res, 500, e.getMessage());
    }

    res.addHeader('Content-Type', 'application/json');
    res.responseBody = Blob.valueOf(JSON.serialize(response));
  }

  private static Integer parseIntParam(RestRequest req, String paramName) {
    String paramValue = req.params.get(paramName);
    return String.isBlank(paramValue) ? null : Integer.valueOf(paramValue);
  }

  private static ApiResponse handleError(RestResponse res, Integer statusCode, String message) {
    res.statusCode = statusCode;
    return new ApiResponse(false, message);
  }

  /**
   * Standardized API response envelope for the storefront search endpoint.
   */
  global class ApiResponse {
    global Boolean success;
    global String message;
    global PagedResult data;

    /**
     * Creates an API response envelope.
     * @param success Whether the operation was successful
     * @param message Success or error message
     */
    global ApiResponse(Boolean success, String message) {
      this.success = success;
      this.message = message;
    }
  }
}
