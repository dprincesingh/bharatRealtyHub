@RestResource(urlMapping='/properties/*')
global without sharing class PropertyListingService {

    global class PropertyDTO {
        public String id;
        public String name;
        public String propertyType;
        public String listingType;
        public Decimal price;
        public Decimal bedrooms;
        public Decimal bathrooms;
        public Decimal areaSqft;
        public String city;
        public String description;
        public String imageUrl;
    }

    @HttpGet
    global static List<PropertyDTO> getPublishedProperties() {
        List<PropertyDTO> results = new List<PropertyDTO>();

        try {
            for (Account acc : [
                SELECT Id, Name, Property_Type__c, Listing_Type__c, Price__c, Bedrooms__c,
                       Bathrooms__c, Area_Sqft__c, BillingCity, Description__c, Property_Image_URL__c
                FROM Account
                WHERE RecordType.DeveloperName = 'Property'
                AND Is_Published__c = true
                ORDER BY CreatedDate DESC
            ]) {
                PropertyDTO dto = new PropertyDTO();
                dto.id = acc.Id;
                dto.name = acc.Name;
                dto.propertyType = acc.Property_Type__c;
                dto.listingType = acc.Listing_Type__c;
                dto.price = acc.Price__c;
                dto.bedrooms = acc.Bedrooms__c;
                dto.bathrooms = acc.Bathrooms__c;
                dto.areaSqft = acc.Area_Sqft__c;
                dto.city = acc.BillingCity;
                dto.description = acc.Description__c;
                dto.imageUrl = acc.Property_Image_URL__c;
                results.add(dto);
            }
        } catch (Exception e) {
            ErrorLogger.logError(e, 'PropertyListingService.getPublishedProperties');
            RestContext.response.statusCode = 500;
        }

        return results;
    }
}
