trigger AiJobRunTrigger on AiJobRun(after update) {
  if (Trigger.isAfter && Trigger.isUpdate) {
    AiJobRunTriggerHandler.handleAfterUpdate(Trigger.old, Trigger.new);
  }
}
