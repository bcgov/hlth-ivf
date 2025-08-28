@isTest
public class CaseTriggerHandlerTest {     
    @testSetup
    static void setupTestData() {
        List<ClinicFunding__c> clinicFundings = new List<ClinicFunding__c>();
        List<IVFFundingTier__c> fundingTiers = new List<IVFFundingTier__c>();
        Account testClinic = new Account(Name = 'Test Clinic');
        insert testClinic;
        
        Id ivfAppRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'IVF_Application' AND SObjectType = 'Case' LIMIT 1].Id;
        Id ivfTreatmentRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'IVFTreatment' AND SObjectType = 'Case' LIMIT 1].Id;
        
        ClinicFunding__c clinicFunding = new ClinicFunding__c(
            Clinic__c = testClinic.Id, 
            AvailableBalance__c = 10000,
            FYStartDate__c=Date.newInstance(2024, 4, 1),
            FYEndDate__c=Date.newInstance(2025, 3, 31)
        );
        clinicFundings.add(clinicFunding);
        ClinicFunding__c clinicFunding2 = new ClinicFunding__c(
            Clinic__c = testClinic.Id, 
            AvailableBalance__c = 20000,
            FYStartDate__c=Date.newInstance(2025, 4, 1),
            FYEndDate__c=Date.newInstance(2026, 3, 31)
        );
        clinicFundings.add(clinicFunding2);
        ClinicFunding__c clinicFunding3 = new ClinicFunding__c(
            Clinic__c = testClinic.Id, 
            AvailableBalance__c = 30000,
            FYStartDate__c=Date.newInstance(2023, 4, 1),
            FYEndDate__c=Date.newInstance(2024, 3, 31)
        );
        clinicFundings.add(clinicFunding3);
        insert clinicFundings;
        
        IVFFundingTier__c testTier = new IVFFundingTier__c(
            Name = 'Tier 1',
            IncomeLevel__c = '0 - $100K',    
            Funding_Amount__c = 7000
        );
        fundingTiers.add(testTier);
        IVFFundingTier__c testTier2 = new IVFFundingTier__c(
            Name = 'Tier 2',
            IncomeLevel__c = '$250,001+',     
            Funding_Amount__c = 7000
        );
        fundingTiers.add(testTier2);
        insert fundingTiers;
        Case ivfApp = new Case(
            AccountId=testClinic.Id,
            RecordTypeId = ivfAppRTId,
            Status = 'Draft',
            Clinic_Funding__c = clinicFunding.Id,
            Subject = 'IVF Application Test', 
            FinalDecisionDate__c=Date.newInstance(2023, 5, 1),
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
        System.assertEquals(10000, updatedFunding.AvailableBalance__c,
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
    @isTest
    static void testPopulateFundingTiers() {
        Case testCase=[SELECT Id,RecordtypeId,TotalHouseholdIncome__c,FundingTier__c,ApprovedTreatmentFunding__c FROM Case WHERE Subject = 'IVF Application Test' LIMIT 1];
         testCase.ApplicantConsent__c='Yes';
        testCase.PrivateInsuranceWaiver__c='No';
        testCase.RequiredDiagnosticsCompleted__c='Yes';
        testCase.DateOfApplicationSubmission__c= Date.newInstance(2025, 2, 12);
        testCase.DateOfIVFConsultation__c= Date.newInstance(2025, 2, 10);
        testCase.UsingPreviouslyFrozenEmbryo__c= 'No';
        testCase.EstimatedCostofTreatmentPlan__c= 1000;
         testCase.ExceptionRequest__c='No';
        testCase.PrivateInsuranceCoverageForIVF__c= 'No';
        testCase.PreviouslyReceivedFundingforIVF__c= 'No';
        testCase.PractitionerNumber__c='98765';
        testCase.FirstName__c='Test';
        testCase.LastName__c='Test';
        testCase.Applicant1RequiredDiagnosticsCompleted__c= 'No';
        testCase.FertilitySpecialistClinicName__c='Grace';
        testCase.FertilitySpecialistClinicLocation__c='Vancouver';
        testCase.EmbryoTransferLocation__c='GraceVancouver';
        testCase.NOARecevied__c='Yes';
        testCase.AreYouAGestationalCarrier__c='No';
        testCase.Applicant1Address__CountryCode__s='US';
        testCase.Applicant1Address__StateCode__s='AR';
        testCase.Applicant1Address__PostalCode__s='98766';
        testCase.Applicant1Address__Street__s='test';
        testCase.Applicant1Address__City__s='Test';
        testCase.Applicant1EnrolledinMedicalServicesPlan__c='Yes';
        testCase.Applicant1GivenName__c='Test';
        testCase.Applicant1Surname__c='SurName';
        testCase.Applicant1MedicallyEligible__c='Yes';
        testCase.Applicant1Patient__c='No';
        testCase.Applicant1PersonalHealthNumber__c='98768';
        testCase.Applicant1DateOfBirth__c=  Date.newInstance(2025, 2, 04);
        testCase.NotApplicable__c =true;
        testCase.Patient1NotApplicable__c =true;
        testCase.Patient2NotApplicable__c =true;
        testCase.Patient3NotApplicable__c =true;
        testCase.TotalHouseholdIncome__c=10000;
        testCase.status='In Review';
        update testCase;
        Case updatedCase=[Select id,TotalHouseholdIncome__c,FundingTier__c,ApprovedTreatmentFunding__c from case where id=:testCase.Id];
        System.assertEquals(updatedCase.FundingTier__c!=null,True,'Funding tier not populated');
    }
    @isTest
    static void testPopulateFundingTiers2() {
        Case testCase=[SELECT Id,RecordtypeId,TotalHouseholdIncome__c,FundingTier__c,ApprovedTreatmentFunding__c FROM Case WHERE Subject = 'IVF Application Test' LIMIT 1];
        testCase.ApplicantConsent__c='Yes';
        testCase.PrivateInsuranceWaiver__c='No';
        testCase.RequiredDiagnosticsCompleted__c='Yes';
        testCase.DateOfApplicationSubmission__c= Date.newInstance(2025, 2, 12);
        testCase.DateOfIVFConsultation__c= Date.newInstance(2025, 2, 10);
        testCase.UsingPreviouslyFrozenEmbryo__c= 'No';
        testCase.EstimatedCostofTreatmentPlan__c= 1000;
         testCase.ExceptionRequest__c='No';
        testCase.PrivateInsuranceCoverageForIVF__c= 'No';
        testCase.PreviouslyReceivedFundingforIVF__c= 'No';
        testCase.PractitionerNumber__c='98765';
        testCase.FirstName__c='Test';
        testCase.LastName__c='Test';
        testCase.Applicant1RequiredDiagnosticsCompleted__c= 'No';
        testCase.FertilitySpecialistClinicName__c='Grace';
        testCase.FertilitySpecialistClinicLocation__c='Vancouver';
        testCase.EmbryoTransferLocation__c='GraceVancouver';
        testCase.NOARecevied__c='Yes';
        testCase.AreYouAGestationalCarrier__c='No';
        testCase.Applicant1Address__CountryCode__s='US';
        testCase.Applicant1Address__StateCode__s='AR';
        testCase.Applicant1Address__PostalCode__s='98766';
        testCase.Applicant1Address__Street__s='test';
        testCase.Applicant1Address__City__s='Test';
        testCase.Applicant1EnrolledinMedicalServicesPlan__c='Yes';
        testCase.Applicant1GivenName__c='Test';
        testCase.Applicant1Surname__c='SurName';
        testCase.Applicant1MedicallyEligible__c='Yes';
        testCase.Applicant1Patient__c='No';
        testCase.Applicant1PersonalHealthNumber__c='98768';
        testCase.Applicant1DateOfBirth__c=  Date.newInstance(2025, 2, 04);
        testCase.NotApplicable__c =true;
        testCase.Patient1NotApplicable__c =true;
        testCase.Patient2NotApplicable__c =true;
        testCase.Patient3NotApplicable__c =true;
        testCase.TotalHouseholdIncome__c=260000;
        testCase.status='In Review';
        update testCase;
        Case updatedCase=[Select id,TotalHouseholdIncome__c,FundingTier__c,ApprovedTreatmentFunding__c from case where id=:testCase.Id];
        System.assertEquals(updatedCase.FundingTier__c!=null,True,'Funding Tier not populated');
    }
    @isTest
    static void testNotPopulateFundingTiers() {
        Case testCase=[SELECT Id FROM Case WHERE Subject = 'IVF Application Test' LIMIT 1];
        testCase.ApplicantConsent__c='Yes';
        testCase.PrivateInsuranceWaiver__c='No';
        testCase.RequiredDiagnosticsCompleted__c='Yes';
        testCase.DateOfApplicationSubmission__c= Date.newInstance(2025, 2, 12);
        testCase.DateOfIVFConsultation__c= Date.newInstance(2025, 2, 10);
        testCase.UsingPreviouslyFrozenEmbryo__c= 'No';
        testCase.EstimatedCostofTreatmentPlan__c= 1000;
         testCase.ExceptionRequest__c='No';
        testCase.PrivateInsuranceCoverageForIVF__c= 'No';
        testCase.PreviouslyReceivedFundingforIVF__c= 'No';
        testCase.PractitionerNumber__c='98765';
        testCase.FirstName__c='Test';
        testCase.LastName__c='Test';
        testCase.Applicant1RequiredDiagnosticsCompleted__c= 'No';
        testCase.FertilitySpecialistClinicName__c='Grace';
        testCase.FertilitySpecialistClinicLocation__c='Vancouver';
        testCase.EmbryoTransferLocation__c='GraceVancouver';
        testCase.NOARecevied__c='Yes';
        testCase.AreYouAGestationalCarrier__c='No';
        testCase.Applicant1Address__CountryCode__s='US';
        testCase.Applicant1Address__StateCode__s='AR';
        testCase.Applicant1Address__PostalCode__s='98766';
        testCase.Applicant1Address__Street__s='test';
        testCase.Applicant1Address__City__s='Test';
        testCase.Applicant1EnrolledinMedicalServicesPlan__c='Yes';
        testCase.Applicant1GivenName__c='Test';
        testCase.Applicant1Surname__c='SurName';
        testCase.Applicant1MedicallyEligible__c='Yes';
        testCase.Applicant1Patient__c='No';
        testCase.Applicant1PersonalHealthNumber__c='98768';
        testCase.Applicant1DateOfBirth__c=  Date.newInstance(2025, 2, 04);
        testCase.NotApplicable__c =true;
        testCase.Patient1NotApplicable__c =true;
        testCase.Patient2NotApplicable__c =true;
        testCase.Patient3NotApplicable__c =true;
        testCase.status='In Review';
        Test.StartTest();
        update testCase;
        Test.StopTest();
        Case updatedCase=[Select id,TotalHouseholdIncome__c,ApprovedTreatmentFunding__c from case where id=:testCase.Id];
        System.assertEquals(updatedCase.ApprovedTreatmentFunding__c==null,True,'Funding Amount should not be populated');
    }
}