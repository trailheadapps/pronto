trigger OrderItemTrigger on Order_Item__c(after insert, after update, after delete, after undelete) {
  // Handle after insert events
  if (Trigger.isAfter && Trigger.isInsert) {
    OrderTotalAmountTriggerHandler.handleAfterInsert(Trigger.new);
  }

  // Handle after update events
  if (Trigger.isAfter && Trigger.isUpdate) {
    OrderTotalAmountTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.old);
  }

  // Handle after delete events
  if (Trigger.isAfter && Trigger.isDelete) {
    OrderTotalAmountTriggerHandler.handleAfterDelete(Trigger.old);
  }

  // Handle after undelete events
  if (Trigger.isAfter && Trigger.isUndelete) {
    OrderTotalAmountTriggerHandler.handleAfterUndelete(Trigger.new);
  }
}
