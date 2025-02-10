public with sharing class CaseSubmitController {
    @AuraEnabled(cacheable=true)
    public static String getCaseStatus(Id caseId) {
        Case caseRecord = [SELECT Status FROM Case WHERE Id = :caseId LIMIT 1];
        return caseRecord.Status;
    }

    @AuraEnabled
    public static void submitCase(Id caseId) {
        try{
            Case caseRecord = [SELECT Id, Status FROM Case WHERE Id = :caseId LIMIT 1];
            if (caseRecord.Status == 'Submitted') {
                throw new AuraHandledException('This case has already been submitted.');
            }
            caseRecord.Status = 'Submitted';
            //caseRecord.Status = 'Changes Completed';
            Id readOnlyRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('IVF Application Read Only').getRecordTypeId();
            
            caseRecord.RecordTypeId =readOnlyRecordTypeId ;// Update the status
            update caseRecord;
          }
          catch (DmlException e) {
            List<String> errorMessages = new List<String>();

            for (Integer i = 0; i < e.getNumDml(); i++) {
                errorMessages.add(e.getDmlMessage(i));
            }
            throw new AuraHandledException(String.join(errorMessages, ' | '));
        }
            
    }
}