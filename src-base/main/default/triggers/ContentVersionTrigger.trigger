trigger ContentVersionTrigger on ContentVersion(after insert) {
  if (Trigger.isAfter && Trigger.isInsert) {
    ContentVersionTriggerHandler.handleAfterInsert(Trigger.new);
  }
}
