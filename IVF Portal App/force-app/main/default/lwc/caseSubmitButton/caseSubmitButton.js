import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getCaseRecordType from '@salesforce/apex/CaseSubmitController.getCaseRecordType';
import submitCase from '@salesforce/apex/CaseSubmitController.submitCase';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CaseSubmitButton extends NavigationMixin(LightningElement) {
    @api recordId;
    @track isDisabled = false;
    @track showButton = false;
    wiredgetCaseRecordTypeResult;

    @wire(getCaseRecordType, { caseId: '$recordId' })
    wiredgetCaseRecordType(result) {
        this.wiredgetCaseRecordTypeResult = result;
        if (result.data) {
            const [recordType, status] = result.data.split('|');
            const allowedRecordTypes = ['IVF_Application', 'IVF_Application_Read_Only'];
            const allowedStatuses = ['Draft', 'Changes Requested', 'Submitted'];

            this.showButton = allowedRecordTypes.includes(recordType) && allowedStatuses.includes(status);
            this.isDisabled = !allowedStatuses.includes(status);
        } else if (result.error) {
            console.error('Error fetching Case status:', result.error);
        }
    }

    async handleSubmit() {
        this.isDisabled = true;
        try {
            await submitCase({ caseId: this.recordId });
            this.showToast('Success', 'Case submitted successfully!', 'success');
            this.refreshRecordPage();
        } catch (error) {
            console.error('Error submitting Case:', error);
            let errorMessage = 'An error occurred while submitting the Case.';
            if (error.body) {
                if (error.body.message) {
                    errorMessage = error.body.message;
                } else if (error.body.pageErrors?.length) {
                    errorMessage = error.body.pageErrors.map(e => e.message).join(', ');
                } else if (error.body.fieldErrors) {
                    errorMessage = Object.values(error.body.fieldErrors).flat().map(e => e.message).join(', ');
                }
            }

            this.showToast('Validation Error', errorMessage, 'error');
            this.isDisabled = false; // Re-enable the button if submission fails
        }
    }

    refreshRecordPage() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Case',
                actionName: 'view'
            }
        }).then(url => {
            window.location.href = url; 
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}