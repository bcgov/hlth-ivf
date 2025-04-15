public with sharing class LRAFlowInvoker {
    
    public class Request {
        @InvocableVariable(required=true)
        public String phn;
    }
    
    public class Response {
        @InvocableVariable
        public Boolean isActive;
    }
    
    @InvocableMethod(label='Verify MSP Active Status')
    public static List<Response> verifyMSP(List<Request> requests) {
        List<Response> results = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            try {
                if (req != null && !String.isBlank(req.phn)) {
                    String responseBody = LRAIntegrationHandler.callLRAAPI('', 'GET', '', req.phn);
                    res.isActive = responseBody != null && responseBody.contains('MSP Status: Active');
                } else {
                    res.isActive = false;
                }
            } catch (Exception e) {
                res.isActive = false;
            }
            results.add(res);
        }
        return results;
    }
}