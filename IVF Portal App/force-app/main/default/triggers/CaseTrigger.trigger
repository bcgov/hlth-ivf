trigger CaseTrigger on Case (before update,after update) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        CaseTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        CaseTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}