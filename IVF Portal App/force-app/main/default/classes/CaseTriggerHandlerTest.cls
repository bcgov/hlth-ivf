@isTest
public class CaseTriggerHandlerTest {     
    @testSetup
    static void setupTestData() {
        Account testClinic = new Account(Name = 'Test Clinic');
        insert testClinic;
        
        Id ivfAppRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'IVF_Application' AND SObjectType = 'Case' LIMIT 1].Id;
        Id ivfTreatmentRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'IVFTreatment' AND SObjectType = 'Case' LIMIT 1].Id;
        
        ClinicFunding__c clinicFunding = new ClinicFunding__c(
            Clinic__c = testClinic.Id, 
            AvailableBalance__c = 10000
        );
        insert clinicFunding;
        
        IVFFundingTier__c testTier = new IVFFundingTier__c(
            Name = 'Tier 1',
            IncomeLevel__c = '0-50000',     
            Funding_Amount__c = 7000
        );
        insert testTier;
        Case ivfApp = new Case(
            RecordTypeId = ivfAppRTId,
            Status = 'Draft',
            Clinic_Funding__c = clinicFunding.Id,
            Subject = 'IVF Application Test',      
            ApprovedTreatmentFunding__c = 7000
        );
        insert ivfApp;
        
        // Step 5: Create IVF Treatment Case (child)
        Case treatment = new Case(
            RecordTypeId = ivfTreatmentRTId,
            ParentId = ivfApp.Id,
            FundingComplete__c = false,
            ApprovedTreatmentFunding__c = 7000,
            TotalMedicationCost__c = 2000,
            Subject = 'IVF Treatment Test'
        );
        insert treatment;
    }
    
    @isTest
    static void testFundingBalanceReturnedToClinic() {
        Case treatment = [SELECT Id, FundingComplete__c FROM Case WHERE Subject = 'IVF Treatment Test' LIMIT 1];
        treatment.FundingComplete__c = true;
        
        Test.startTest();
        update treatment;
        Test.stopTest();
        
        ClinicFunding__c updatedFunding = [SELECT AvailableBalance__c FROM ClinicFunding__c LIMIT 1];
        System.assertEquals(15000, updatedFunding.AvailableBalance__c,
                            'Expected funding to return full 7000 (treatment cost = 0, medication = 2000)');
    }
    
    @isTest
    static void testNoUpdateWhenFundingCompleteAlreadyTrue() {
        Case treatment = [SELECT Id, FundingComplete__c FROM Case WHERE Subject = 'IVF Treatment Test' LIMIT 1];
        treatment.FundingComplete__c = true;
        update treatment;
        Decimal prevBalance = [SELECT AvailableBalance__c FROM ClinicFunding__c LIMIT 1].AvailableBalance__c;
        Test.startTest();
        update treatment;
        Test.stopTest();
        
        Decimal newBalance = [SELECT AvailableBalance__c FROM ClinicFunding__c LIMIT 1].AvailableBalance__c;
        System.assertEquals(prevBalance, newBalance, 'Balance should not change if FundingComplete__c was already true');
    }
}