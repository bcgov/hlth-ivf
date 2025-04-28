@isTest
private class LRAIntegrationHandlerTest {
    
    @isTest
    static void testMSPActive() {
        String body = '{"resourceType":"Bundle","entry":[{"resource":{"insurance":[{"inforce":true}]}}]}';
        Test.setMock(HttpCalloutMock.class, new DynamicMock(body, 200));
        
        Test.startTest();
        String result = LRAIntegrationHandler.callLRAAPI('', 'GET', '', '1234567890');
        Test.stopTest();
        
        System.assertEquals('MSP_ACTIVE', result, 'Expected MSP_ACTIVE when insurance inforce is true.');
    }
    
    @isTest
    static void testMSPInactive() {
        String body = '{"resourceType":"Bundle","entry":[{"resource":{"insurance":[{"inforce":false}]}}]}';
        Test.setMock(HttpCalloutMock.class, new DynamicMock(body, 200));
        
        Test.startTest();
        String result = LRAIntegrationHandler.callLRAAPI('', 'GET', '', '9876543210');
        Test.stopTest();
        
        System.assertEquals('MSP_INACTIVE', result, 'Expected MSP_INACTIVE when insurance inforce is false.');
    }
    
    @isTest
    static void testInvalidPHNInNon200Response() {
        String body = 'Error: An invalid PHN was supplied';
        Test.setMock(HttpCalloutMock.class, new DynamicMock(body, 400));
        
        Test.startTest();
        String result = LRAIntegrationHandler.callLRAAPI('', 'GET', '', 'invalidPHN');
        Test.stopTest();
        
        System.assertEquals('INVALID_PHN', result, 'Expected INVALID_PHN for invalid PHN error response.');
    }
    
    @isTest
    static void testGenericFailureNon200Response() {
        String body = '{"error":"Unauthorized"}'; 
        Test.setMock(HttpCalloutMock.class, new DynamicMock(body, 401));
        
        Test.startTest();
        String result = LRAIntegrationHandler.callLRAAPI('', 'GET', '', 'unauthorized');
        Test.stopTest();
        
        System.assertEquals('MSP_CHECK_FAILED', result, 'Expected MSP_CHECK_FAILED for unauthorized response.');
    }
    
    @isTest
    static void testExceptionHandling() {
        Test.setMock(HttpCalloutMock.class, new ExceptionMock()); // Force API failure
        
        Test.startTest();
        String result = LRAIntegrationHandler.callLRAAPI('', 'GET', '', 'exception');
        Test.stopTest();
        
        System.assertEquals('MSP_CHECK_FAILED', result, 'Expected MSP_CHECK_FAILED when exception occurs.');
    }
    
    private class DynamicMock implements HttpCalloutMock {
        private String mockBody;
        private Integer mockStatusCode;
        
        public DynamicMock(String body, Integer statusCode) {
            this.mockBody = body;
            this.mockStatusCode = statusCode;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(mockStatusCode);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(mockBody);
            return res;
        }
    }
    
    private class ExceptionMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Forced exception for testing');
        }
    }
}