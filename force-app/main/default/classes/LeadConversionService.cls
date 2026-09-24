public without sharing class LeadConversionService {

      @AuraEnabled
      public static Id convertLead(Id leadId) {
          try {
              Lead leadRecord = [
                  SELECT Id, Property_Interest__c, Property_Interest__r.Price__c, Enquiry_Type__c, FirstName, LastName, Name
                  FROM Lead
                  WHERE Id = :leadId
                  LIMIT 1
              ];

              if (leadRecord.Property_Interest__c == null) {
                  throw new AuraHandledException('This Lead has no Property linked — cannot convert.');
              }

              Database.LeadConvert lc = new Database.LeadConvert();
              lc.setLeadId(leadRecord.Id);
              lc.setAccountId(leadRecord.Property_Interest__c);
              lc.setDoNotCreateOpportunity(false);
              lc.setOpportunityName(leadRecord.Name + ' - Opportunity');
              lc.setConvertedStatus('Qualified');

              Database.LeadConvertResult result = Database.convertLead(lc);

              if (!result.isSuccess()) {
                  throw new AuraHandledException('Conversion failed: ' + result.getErrors()[0].getMessage());
              }

              update new Opportunity(
                  Id = result.getOpportunityId(),
                  Amount = leadRecord.Property_Interest__r.Price__c,
                  CloseDate = Date.today().addDays(30),
                  Purchase_Type__c = leadRecord.Enquiry_Type__c
              );

              return result.getOpportunityId();
          } catch (Exception e) {
              ErrorLogger.logError(e, 'LeadConversionService.convertLead');
              throw new AuraHandledException('Could not convert this Lead: ' + e.getMessage());
          }
      }
  }