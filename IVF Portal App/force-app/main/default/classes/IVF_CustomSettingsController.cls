public with sharing class IVF_CustomSettingsController {

    // Method to retrieve hierarchy custom setting values
    @AuraEnabled(cacheable=true)
    public static IVF_Outage_Message_Settings__c getHierarchyCustomSetting() {
        // Retrieve the hierarchy custom setting values for the current user's profile
        return IVF_Outage_Message_Settings__c.getOrgDefaults();
    }
}