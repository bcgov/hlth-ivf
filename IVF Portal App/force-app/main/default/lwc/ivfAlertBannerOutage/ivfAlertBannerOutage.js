import { LightningElement, wire } from 'lwc';
import getHierarchyCustomSetting from '@salesforce/apex/IVF_CustomSettingsController.getHierarchyCustomSetting';

export default class IvfAlertBannerOutage extends LightningElement {
    showBanner;
    bannerOutageMsg;
    hierarchyCustomSetting;

    @wire(getHierarchyCustomSetting)
    wiredHierarchyCustomSetting({ error, data }) {
        if (data) {
            this.hierarchyCustomSetting = data;
            this.showBanner = this.hierarchyCustomSetting.Outage__c ;
            this.bannerOutageMsg = this.hierarchyCustomSetting.Outage_Message__c;
        } else   
            this.showBanner = false;
    }
}