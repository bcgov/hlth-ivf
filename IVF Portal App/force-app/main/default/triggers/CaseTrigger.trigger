trigger CaseTrigger on Case (before insert, before update, after update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        IVFTreatmentStatusService.applyStatus(Trigger.new);
    }
    if (Trigger.isBefore && Trigger.isUpdate) {
        CaseTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
        IVFTreatmentStatusService.applyStatus(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        CaseTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}