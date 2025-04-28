@isTest(seeAllData=false)
public class MSPEligibilityCheckMonthlyBatchTest {
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
        //Funding Tier Creation
        IVFFundingTier__c testIVFFundingTier = new IVFFundingTier__c(Name='Tier 1',Funding_Amount__c=10000);
        insert testIVFFundingTier;
        
        //Update Case
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
        testCase.Applicant1PersonalHealthNumber__c='9876854321';
        testCase.Applicant1DateOfBirth__c=  Date.newInstance(2005, 2, 04);
        testCase.MSPEligibilityCheckComplete__c=True;
        //Applicant 2 Details
        //testCase.NotApplicable__c =true;
        testCase.Applicant2Surname__c='Finley';
        testCase.Applicant2GivenName__c = 'Bod';
        testCase.Applicant2EnrolledInMedicalServicesPlan__c = 'Yes';
        testCase.Applicant2DateOfBirth__c = Date.newInstance(2005, 15, 04);
        testCase.Applicant2MedicallyEligible__c = 'Yes';
        testCase.Applicant2ReceivedFunding__c = 'No'; 
        testCase.Applicant2RequiredDiagnosticsCompleted__c = 'Yes';
        testCase.Applicant2Address__CountryCode__s='US';
        testCase.Applicant2Address__StateCode__s='AR';
        testCase.Applicant2Address__PostalCode__s='98766';
        testCase.Applicant2Address__Street__s='test';
        testCase.Applicant2Address__City__s='Test';
        testCase.Applicant2PersonalHealthNumber__c='9876854322';
        //Patient1 Details
        //testCase.Patient1NotApplicable__c =true;
        testCase.Patient1Surname__c='Test';
        testCase.Patient1PersonalHealthNumber__c ='9876854323';
        testCase.Patient1GivenName__c = 'Patient1';
        testCase.Patient1EnrolledInMedicalServicesPlan__c = 'Yes';
        testCase.EnrolledInCanadianPublicHealthPlan__c = 'Yes';
        testCase.PreviouslyParticipatedInIvfProgram__c = 'Yes';
        testCase.Patient1DateofBirth__c = Date.newInstance(2005, 15, 04);
        testCase.Patient1Address__CountryCode__s='US';
        testCase.Patient1Address__StateCode__s='AR';
        testCase.Patient1Address__PostalCode__s='98766';
        testCase.Patient1Address__Street__s='test';
        testCase.Patient1Address__City__s='Test';
        //Patient2 Details
        //testCase.Patient2NotApplicable__c =true;
        testCase.Patient2Surname__c='Test';
        testCase.Patient2IsThePatientFromOutOfCountry__c= 'Yes';
        testCase.Patient2PersonalHealthNumber__c ='9876854324';
        //testCase.Patient2GivenName__c = 'Patient2';
        testCase.Patient2EnrolledInMedicalServicesPlan__c = 'Yes';
        testCase.Patient2DateofBirth__c = Date.newInstance(2005, 15, 04);
        testCase.Patient2Address__CountryCode__s='US';
        testCase.Patient2Address__StateCode__s='AR';
        testCase.Patient2Address__PostalCode__s='98766';
        testCase.Patient2Address__Street__s='test';
        testCase.Patient2Address__City__s='Test';
        //Patient3 Details
        //testCase.Patient3NotApplicable__c =true;
        testCase.Patient3IsThePatientFromOutOfCountry__c='Yes';
        testCase.Patient3PersonalHealthNumber__c='9876854325';
        
        testCase.FundingTier__c = testIVFFundingTier.Id;
        testCase.ApprovedTreatmentFunding__c = testIVFFundingTier.Funding_Amount__c;
        testCase.NOARecevied__c = 'Yes';
        testCase.Status='In Review';
        update testCase;
    }
    
    @isTest
    static void testScheudleBatch() {
    
        //  Fetch the Test Case
        Case testCase = [SELECT Id, Status FROM Case Where Recordtype.Name !='IVF Treatment'];
        
        //Approve the Case
        testCase.Status='Approved';
        update testCase;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockLRAActiveResponse());
        Integer batch_size=1;
        String cronExp = '0 0 1 2 * ?'; // 1:00 AM PST on 2nd of every month
        String jobName = 'MSP_Eligibility_Monthly_Scheduler';
        //MSPEligibilityCheckMonthlyBatch batch=new MSPEligibilityCheckMonthlyBatch(batch_size);
        //batch.batchSize=1;
        System.schedule(jobName, cronExp, new MSPEligibilityCheckMonthlyBatch(batch_size));
        Test.stopTest();
    }

    @isTest
    static void testMSPCheckSuccessful() {
        Id IVFTreatmentRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('IVF Treatment').getRecordTypeId();
        //  Fetch the Test Case
        Case testCase = [SELECT Id, Status FROM Case Where Recordtype.Name !='IVF Treatment' LIMIT 1];
        IVFFundingTier__c fundingTier =[Select Id,Funding_Amount__c from IVFFundingTier__c Where Name ='Tier 1'];
        
        //Approve the Case
        testCase.Status='Approved';
        update testCase;
        System.assertNotEquals('Changes Completed', testCase.Status);
        //Check for Treatment records Creation when Application is approved.
        List<Case> treatmentCases=[Select id from Case Where recordtypeid =:IVFTreatmentRecordTypeId and parentid =:testCase.Id];
        System.debug('treatmentCases'+treatmentCases);
        
        
        //  Run the Apex Method
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockLRAActiveResponse());
        Integer batch_size=1;
        MSPEligibilityCheckMonthlyBatch MSPEBatch= new MSPEligibilityCheckMonthlyBatch(batch_size);
        //MSPEBatch.batchSize=1;
        Database.executeBatch(MSPEBatch,batch_size);
        Test.stopTest();      
    }
    @isTest
    static void testMSPCheckException() {
        Id IVFTreatmentRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('IVF Treatment').getRecordTypeId();
        //  Fetch the Test Case
        Case testCase = [SELECT Id, Status FROM Case Where Recordtype.Name !='IVF Treatment' LIMIT 1];
        IVFFundingTier__c fundingTier =[Select Id,Funding_Amount__c from IVFFundingTier__c Where Name ='Tier 1'];
        
        //Approve the Case
        testCase.Status='Approved';
        update testCase;
        System.assertNotEquals('Changes Completed', testCase.Status);
        //Check for Treatment records Creation when Application is approved.
        List<Case> treatmentCases=[Select id from Case Where recordtypeid =:IVFTreatmentRecordTypeId and parentid =:testCase.Id];
        System.debug('treatmentCases'+treatmentCases);
        
        
        //  Run the Apex Method
        Test.startTest();
        //Test.setMock(HttpCalloutMock.class, new MockLRAActiveResponse());
        Integer batch_size=1;
        MSPEligibilityCheckMonthlyBatch MSPEBatch= new MSPEligibilityCheckMonthlyBatch(batch_size);
        //MSPEBatch.batchSize=1;
        Database.executeBatch(MSPEBatch,batch_size);
        Test.stopTest();      
    }
}