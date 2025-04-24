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
            
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                try {
                    LRAMSPEligibilityWrapper mspEligibility = LRAMSPEligibilityWrapper.parse(res.getBody());
                    
                    // Handle no patient found
                    if (mspEligibility == null || mspEligibility.total == null || mspEligibility.total == 0 || mspEligibility.entry == null || mspEligibility.entry.isEmpty()) {
                        return 'Patient not found or not enrolled in MSP.';
                    }
                    
                    // Check insurance info
                    LRAMSPEligibilityWrapper.Entry entry = mspEligibility.entry[0];
                    if (entry.resource == null || entry.resource.insurance == null || entry.resource.insurance.isEmpty()) {
                        return 'MSP Status: Unknown (no insurance info)';
                    }
                    
                    Boolean isMSPActive = entry.resource.insurance[0].inforce;
                    return 'MSP Status: ' + (isMSPActive ? 'Active' : 'Inactive');
                } catch (Exception parseEx) {
                    return 'Error parsing response from LRA.';
                }
            } else {
                return 'LRA Error: ' + res.getStatusCode() + ' - ' + res.getBody();
            }
            
        } catch (Exception e) {
            return 'Exception occurred: ' + e.getMessage();
        }
    }
}