@isTest
global class MockLRAInactiveResponse implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody('{"entry":[{"resource":{"active":false}}]}');
        return res;
    }
}