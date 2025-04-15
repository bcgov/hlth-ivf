@isTest
global class MockLRAActiveResponse implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody('{"entry":[{"resource":{"active":true}}]}');
        return res;
    }
}