public class CaseTriggerHandler {
    public static Id ivfTreatmentRtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('IVF Treatment').getRecordTypeId();
    public static void handleBeforeUpdate(List<Case> newList, Map<Id, Case> oldMap) {
        Map<Id, IVFFundingTier__c> fundingTiers = new Map<Id, IVFFundingTier__c>([SELECT Id, IncomeLevel__c, Funding_Amount__c FROM IVFFundingTier__c]);
        for(Case c:newList)
        {
            if(c.recordtypeId!=ivfTreatmentRtId){
                if(c.TotalHouseholdIncome__c!=null && c.TotalHouseholdIncome__c!=oldmap.get(c.id).TotalHouseholdIncome__c)                {
                    Decimal income = c.TotalHouseholdIncome__c;
                    Boolean matched = false;
                    for(IVFFundingTier__c tier:fundingTiers.values())
                    {
                        if(String.isNotBlank(tier.IncomeLevel__c)){
                            String cleanedIncome = tier.IncomeLevel__c.replace('$','').replace(',','').trim();
                            if(cleanedIncome.toUpperCase().contains('K')){
                                cleanedIncome = cleanedIncome.toUpperCase().replace('K','000');
                            }
                            Decimal minVal, maxVal;
                            if(cleanedIncome.contains('-')){
                                List<String> parts = cleanedIncome.split('-',2);
                                minVal = Decimal.valueOf(parts[0].trim());
                                maxVal = Decimal.valueOf(parts[1].trim());
                            }
                            else if(cleanedIncome.endsWith('+')){
                                minVal = Decimal.valueOf(cleanedIncome.replace('+','').trim());
                                maxVal = null;
                            }
                            if(
                                (minVal == null || income >= minVal) &&
                                (maxVal == null || income <= maxVal)
                            ){
                                System.debug('minIncome'+minVal +'maxIncome'+maxVal);
                                    c.FundingTier__c = tier.Id;
                                    c.ApprovedTreatmentFunding__c = tier.Funding_Amount__c;
                                    System.debug('FundingTier__c'+c.FundingTier__c+'ApprovedTreatmentFunding__c'+c.ApprovedTreatmentFunding__c);
                                    matched = true;
                                    break;
                            }

                        }
                    }
                }
                if(c.TotalHouseholdIncome__c==null){
                    c.FundingTier__c=null;
                    c.ApprovedTreatmentFunding__c=null;
                }
            }
        }
    }
    
    public static void handleAfterUpdate(List<Case> newList, Map<Id, Case> oldMap) {
        Map<Id, Decimal> treatmentBalances = new Map<Id, Decimal>();
        Set<Id> treatmentIds = new Set<Id>();
        
        Map<Id, Case> loadedCases = new Map<Id, Case>([
            SELECT Id, RecordType.DeveloperName, FundingComplete__c, ParentId
            FROM Case
            WHERE Id IN :newList
        ]);
        
        for (Case newCase : newList) {
            Case oldCase = oldMap.get(newCase.Id);
            Case loaded = loadedCases.get(newCase.Id);
            
            if (
                loaded.FundingComplete__c == true &&
                oldCase.FundingComplete__c != true &&
                loaded.RecordType.DeveloperName == 'IVFTreatment' &&
                loaded.ParentId != null
            ) {
                Decimal availableBalance = 0;
                
                if (oldCase.ApprovedTreatmentFunding__c != null && oldCase.TotalTreatmentCost__c != null) {
                    availableBalance = oldCase.ApprovedTreatmentFunding__c - oldCase.TotalTreatmentCost__c;
                    
                    if (oldCase.TotalMedicationCost__c != null) {
                        Decimal medCap = availableBalance;
                        Decimal medUse = oldCase.TotalMedicationCost__c;
                        availableBalance -= Math.min(medUse, medCap);
                    }
                }
                
                if (availableBalance > 0) {
                    treatmentBalances.put(loaded.Id, availableBalance);
                }
            }
        }
        
        if (!treatmentBalances.isEmpty()) {
            moveBalanceBackToClinicFromTreatment(treatmentBalances);
        }
    }
    
    public static void moveBalanceBackToClinicFromTreatment(Map<Id, Decimal> treatmentBalances) {
        if (treatmentBalances.isEmpty()) return;
        
        // Step 1: Get treatment records with ParentId
        List<Case> treatments = [
            SELECT Id, ParentId
            FROM Case
            WHERE Id IN :treatmentBalances.keySet()
            AND ParentId != null
        ];
        
        // Step 2: Get IVF Applications with record type filtering
        Set<Id> parentIds = new Set<Id>();
        for (Case t : treatments) {
            parentIds.add(t.ParentId);
        }
        
        Map<Id, Case> parentApps = new Map<Id, Case>([
            SELECT Id, Clinic_Funding__c, RecordType.DeveloperName,DateOfApplicationSubmission__c
            FROM Case
            WHERE Id IN :parentIds
            AND RecordType.DeveloperName IN ('IVF_Application', 'IVF_Application_Read_Only')
        ]);
        system.debug('parentApps' +parentApps);
        
        // Step 3: Load associated Clinic Funding records
        Set<Id> fundingIds = new Set<Id>();
        for (Case app : parentApps.values()) {
            if (app.Clinic_Funding__c != null) {
                fundingIds.add(app.Clinic_Funding__c);
            }
        }
        
        Map<Id, ClinicFunding__c> fundingMap = new Map<Id, ClinicFunding__c>([
            SELECT Id, AvailableBalance__c,FYStartDate__c,FYEndDate__c
            FROM ClinicFunding__c
            WHERE Id IN :fundingIds
        ]);
        
        // Step 4: Increment available balance
        List<ClinicFunding__c> toUpdate = new List<ClinicFunding__c>();
        
        for (Case treatment : treatments) {
            Decimal oldBalance = treatmentBalances.get(treatment.Id);
            Case parent = parentApps.get(treatment.ParentId);
            
            if (parent != null && parent.Clinic_Funding__c != null) {
                ClinicFunding__c fund = fundingMap.get(parent.Clinic_Funding__c);
                if (fund != null) {
                    System.debug('Fund Before: ' + fund.AvailableBalance__c);
                    if(parent.DateOfApplicationSubmission__c >= fund.FYStartDate__c && parent.DateOfApplicationSubmission__c <= fund.FYEndDate__c){
                    fund.AvailableBalance__c += oldBalance;
                    System.debug('Fund After: ' + fund.AvailableBalance__c);
                    toUpdate.add(fund);
                    }
                }
            }
        }
        
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}