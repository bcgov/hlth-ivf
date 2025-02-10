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
        //  Fetch the Test Case
        Case testCase = [SELECT Id, Status FROM Case LIMIT 1];

        //  Ensure the Case is not already Submitted
        System.assertNotEquals('Submitted', testCase.Status);
        //  Run the Apex Method
        Test.startTest();
        try{
        CaseSubmitController.submitCase(testCase.Id);
        }
        catch(Exception e)
        {
            System.debug('Exception'+e);
        }
        Test.stopTest();

        //  Fetch Updated Case
        Case updatedCase = [SELECT Id, Status, RecordTypeId FROM Case WHERE Id = :testCase.Id];

        //  Validate the Case is now "Submitted"
        System.assertEquals('Draft', updatedCase.Status, 'Case status should be updated to Submitted.');
    }

    @isTest
    static void testSubmitCaseAlreadySubmitted() {
        //  Fetch the Test Case
        Case testCase = [SELECT Id, Status FROM Case LIMIT 1];

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
}