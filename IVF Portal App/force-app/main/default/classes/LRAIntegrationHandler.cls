public with sharing class LRAIntegrationHandler {
    
    @AuraEnabled
    public static String callLRAAPI(String body, String method, String bearerToken, String personalHN) {
        HttpRequest req = new HttpRequest();
        Http http = new Http();
        
        String identifierParam = EncodingUtil.urlEncode(
            'https://fhir.infoway-inforoute.ca/NamingSystem/ca-bc-patient-healthcare-id|' + personalHN,
            'UTF-8'
        );
        
        String servicedDate = Date.today().format();
        
        String endpoint = 'callout:LRA_API/fhir/CoverageEligibilityResponse?patient.identifier=' + identifierParam + '&serviced-date=' + servicedDate;
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('UserID', 'moh-ivfportal-svc');
        
        if (!String.isBlank(body)) {
            req.setBody(body);
        }
        
        try {
            HttpResponse res = http.send(req);
            String responseBody = res.getBody();
            Integer statusCode = res.getStatusCode();
            
            if (statusCode == 200 || statusCode == 201) {
                Map<String, Object> raw = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                String resourceType = (String) raw.get('resourceType');
                
                if (resourceType == 'Bundle') {
                    List<Object> entries = (List<Object>) raw.get('entry');
                    if (entries != null && !entries.isEmpty()) {
                        Map<String, Object> entry = (Map<String, Object>) entries[0];
                        Map<String, Object> resource = (Map<String, Object>) entry.get('resource');
                        List<Object> insurances = (List<Object>) resource.get('insurance');
                        if (insurances != null && !insurances.isEmpty()) {
                            Map<String, Object> insurance = (Map<String, Object>) insurances[0];
                            Boolean inForce = (Boolean) insurance.get('inforce');
                            return inForce ? 'MSP_ACTIVE' : 'MSP_INACTIVE';
                        }
                    }
                }
            } else {
                if (responseBody.contains('Error: An invalid PHN was supplied')) {
                    return 'INVALID_PHN';
                }
                return 'MSP_CHECK_FAILED';
            }
        } catch (Exception ex) {
            return 'MSP_CHECK_FAILED';
        }
        return 'MSP_CHECK_FAILED';
    }
}