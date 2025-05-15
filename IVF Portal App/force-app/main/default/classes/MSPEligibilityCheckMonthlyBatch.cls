public class MSPEligibilityCheckMonthlyBatch implements Database.Batchable<SObject>, Database.AllowsCallouts,Schedulable {
    private Integer batchSize;

    public MSPEligibilityCheckMonthlyBatch(Integer size) {
        this.batchSize = size;
    }
    public static Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id,FundingComplete__c,ParentId, Parent.Applicant1PersonalHealthNumber__c,Parent.Applicant1Date__c, Parent.Applicant1MSPStatus__c,Parent.Applicant2PersonalHealthNumber__c,Parent.Applicant2Date__c, Parent.Applicant2MSPStatus__c,Parent.Patient1PersonalHealthNumber__c,Parent.Patient1Date__c,Parent.Patient1MSPStatus__c, Parent.Patient2PersonalHealthNumber__c,Parent.Patient2Date__c,Parent.Patient2MSPStatus__c,Parent.Patient3PersonalHealthNumber__c,Parent.Patient3Date__c,Parent.Patient3MSPStatus__c,Parent.MonthlyMSPStatusCheck__c,Parent.DateOfLastMSPBatchJobRun__c
            FROM Case WHERE Parent.status='approved' and FundingComplete__c=false 
        ]);
    }
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Case> updatedCases = new List<Case>();
        Map<String,String> MSPStatusMap=new Map<String,String>();
        Set<String> phnSet = new Set<String>();
        Map<Id, Case> updateCaseMap = new Map<Id, Case>();

        for (Case c : (List<Case>) scope) {
            addPhnToSet(phnSet, c.Parent.Applicant1PersonalHealthNumber__c);
            addPhnToSet(phnSet, c.Parent.Applicant2PersonalHealthNumber__c);
            addPhnToSet(phnSet, c.Parent.Patient1PersonalHealthNumber__c);
            addPhnToSet(phnSet, c.Parent.Patient2PersonalHealthNumber__c);
            addPhnToSet(phnSet, c.Parent.Patient3PersonalHealthNumber__c);
        }


        for (String phn : phnSet) {

            try {
                if (!String.isBlank(phn)) {
                    String responseBody = LRAIntegrationHandler.callLRAAPI('', 'GET', '', phn);
                  
                    if (responseBody != null) {
                        if (responseBody == 'MSP_ACTIVE') {
                            MSPStatusMap.put(phn, 'Enrolled');
                        } else if (responseBody == 'MSP_INACTIVE') {
                            MSPStatusMap.put(phn, 'Not Enrolled');
                        }
                        else {
                            MSPStatusMap.put(phn, 'Invalid or Failed');
                        }
                    } 
                }
            } catch (Exception e) {
                System.debug('Exception while Integration for MSP Check'+e.getmessage());
            }
        }

        for (Case c : (List<Case>)scope) {
            if (c.ParentId == null || c.Parent == null) continue;

            Case updateCase = new Case(Id = c.ParentId);
            Boolean eligibilityChanged = false;

            eligibilityChanged = updateField(updateCase, 'Applicant1', c.Parent.Applicant1PersonalHealthNumber__c, c.Parent.Applicant1MSPStatus__c, mspStatusMap) || eligibilityChanged;
            eligibilityChanged = updateField(updateCase, 'Applicant2', c.Parent.Applicant2PersonalHealthNumber__c, c.Parent.Applicant2MSPStatus__c, mspStatusMap) || eligibilityChanged;
            eligibilityChanged = updateField(updateCase, 'Patient1', c.Parent.Patient1PersonalHealthNumber__c, c.Parent.Patient1MSPStatus__c, mspStatusMap) || eligibilityChanged;
            eligibilityChanged = updateField(updateCase, 'Patient2', c.Parent.Patient2PersonalHealthNumber__c, c.Parent.Patient2MSPStatus__c, mspStatusMap) || eligibilityChanged;
            eligibilityChanged = updateField(updateCase, 'Patient3', c.Parent.Patient3PersonalHealthNumber__c, c.Parent.Patient3MSPStatus__c, mspStatusMap) || eligibilityChanged;

            updateCase.MonthlyMSPStatusCheck__c = eligibilityChanged ? 'Review required - Change in eligibility' : 'Review not required - No change in eligibility';
            updateCase.DateOfLastMSPBatchJobRun__c = System.today();

            updateCaseMap.put(updateCase.Id, updateCase);
        }

        // Update records
        if (!updateCaseMap.isEmpty()) {
            try {
                Database.update(updateCaseMap.values(), false);
            } catch (Exception e) {
                System.debug('Exception while updating cases: ' + e.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('MSPEligibilityCheckMonthlyBatch is completed.');
    }
    public void execute(SchedulableContext sc) {
        
        Database.executeBatch(new MSPEligibilityCheckMonthlyBatch(batchSize), batchSize);
    }
    private void addPhnToSet(Set<String> phnSet, String phn) {
        if (!String.isBlank(phn)) {
            phnSet.add(phn);
        }
    }
    private Boolean updateField(Case updateCase, String fieldPrefix, String phn, String currentStatus, Map<String, String> mspStatusMap) {
        if (String.isBlank(phn)) return false;

        String status = mspStatusMap.get(phn);
        Boolean hasChanged = false;

        if (status != null) {
            if (status != 'Invalid or Failed') {
                updateCase.put(fieldPrefix + 'MSPStatus__c', status);
                updateCase.put(fieldPrefix + 'Date__c', System.today());
                if (currentStatus != status) {
                    hasChanged = true;
                }
            } else {
                updateCase.put(fieldPrefix + 'MSPStatus__c', '');
                updateCase.put(fieldPrefix + 'Date__c', null);
                if (!String.isBlank(currentStatus)) {
                    hasChanged = true;
                }
            }
        }
        return hasChanged;
    }
}