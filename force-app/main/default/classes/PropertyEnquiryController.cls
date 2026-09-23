public without sharing class PropertyEnquiryController {
    @AuraEnabled
    public static Id submitEnquiry(String propertyId, String propertyName, String listingType,
            String firstName, String lastName, String email, String phone, String message) {
        if (String.isBlank(firstName) || String.isBlank(lastName) || String.isBlank(email) || String.isBlank(phone)) {
            throw new AuraHandledException('Please fill in your first name, last name, email, and phone number.');
        }

        try {
            List<Lead> existingLeads = [
                SELECT Id, Message__c
                FROM Lead
                WHERE Email = :email
                AND Property_Interest__c = :propertyId
                AND IsConverted = false
                AND CreatedDate = LAST_N_DAYS:30
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            if (!existingLeads.isEmpty()) {
                Lead existingLead = existingLeads[0];
                if (String.isNotBlank(message)) {
                    String separator = '\n\n--- New message on ' + Date.today().format() + ' ---\n';
                    existingLead.Message__c = String.isNotBlank(existingLead.Message__c)
                        ? existingLead.Message__c + separator + message
                        : message;
                    update existingLead;
                }
                return existingLead.Id;
            }

            Lead newLead = new Lead(
                FirstName = firstName,
                LastName = lastName,
                Company = 'Website Enquiry',
                Email = email,
                Phone = phone,
                LeadSource = 'Website',
                Enquiry_Type__c = (listingType == 'Sale') ? 'Buy' : 'Rent',
                Message__c = message
            );

            if (String.isNotBlank(propertyId)) {
                newLead.Property_Interest__c = propertyId;
            }

            insert newLead;
            return newLead.Id;
        } catch (Exception e) {
            ErrorLogger.logError(e, 'PropertyEnquiryController.submitEnquiry');
            throw new AuraHandledException('Something went wrong submitting your enquiry. Please try again.');
        }
    }
}
