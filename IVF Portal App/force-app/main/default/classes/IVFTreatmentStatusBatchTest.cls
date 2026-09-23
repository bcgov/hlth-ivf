@isTest
private class IVFTreatmentStatusBatchTest {
    private static Id treatmentRecordTypeId() {
        return Schema.SObjectType.Case.getRecordTypeInfosByName().get('IVF Treatment').getRecordTypeId();
    }

    private static Id applicationRecordTypeId() {
        return Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('IVF_Application').getRecordTypeId();
    }

    private static Case createApplication(Date submissionDate) {
        Case application = new Case(
            RecordTypeId = applicationRecordTypeId(),
            Status = 'Draft',
            Subject = 'Treatment status test application',
            DateOfApplicationSubmission__c = submissionDate
        );
        insert application;
        return application;
    }

    private static Case createTreatment(Case application, Date fundingStartDate, Date treatmentStartDate, Decimal medicationCost) {
        Case treatment = new Case(
            RecordTypeId = treatmentRecordTypeId(),
            ParentId = application.Id,
            Subject = 'Treatment status test',
            Treatmentstartdate__c = fundingStartDate,
            Treatment_Start_Date__c = treatmentStartDate,
            ApprovedTreatmentFunding__c = 1000,
            TotalMedicationCost__c = medicationCost,
            Medication_Start_Date__c = medicationCost != null && medicationCost > 0
                ? treatmentStartDate
                : null
        );
        insert treatment;
        return treatment;
    }

    @isTest
    static void updatesTreatmentStatuses() {
        Date today = Date.today();
        Case application = createApplication(IVFTreatmentStatusService.APPLICATION_CUTOFF);
        Case notStarted = createTreatment(application, today.addMonths(-4), null, null);
        Case started = createTreatment(application, today.addMonths(-1), today, null);
        Case expired = createTreatment(application, today.addMonths(-8), today.addMonths(-7), 1);

        Test.startTest();
        Database.executeBatch(new IVFTreatmentStatusBatch(), 200);
        Test.stopTest();

        Map<Id, Case> treatments = new Map<Id, Case>([
            SELECT Treatment_Status__c
            FROM Case
            WHERE Id IN :new Set<Id>{notStarted.Id, started.Id, expired.Id}
        ]);
        System.assertEquals('Not Started 3 Months Timeline Exceeded', treatments.get(notStarted.Id).Treatment_Status__c);
        System.assertEquals('Started', treatments.get(started.Id).Treatment_Status__c);
        System.assertEquals('Funding Validity Exceeded', treatments.get(expired.Id).Treatment_Status__c);
    }

    @isTest
    static void excludesApplicationsBeforeCutoff() {
        Case application = createApplication(IVFTreatmentStatusService.APPLICATION_CUTOFF.addDays(-1));
        Case treatment = createTreatment(application, Date.today().addMonths(-4), null, null);

        Test.startTest();
        Database.executeBatch(new IVFTreatmentStatusBatch(), 200);
        Test.stopTest();

        treatment = [SELECT Treatment_Status__c FROM Case WHERE Id = :treatment.Id];
        System.assertEquals('Not Started', treatment.Treatment_Status__c);
    }

    @isTest
    static void schedulesDailyJob() {
        Test.startTest();
        String jobId = System.schedule(
            'Test Daily IVF Treatment Status Update',
            '0 0 1 1 1 ? 2099',
            new IVFTreatmentStatusBatch()
        );
        Test.stopTest();
        System.assertNotEquals(null, jobId);
    }
}