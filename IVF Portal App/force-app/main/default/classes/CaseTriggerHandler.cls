public class CaseTriggerHandler {
    public static Id ivfTreatmentRtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('IVF Treatment').getRecordTypeId();
    public static void handleBeforeUpdate(List<Case> newList, Map<Id, Case> oldMap) {
        Map<Id, IVFFundingTier__c> fundingTiers = new Map<Id, IVFFundingTier__c>([SELECT Id, IncomeLevel__c, Funding_Amount__c FROM IVFFundingTier__c]);
        Set<String> phns=new Set<STring>();
        Map<String,Boolean> allowedPhns=new Map<String,Boolean>();
        for(Case c:newList)
        {
            //Funding Complete unchecked (case reopened for corrections) - clear the completion reason and date
            if(c.recordtypeId==ivfTreatmentRtId && c.FundingComplete__c==false && oldMap.get(c.Id).FundingComplete__c==true)
            {
                c.FundingCompleteReason__c=null;
                c.Funding_Complete_Date__c=null;
            }
            
            if(c.recordtypeId!=ivfTreatmentRtId){
                if(c.Status =='Submitted')
                {
                    if(c.Applicant1PersonalHealthNumber__c!=null)
                    {
                        phns.add(c.Applicant1PersonalHealthNumber__c);
                    }
                    if(c.Applicant2PersonalHealthNumber__c!=null)
                    {
                        phns.add(c.Applicant2PersonalHealthNumber__c);
                    }
                }
                if(c.Status =='Not Approved')
                {
                    c.Allow_Duplicate__c=True;
                }
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
        if(!phns.isempty())
        {
                List<Case> phncaseList=[Select Id,Status,Applicant1PersonalHealthNumber__c,Applicant2PersonalHealthNumber__c  from case where (Applicant1PersonalHealthNumber__c in:Phns OR Applicant2PersonalHealthNumber__c in: Phns) and id not in:oldmap.keyset()];
                for(Case existing:phnCaseList)
                {
                    if (existing.Status != 'Not Approved' && existing.Status != 'Draft') {
                        if (String.isNotBlank(existing.Applicant1PersonalHealthNumber__c)) {
                            AllowedPhns.put(existing.Applicant1PersonalHealthNumber__c, false);
                        }
                        if (String.isNotBlank(existing.Applicant2PersonalHealthNumber__c)) {
                            AllowedPhns.put(existing.Applicant2PersonalHealthNumber__c, false);
                        }
                    }
                    else
                    {
                        if (String.isNotBlank(existing.Applicant1PersonalHealthNumber__c)) {
                            AllowedPhns.put(existing.Applicant1PersonalHealthNumber__c, true);
                        }
                        if (String.isNotBlank(existing.Applicant2PersonalHealthNumber__c)) {
                            AllowedPhns.put(existing.Applicant2PersonalHealthNumber__c, true);
                        }
                        
                    }
                }
                System.debug('AllowedPhns'+AllowedPhns);
                for(Case c:newList)
                {
                     if(c.recordtypeId!=ivfTreatmentRtId && c.Status =='Submitted' && c.Allow_Duplicate__c==false){
                         if(!AllowedPhns.isempty())
                         {
                             if (String.isNotBlank(c.Applicant1PersonalHealthNumber__c) &&
                                AllowedPhns.containsKey(c.Applicant1PersonalHealthNumber__c) &&
                                AllowedPhns.get(c.Applicant1PersonalHealthNumber__c) == false) {
                                c.addError('An application has already been submitted for applicant 1 with PHN ('+ c.Applicant1PersonalHealthNumber__c+'). Please contact HLTH.');
                            }
                            if (String.isNotBlank(c.Applicant2PersonalHealthNumber__c) &&
                                AllowedPhns.containsKey(c.Applicant2PersonalHealthNumber__c) &&
                                AllowedPhns.get(c.Applicant2PersonalHealthNumber__c) == false) {
                                c.addError('An application has already been submitted for applicant 2 with PHN ('+ c.Applicant2PersonalHealthNumber__c+'). Please contact HLTH.');
                            }
                             if(!AllowedPhns.containskey(c.Applicant1PersonalHealthNumber__c) || (String.isNotBlank(c.Applicant1PersonalHealthNumber__c) && AllowedPhns.containskey(c.Applicant1PersonalHealthNumber__c) && AllowedPhns.get(c.Applicant1PersonalHealthNumber__c)))
                             {
                                 if(!AllowedPhns.containskey(c.Applicant2PersonalHealthNumber__c) ||(String.isNotBlank(c.Applicant2PersonalHealthNumber__c) && AllowedPhns.containskey(c.Applicant2PersonalHealthNumber__c) && AllowedPhns.get(c.Applicant2PersonalHealthNumber__c)))
                                 {
                                     c.Allow_Duplicate__c=true;
                                 }
                                 
                             }
                             
                         }
                     }
                
                }
        }
    }
    
    public static void handleAfterUpdate(List<Case> newList, Map<Id, Case> oldMap) {
        Map<Id, Decimal> treatmentBalances = new Map<Id, Decimal>();
        List<FeedItem> chatterPosts = new List<FeedItem>();
        Set<Id> treatmentIds = new Set<Id>();
        //Create Chatter post if case not approved
        for (Case newCase : newList) {
            Case oldCase = oldMap.get(newCase.Id);
            if(newCase.recordtypeId!=ivfTreatmentRtId && newCase.status!=oldCase.Status && newCase.Status=='Not Approved')
            {
                chatterPosts.add(new FeedItem(
                ParentId = newCase.Id,
                Body = 'Application moved to '+newCase.Status+'. Reason: ' + newCase.Not_Approved_Reason__c,
                CreatedById = UserInfo.getUserId(),
                Type       = 'TextPost',
                Visibility = 'AllUsers'
                ));
            }
            
        }
        if (!chatterPosts.isEmpty()) {
        insert chatterPosts;
        }
        
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
                Decimal availableBalance = calculateAvailableBalance(oldCase);

                if (availableBalance > 0) {
                    treatmentBalances.put(loaded.Id, availableBalance);
                }
            }
            // Case reopened: take back the unused balance that was returned to the clinic when funding was completed.
            // 'Funding utilized' cases had no balance left, so nothing was returned for them.
            else if (
                loaded.FundingComplete__c == false &&
                oldCase.FundingComplete__c == true &&
                oldCase.FundingCompleteReason__c != 'Funding utilized' &&
                loaded.RecordType.DeveloperName == 'IVFTreatment' &&
                loaded.ParentId != null
            ) {
                Decimal returnedBalance = calculateAvailableBalance(oldCase);
                if (returnedBalance > 0) {
                    treatmentBalances.put(loaded.Id, -returnedBalance);
                }
            }
        }
        
        if (!treatmentBalances.isEmpty()) {
            moveBalanceBackToClinicFromTreatment(treatmentBalances);
        }
    }
    
    private static Decimal calculateAvailableBalance(Case treatment) {
        Decimal availableBalance = 0;

        if (treatment.ApprovedTreatmentFunding__c != null && treatment.TotalTreatmentCost__c != null) {
            availableBalance = treatment.ApprovedTreatmentFunding__c - treatment.TotalTreatmentCost__c;

            if (treatment.TotalMedicationCost__c != null) {
                Decimal medCap = availableBalance;
                Decimal medUse = treatment.TotalMedicationCost__c;
                availableBalance -= Math.min(medUse, medCap);
            }
        }
        return availableBalance;
    }

    // Positive amounts are returned to the clinic, negative amounts are taken back from it
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
        Map<Id, ClinicFunding__c> toUpdate = new Map<Id, ClinicFunding__c>();
        
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
                    toUpdate.put(fund.Id, fund);
                    }
                }
            }
        }
        
        if (!toUpdate.isEmpty()) {
            update toUpdate.values();
        }
    }
}