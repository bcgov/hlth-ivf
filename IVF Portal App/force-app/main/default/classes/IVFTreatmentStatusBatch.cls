public with sharing class IVFTreatmentStatusBatch implements Database.Batchable<SObject>, Schedulable {
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id, RecordTypeId, ParentId, Treatment_Start_Date__c,
                Treatmentstartdate__c, TotalTreatmentandMedication__c
            FROM Case
            WHERE RecordType.DeveloperName = 'IVFTreatment'
                AND ParentId != null
                AND Parent.DateOfApplicationSubmission__c >= :IVFTreatmentStatusService.APPLICATION_CUTOFF
        ]);
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        List<Case> treatments = (List<Case>) scope;
        IVFTreatmentStatusService.applyStatus(treatments);
        update treatments;
    }

    public void finish(Database.BatchableContext context) {
    }

    public void execute(SchedulableContext context) {
        Database.executeBatch(new IVFTreatmentStatusBatch(), 200);
    }
}