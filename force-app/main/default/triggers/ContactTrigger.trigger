trigger ContactTrigger on Contact (before insert, before update, after insert, after update) {
    if(Trigger.isBefore && Trigger.isInsert) {

        ContactTriggerHandler.handleDuplicateContactBeforeSave(Trigger.new);  
    }
}