import { LightningElement, api, wire, track } from 'lwc';
import getCaseStatus from '@salesforce/apex/CaseSubmitController.getCaseStatus';
import submitCase from '@salesforce/apex/CaseSubmitController.submitCase';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

export default class CaseSubmitButton extends LightningElement {
  @api recordId;
  @track isDisabled = false;

  // Wire Case status to enable refreshApex
  @wire(getCaseStatus, { caseId: '$recordId' })
  wiredCaseStatus({ data, error }) {
    if (data) {
      
      this.isDisabled = !(data === 'Draft' || data === 'Changes Requested' || data === 'Submitted');
    } else if (error) {
      console.error('Error fetching Case status:', error);
    }
  }

  handleSubmit() {
    submitCase({ caseId: this.recordId })
      .then(() => {
        this.showToast('Success', 'Case submitted successfully!', 'success');
        this.isDisabled = true;
        getRecordNotifyChange([{ recordId: this.recordId }]); // Refresh the UI
      })
      .catch((error) => {
        console.error('Error submitting Case:', error);

        // ✅ Extract combined error messages from Apex
        let errorMessage = 'An error occurred while submitting the Case.';
        if (error.body && error.body.message) {
          errorMessage = error.body.message;
        }

        this.showToast('Validation Error', errorMessage, 'error');
      });
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}