public with sharing class ContactTriggerHandler {
    //Duplicate Contact 
    public static void handleDuplicateContactBeforeSave(List<Contact> newConList) {
        
        if(newConList.isEmpty()) return ; 
        
        Set<Id>accountIds = new Set<Id>();
        Set<String> emails = new Set<String>();
        
        for(Contact con : newConList){
            if(con.accountId != null && con.email !=null){
                accountIds.add(con.accountId);
                emails.add(con.email);
            }
        }
        
        if(accountIds.isEmpty() || emails.isEmpty()) return ; 
        Map<String,Contact> emailAccountIdToContactMap = new Map<String,Contact>();
        List<Contact> existingContact = [Select Id , email, accountId From Contact where AccountId in:accountIds AND email in:emails]; 
    	
        for(Contact con :existingContact){
            String key = con.email.toLowerCase()+con.AccountId;
            if(!emailAccountIdToContactMap.containsKey(key)){
                emailAccountIdToContactMap.put(key,con);
            }
        }
        for(Contact con : newConList){
            String key = con.email.toLowerCase()+con.AccountId;
            if(emailAccountIdToContactMap.containsKey(key)){
                con.addError('Duplicate contact found for the same account with the same email address.'+con.Email);
            }
        }
        

    }
}