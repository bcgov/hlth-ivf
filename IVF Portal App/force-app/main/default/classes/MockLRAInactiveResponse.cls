@isTest
global class MockLRAInactiveResponse implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody('{' +
                    '"resourceType": "Bundle",' +
                    '"total": 1,' +
                    '"entry": [{' +
                    '"resource": {' +
                    '"insurance": [{' +
                    '"inforce": false' +
                    '}]' +
                    '}' +
                    '}]' +
                    '}');
        return res;
    }
}
