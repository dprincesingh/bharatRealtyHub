import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import convertLead from '@salesforce/apex/LeadConversionService.convertLead';

export default class ConvertLeadAction extends NavigationMixin(LightningElement) {
    @api recordId;
    isConverting = false;
    errorMessage = '';

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleConfirm() {
        this.isConverting = true;
        this.errorMessage = '';

        convertLead({ leadId: this.recordId })
            .then((opportunityId) => {
                this.dispatchEvent(new CloseActionScreenEvent());
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: opportunityId,
                        objectApiName: 'Opportunity',
                        actionName: 'view'
                    }
                });
            })
            .catch((error) => {
                this.errorMessage =
                    (error && error.body && error.body.message) || 'Something went wrong converting this Lead.';
            })
            .finally(() => {
                this.isConverting = false;
            });
    }
}