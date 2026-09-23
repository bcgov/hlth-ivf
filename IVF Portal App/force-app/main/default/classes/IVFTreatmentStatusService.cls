public with sharing class IVFTreatmentStatusService {
    public static final Date APPLICATION_CUTOFF = Date.newInstance(2026, 4, 1);

    public static void applyStatus(List<Case> treatments) {
        Set<Id> parentIds = new Set<Id>();
        for (Case treatment : treatments) {
            if (treatment.RecordTypeId == CaseTriggerHandler.ivfTreatmentRtId && treatment.ParentId != null) {
                parentIds.add(treatment.ParentId);
            }
        }

        Map<Id, Case> applications = new Map<Id, Case>();
        if (!parentIds.isEmpty()) {
            applications = new Map<Id, Case>([
                SELECT Id, DateOfApplicationSubmission__c
                FROM Case
                WHERE Id IN :parentIds
            ]);
        }

        Date today = System.today();
        for (Case treatment : treatments) {
            if (treatment.RecordTypeId != CaseTriggerHandler.ivfTreatmentRtId) {
                continue;
            }

            Case application = applications.get(treatment.ParentId);
            if (application == null || application.DateOfApplicationSubmission__c == null
                || application.DateOfApplicationSubmission__c < APPLICATION_CUTOFF) {
                continue;
            }

            if (treatment.Treatment_Start_Date__c != null
                && today > treatment.Treatment_Start_Date__c.addMonths(6)
                && treatment.TotalTreatmentandMedication__c != null
                && treatment.TotalTreatmentandMedication__c > 0) {
                treatment.Treatment_Status__c = 'Funding Validity Exceeded';
            } else if (treatment.Treatment_Start_Date__c != null
                && treatment.Treatmentstartdate__c != null
                && treatment.Treatment_Start_Date__c <= treatment.Treatmentstartdate__c.addMonths(3)) {
                treatment.Treatment_Status__c = 'Started';
            } else if (treatment.Treatment_Start_Date__c == null
                && treatment.Treatmentstartdate__c != null
                && today > treatment.Treatmentstartdate__c.addMonths(3)) {
                treatment.Treatment_Status__c = 'Not Started 3 Months Timeline Exceeded';
            } else {
                treatment.Treatment_Status__c = 'Not Started';
            }
        }
    }
}