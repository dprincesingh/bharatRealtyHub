import { LightningElement } from 'lwc';
import submitEnquiry from '@salesforce/apex/PropertyEnquiryController.submitEnquiry';

export default class PropertyEnquiryFlowLauncher extends LightningElement {
    propertyId = '';
    propertyName = '';
    listingType = '';

    firstName = '';
    lastName = '';
    email = '';
    phone = '';
    message = '';

    errorMessage = '';
    isSubmitting = false;
    submitted = false;

    connectedCallback() {
        const params = new URLSearchParams(window.location.search);
        this.propertyId = params.get('propertyId') || '';
        this.propertyName = params.get('propertyName') || '';
        this.listingType = params.get('listingType') || '';
    }

    handleChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value;
    }

    handleSubmit() {
        this.errorMessage = '';

        const inputs = this.template.querySelectorAll('lightning-input');
        let allValid = true;
        inputs.forEach((input) => {
            if (!input.reportValidity()) {
                allValid = false;
            }
        });
        if (!allValid) {
            return;
        }

        this.isSubmitting = true;

        submitEnquiry({
            propertyId: this.propertyId,
            propertyName: this.propertyName,
            listingType: this.listingType,
            firstName: this.firstName,
            lastName: this.lastName,
            email: this.email,
            phone: this.phone,
            message: this.message
        })
            .then(() => {
                this.submitted = true;
            })
            .catch((error) => {
                this.errorMessage =
                    (error && error.body && error.body.message) || 'Something went wrong. Please try again.';
            })
            .finally(() => {
                this.isSubmitting = false;
            });
    }
}
