@isTest(seeAllData=false)
public class CaseSubmitControllerTest {
    
    @testSetup
    static void setupTestData() {
        Id IVFreadOnlyRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('IVF Application Read Only').getRecordTypeId();
        Id IVFRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('IVF Application').getRecordTypeId();
        //  Create a Test Case
        Case testCase = new Case(
            RecordTypeId=IVFRecordTypeId,
            Status = 'Draft',
            Applicant1GivenName__c='Test',
            Applicant1Surname__c ='surname'
        );
        insert testCase;
    }
    
    @isTest
    static void testGetCaseStatus() {
        //  Fetch the Test Case
        Case testCase = [SELECT Id, Status FROM Case LIMIT 1];

        //  Run the Apex Method
        Test.startTest();
        String status = CaseSubmitController.getCaseStatus(testCase.Id);
        Test.stopTest();

        //  Validate the Expected Output
        System.assertEquals('Draft', status, 'The retrieved status should match the initial status.');
    }
    @isTest
    static void testSubmitCaseSuccess() {
        try{
        //  Fetch the Test Case
        Case testCase = [SELECT Id, Status FROM Case LIMIT 1];
        testCase.ApplicantConsent__c='Yes';
        testCase.PrivateInsuranceWaiver__c='No';
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
        
        testCase.AreYouAGestationalCarrier__c='No';
        testCase.Applicant1Address__CountryCode__s='US';
        testCase.Applicant1Address__StateCode__s='AR';
        testCase.Applicant1Address__PostalCode__s='98766';
        testCase.Applicant1Address__Street__s='test';
        testCase.Applicant1Address__City__s='Test';
        testCase.Applicant1EnrolledinMedicalServicesPlan__c='Yes';
        testCase.Applicant1GivenName__c='Test';
        testCase.Applicant1MedicallyEligible__c='Yes';
        testCase.Applicant1Patient__c='No';
        testCase.Applicant1PersonalHealthNumber__c='98768';
        testCase.Applicant1DateOfBirth__c=  Date.newInstance(2025, 2, 04);
        update testCase;
        //  Ensure the Case is not already Submitted
        System.assertNotEquals('Submitted', testCase.Status);
        //  Run the Apex Method
        Test.startTest();
        CaseSubmitController.submitCase(testCase.Id);
        //  Fetch Updated Case
        Case updatedCase = [SELECT Id, Status, RecordTypeId FROM Case WHERE Id = :testCase.Id];

        //  Validate the Case is now "Submitted"
        System.assertEquals('Submitted', updatedCase.Status, 'Case status should be updated to Submitted.');
        Test.stopTest();
        }
        catch(Exception e)
        {
            System.debug('Exception'+e);
        }
               
    }

    @isTest
    static void testSubmitCaseAlreadySubmitted() {
        //  Fetch the Test Case
        Case testCase = [SELECT Id, Status FROM Case LIMIT 1];
        testCase.ApplicantConsent__c='Yes';
        testCase.PrivateInsuranceWaiver__c='No';
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
        
        testCase.AreYouAGestationalCarrier__c='No';
        testCase.Applicant1Address__CountryCode__s='US';
        testCase.Applicant1Address__StateCode__s='AR';
        testCase.Applicant1Address__PostalCode__s='98766';
        testCase.Applicant1Address__Street__s='test';
        testCase.Applicant1Address__City__s='Test';
        testCase.Applicant1EnrolledinMedicalServicesPlan__c='Yes';
        testCase.Applicant1GivenName__c='Test';
        testCase.Applicant1MedicallyEligible__c='Yes';
        testCase.Applicant1Patient__c='No';
        testCase.Applicant1PersonalHealthNumber__c='98768';
        testCase.Applicant1DateOfBirth__c=  Date.newInstance(2025, 2, 04);
        //  Update Status to "Submitted"
        testCase.Status = 'Submitted';
        try{
        
            update testCase;
        }
        catch(Exception e)
        {
            System.debug('Exception'+e);
        }

        // Attempt to Resubmit & Expect an Exception
        Test.startTest();
        try {
            CaseSubmitController.submitCase(testCase.Id);
            System.assert(false, 'Exception was expected but not thrown.');
        } catch (AuraHandledException e) {
            system.debug('Excepiton'+e);
        }
        Test.stopTest();
    }
    @isTest
    static void testSubmitforChangesRequested() {
        //  Fetch the Test Case
        Case testCase = [SELECT Id, Status FROM Case LIMIT 1];
        testCase.ApplicantConsent__c='Yes';
        testCase.PrivateInsuranceWaiver__c='No';
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
        
        testCase.AreYouAGestationalCarrier__c='No';
        testCase.Applicant1Address__CountryCode__s='US';
        testCase.Applicant1Address__StateCode__s='AR';
        testCase.Applicant1Address__PostalCode__s='98766';
        testCase.Applicant1Address__Street__s='test';
        testCase.Applicant1Address__City__s='Test';
        testCase.Applicant1EnrolledinMedicalServicesPlan__c='Yes';
        testCase.Applicant1GivenName__c='Test';
        testCase.Applicant1MedicallyEligible__c='Yes';
        testCase.Applicant1Patient__c='No';
        testCase.Applicant1PersonalHealthNumber__c='98768';
        testCase.NotApplicable__c =true;
        testCase.Applicant1DateOfBirth__c=  Date.newInstance(2025, 2, 04);
        testCase.Status='Changes Requested';
        update testCase;
        //  Ensure the Case is not already Submitted
        System.assertNotEquals('Changes Completed', testCase.Status);
        //  Run the Apex Method
        Test.startTest();
        CaseSubmitController.submitCase(testCase.Id);
        //  Fetch Updated Case
        Case updatedCase = [SELECT Id, Status, RecordTypeId FROM Case WHERE Id = :testCase.Id];

        //  Validate the Case is now "Submitted"
        System.assertEquals('Changes Completed', updatedCase.Status, 'Case status should be updated to Submitted.');
        Test.stopTest();      
    }  
}