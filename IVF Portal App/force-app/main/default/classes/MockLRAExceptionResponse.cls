@isTest
global class MockLRAExceptionResponse implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        throw new CalloutException('Simulated API failure');
    }
}