@isTest
private class LRAFlowInvokerTest {

    @isTest
    static void testVerifyMspActive() {
        Test.setMock(HttpCalloutMock.class, new MockLRAActiveResponse());
        LRAFlowInvoker.Request req = new LRAFlowInvoker.Request();
        req.phn = '777787889';

        List<LRAFlowInvoker.Response> results = LRAFlowInvoker.verifyMSP(
            new List<LRAFlowInvoker.Request>{ req }
        );

        System.assertEquals(1, results.size(), 'Should return 1 response for active PHN');
        System.assertEquals(true, results[0].isActive, 'Expected MSP status to be Active');
    }

    @isTest
    static void testVerifyMspInactive() {
        Test.setMock(HttpCalloutMock.class, new MockLRAInactiveResponse());
        LRAFlowInvoker.Request req = new LRAFlowInvoker.Request();
        req.phn = '123456789';

        List<LRAFlowInvoker.Response> results = LRAFlowInvoker.verifyMSP(
            new List<LRAFlowInvoker.Request>{ req }
        );

        System.assertEquals(1, results.size(), 'Should return 1 response for inactive PHN');
        System.assertEquals(false, results[0].isActive, 'Expected MSP status to be Inactive');
    }

    @isTest
    static void testVerifyMspException() {
        Test.setMock(HttpCalloutMock.class, new MockLRAExceptionResponse());
        LRAFlowInvoker.Request req = new LRAFlowInvoker.Request();
        req.phn = 'errorPHN';

        List<LRAFlowInvoker.Response> results = LRAFlowInvoker.verifyMSP(
            new List<LRAFlowInvoker.Request>{ req }
        );

        System.assertEquals(1, results.size(), 'Should return 1 response even on exception');
        System.assertEquals(false, results[0].isActive, 'Expected MSP status to be false due to exception');
    }

    @isTest
    static void testVerifyMspBlankPhn() {
        LRAFlowInvoker.Request req = new LRAFlowInvoker.Request();
        req.phn = '';

        List<LRAFlowInvoker.Response> results = LRAFlowInvoker.verifyMSP(
            new List<LRAFlowInvoker.Request>{ req }
        );

        System.assertEquals(1, results.size(), 'Should return 1 response for blank PHN');
        System.assertEquals(false, results[0].isActive, 'Expected MSP status to be false for blank PHN');
    }

    @isTest
    static void testVerifyMspNullRequest() {
        List<LRAFlowInvoker.Response> results = LRAFlowInvoker.verifyMSP(
            new List<LRAFlowInvoker.Request>{ null }
        );

        System.assertEquals(1, results.size(), 'Should return 1 response for null request');
        System.assertEquals(false, results[0].isActive, 'Expected MSP status to be false for null request');
    }
}
