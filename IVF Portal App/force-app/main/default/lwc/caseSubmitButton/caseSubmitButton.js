import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getCaseStatus from '@salesforce/apex/CaseSubmitController.getCaseStatus';
import submitCase from '@salesforce/apex/CaseSubmitController.submitCase';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange, refreshApex } from 'lightning/uiRecordApi';

export default class CaseSubmitButton extends NavigationMixin(LightningElement) {
    @api recordId;
    @track isDisabled = false;
    wiredCaseStatusResult;

    @wire(getCaseStatus, { caseId: '$recordId' })
    wiredCaseStatus(result) {
        this.wiredCaseStatusResult = result;
        if (result.data) {
            this.isDisabled = !['Draft', 'Changes Requested', 'Submitted'].includes(result.data);
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