/**
 * Trigger handler that keeps Order__c.Total_Amount__c in sync with its Order_Item__c records.
 */
public class OrderTotalAmountTriggerHandler {
  /**
   * Updates the Total_Amount__c field on Order__c records based on the sum of related Order_Item__c Total_Amount__c values
   * @param orderIds Set of Order__c record IDs to update
   */
  private static void updateOrderTotalAmounts(Set<Id> orderIds) {
    // Recalculates a derived rollup that end users don't edit directly; this trigger handler
    // must run in system mode so totals stay in sync regardless of the triggering user's FLS.
    // Query for Order_Item__c records related to the specified orders
    List<Order_Item__c> orderItems = [
      SELECT Order__c, Total_Amount__c
      FROM Order_Item__c
      WHERE Order__c IN :orderIds
      WITH SYSTEM_MODE
    ];

    // Group order items by Order__c and calculate totals
    Map<Id, Decimal> orderTotalMap = new Map<Id, Decimal>();
    for (Order_Item__c item : orderItems) {
      Id orderId = item.Order__c;
      Decimal itemAmount = item.Total_Amount__c != null ? item.Total_Amount__c : 0;

      if (orderTotalMap.containsKey(orderId)) {
        orderTotalMap.put(orderId, orderTotalMap.get(orderId) + itemAmount);
      } else {
        orderTotalMap.put(orderId, itemAmount);
      }
    }

    // Query for Order__c records to update
    List<Order__c> ordersToUpdate = [
      SELECT Id, Total_Amount__c
      FROM Order__c
      WHERE Id IN :orderIds
      WITH SYSTEM_MODE
    ];

    // Update the Total_Amount__c field
    for (Order__c order : ordersToUpdate) {
      Decimal totalAmount = orderTotalMap.get(order.Id);
      if (totalAmount != null) {
        order.Total_Amount__c = totalAmount;
      } else {
        order.Total_Amount__c = 0;
      }
    }

    // Update the orders
    if (!ordersToUpdate.isEmpty()) {
      try {
        update as system ordersToUpdate;
      } catch (Exception e) {
        // Log error and re-throw to maintain trigger behavior
        System.debug(LoggingLevel.ERROR, 'Error updating Order Total_Amount__c: ' + e.getMessage());
        throw e;
      }
    }
  }

  /**
   * Handles after insert events for Order_Item__c records
   * @param newOrderItems List of newly inserted Order_Item__c records
   */
  public static void handleAfterInsert(List<Order_Item__c> newOrderItems) {
    Set<Id> orderIds = new Set<Id>();
    for (Order_Item__c item : newOrderItems) {
      orderIds.add(item.Order__c);
    }
    updateOrderTotalAmounts(orderIds);
  }

  /**
   * Handles after update events for Order_Item__c records
   * @param newOrderItems List of updated Order_Item__c records
   * @param oldOrderItems List of old Order_Item__c records
   */
  public static void handleAfterUpdate(List<Order_Item__c> newOrderItems, List<Order_Item__c> oldOrderItems) {
    Set<Id> orderIds = new Set<Id>();

    for (Integer i = 0; i < newOrderItems.size(); i++) {
      Order_Item__c newItem = newOrderItems[i];
      Order_Item__c oldItem = oldOrderItems[i];

      // Check if Total_Amount__c changed or Order__c changed
      if (newItem.Total_Amount__c != oldItem.Total_Amount__c || newItem.Order__c != oldItem.Order__c) {
        orderIds.add(newItem.Order__c);
        if (oldItem.Order__c != newItem.Order__c) {
          orderIds.add(oldItem.Order__c);
        }
      }
    }

    if (!orderIds.isEmpty()) {
      updateOrderTotalAmounts(orderIds);
    }
  }

  /**
   * Handles after delete events for Order_Item__c records
   * @param oldOrderItems List of deleted Order_Item__c records
   */
  public static void handleAfterDelete(List<Order_Item__c> oldOrderItems) {
    Set<Id> orderIds = new Set<Id>();
    for (Order_Item__c item : oldOrderItems) {
      orderIds.add(item.Order__c);
    }
    updateOrderTotalAmounts(orderIds);
  }

  /**
   * Handles after undelete events for Order_Item__c records
   * @param newOrderItems List of undeleted Order_Item__c records
   */
  public static void handleAfterUndelete(List<Order_Item__c> newOrderItems) {
    Set<Id> orderIds = new Set<Id>();
    for (Order_Item__c item : newOrderItems) {
      orderIds.add(item.Order__c);
    }
    updateOrderTotalAmounts(orderIds);
  }
}
