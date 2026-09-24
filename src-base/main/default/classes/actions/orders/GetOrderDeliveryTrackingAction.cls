/**
 * Invocable action to get the delivery tracking information for an order
 */
global with sharing class GetOrderDeliveryTrackingAction {
  @TestVisible
  private static OrderService orderService = new OrderService();

  /**
   * Get the delivery tracking information for an order
   * @param inputs List of Input parameters
   * @return List of Output results
   */
  @InvocableMethod(
    label='Get Delivery Tracking'
    description='Get the delivery tracking information for an order'
    category='Order Management'
  )
  global static List<Output> getDeliveryTracking(List<Input> inputs) {
    List<Output> responses = new List<Output>();
    for (Input request : inputs) {
      if (String.isNotEmpty(request.customerId)) {
        orderService.assertCustomerHasAccessToOrder(request.customerId, request.orderId);
      }
      Output response = new Output();
      response.deliveryTracking = getDeliveryTracking(request.orderId);
      responses.add(response);
    }
    return responses;
  }

  private static DeliveryTracking getDeliveryTracking(Id orderId) {
    List<MapMarker> mapMarkers = new List<MapMarker>{
      new MapMarker(37.7897441, -122.4021046, 'Storefront Location'),
      new MapMarker(37.7875941, -122.400459, 'Driver Location'),
      new MapMarker(37.7835, -122.403, 'Delivery Location')
    };

    DeliveryTracking deliveryTracking = new DeliveryTracking();
    deliveryTracking.orderId = orderId;
    deliveryTracking.status = 'In Progress';
    deliveryTracking.mapMarkers = mapMarkers;
    return deliveryTracking;
  }

  /**
   * Input wrapper for the invocable action
   */
  global class Input {
    @InvocableVariable(label='Customer ID' description='The ID of the customer who placed the order')
    public Id customerId;

    @InvocableVariable(required=true label='Order ID' description='The ID of the order to track')
    public Id orderId;
  }

  /**
   * Output wrapper for the invocable action
   */
  global class Output {
    @InvocableVariable(label='Delivery Tracking' description='The delivery tracking information')
    public DeliveryTracking deliveryTracking;
  }

  /**
   * Delivery tracking information for an order
   */
  public class DeliveryTracking {
    public Id orderId;
    public String status;
    public List<MapMarker> mapMarkers;
  }

  /**
   * A map marker used to represent a location on the delivery tracking map
   */
  public class MapMarker {
    public Decimal latitude;
    public Decimal longitude;
    public String title;

    /**
     * Creates a map marker.
     * @param latitude Latitude of the map marker
     * @param longitude Longitude of the map marker
     * @param title Title of the map marker
     */
    public MapMarker(Decimal latitude, Decimal longitude, String title) {
      this.latitude = latitude;
      this.longitude = longitude;
      this.title = title;
    }
  }
}
