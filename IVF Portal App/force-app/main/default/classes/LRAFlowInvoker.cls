public with sharing class LRAFlowInvoker {
    
    public class Request {
        @InvocableVariable(required=true)
        public String phn;
    }
    
    public class Response {
        @InvocableVariable
        public Boolean isActive;
        
        @InvocableVariable
        public String resultCode;
    }
    
    @InvocableMethod(label='Verify MSP Active Status')
    public static List<Response> verifyMSP(List<Request> requests) {
        List<Response> results = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            try {
                if (req != null && !String.isBlank(req.phn)) {
                    String result = LRAIntegrationHandler.callLRAAPI('', 'GET', '', req.phn);
                    res.resultCode = result;
                    res.isActive = result == 'MSP_ACTIVE';
                } else {
                    res.resultCode = 'MSP_CHECK_FAILED';
                    res.isActive = false;
                }
            } catch (Exception e) {
                res.resultCode = 'MSP_CHECK_FAILED';
                res.isActive = false;
            }
            results.add(res);
        }
        return results;
    }
}