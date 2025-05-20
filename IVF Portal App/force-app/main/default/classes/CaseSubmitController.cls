public without sharing class CaseSubmitController {
    @AuraEnabled(cacheable=true)
    public static String getCaseStatus(Id caseId) {
        Case caseRecord = [SELECT Status FROM Case WHERE Id = :caseId LIMIT 1];
        return caseRecord.Status;
    }
    @AuraEnabled(cacheable=true)
    public static String getCaseRecordType(Id caseId) {
        Case casetype = [SELECT Status, RecordType.DeveloperName FROM Case WHERE Id = :caseId LIMIT 1];
        return casetype.RecordType.DeveloperName + '|' + casetype.Status;
    }
    
    @AuraEnabled
    public static void submitCase(Id caseId) {
        Bypass_Validation_Context__c bypassSetting = null;
        try{
            bypassSetting = Bypass_Validation_Context__c.getOrgDefaults();
            bypassSetting.Enabled__c = true;
            upsert bypassSetting;
            Case caseRecord = [SELECT Id, RecordTypeId,Status,DateOfApplicationSubmission__c,origin FROM Case WHERE Id = :caseId LIMIT 1];
            if(caseRecord.Status=='Draft')
            {
            caseRecord.Status = 'Submitted';
            caseRecord.DateOfApplicationSubmission__c=Date.Today();
            caseRecord.origin = 'Portal';
            }
            else if(caseRecord.Status=='Changes Requested')
            {
                caseRecord.Status = 'Changes Completed';
                Id readOnlyRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('IVF Application Read Only').getRecordTypeId();
                caseRecord.RecordTypeId =readOnlyRecordTypeId ;// Update the status
            }
            update caseRecord;
          }
          catch (DmlException e) {
            List<String> errorMessages = new List<String>();

            for (Integer i = 0; i < e.getNumDml(); i++) {
                errorMessages.add(e.getDmlMessage(i));
            }
            throw new AuraHandledException(String.join(errorMessages, ' | '));
        }
        finally {
            if (bypassSetting != null) {
                    bypassSetting.Enabled__c = false;
                    update bypassSetting;
            }
        }
            
    }
}