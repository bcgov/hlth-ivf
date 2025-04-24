@IsTest
private class LRAIntegrationHandlerTest {
    
    @IsTest
    static void testActiveResponse() {
        Test.setMock(HttpCalloutMock.class, new MockLRAActiveResponse());
        Test.startTest();
        String result = LRAIntegrationHandler.callLRAAPI('', 'GET', '', '9872728627');
        Test.stopTest();
        System.assertEquals('MSP Status: Active', result, 'Should return Active');
    }
    
    @IsTest
    static void testInactiveResponse() {
        Test.setMock(HttpCalloutMock.class, new MockLRAInactiveResponse());
        Test.startTest();
        String result = LRAIntegrationHandler.callLRAAPI('', 'GET', '', '9872728627');
        Test.stopTest();
        System.assertEquals('MSP Status: Inactive', result, 'Should return Inactive');
    }
    
    @IsTest
    static void testCalloutExceptionResponse() {
        Test.setMock(HttpCalloutMock.class, new MockLRAExceptionResponse());
        Test.startTest();
        String result = LRAIntegrationHandler.callLRAAPI('', 'GET', '', '9872728627');
        Test.stopTest();
        System.assert(result.contains('Exception occurred'), 'Should handle callout exception');
    }
    
    @IsTest
    static void testNoEntryOrPatientNotFound() {
        String mockBody = '{"resourceType":"Bundle","total":0}';
        Test.setMock(HttpCalloutMock.class, new LRAIntegrationHandlerTest.DynamicMock(mockBody, 200));
        Test.startTest();
        String result = LRAIntegrationHandler.callLRAAPI('', 'GET', '', '0000000000');
        Test.stopTest();
        System.assertEquals('Patient not found or not enrolled in MSP.', result);
    }
    
    @IsTest
    static void testNoInsuranceInResponse() {
        String mockBody = '{"resourceType":"Bundle","total":1,"entry":[{"resource":{"insurance":[]}}]}';
        Test.setMock(HttpCalloutMock.class, new LRAIntegrationHandlerTest.DynamicMock(mockBody, 200));
        Test.startTest();
        String result = LRAIntegrationHandler.callLRAAPI('', 'GET', '', '0000000000');
        Test.stopTest();
        System.assertEquals('MSP Status: Unknown (no insurance info)', result);
    }
    
    @IsTest
    static void testInvalidJsonParsingError() {
        String invalidJson = 'not a json';
        Test.setMock(HttpCalloutMock.class, new LRAIntegrationHandlerTest.DynamicMock(invalidJson, 200));
        Test.startTest();
        String result = LRAIntegrationHandler.callLRAAPI('', 'GET', '', '9872728627');
        Test.stopTest();
        System.assertEquals('Error parsing response from LRA.', result);
    }
    
    @IsTest
    static void testErrorStatusCode() {
        String errorJson = 'Unauthorized';
        Test.setMock(HttpCalloutMock.class, new LRAIntegrationHandlerTest.DynamicMock(errorJson, 401));
        Test.startTest();
        String result = LRAIntegrationHandler.callLRAAPI('', 'GET', '', '9872728627');
        Test.stopTest();
        System.assert(result.contains('LRA Error: 401'), 'Should return error status');
    }
    
    // Optional: Generic mock for inline JSON usage
    public class DynamicMock implements HttpCalloutMock {
        private String body;
        private Integer statusCode;
        
        public DynamicMock(String body, Integer statusCode) {
            this.body = body;
            this.statusCode = statusCode;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(body);
            res.setStatusCode(statusCode);
            return res;
        }
    }
}