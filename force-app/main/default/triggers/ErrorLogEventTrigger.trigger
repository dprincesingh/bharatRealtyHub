trigger ErrorLogEventTrigger on Error_Log_Event__e (after insert) {
    List<Error_Log__c> logs = new List<Error_Log__c>();
    for (Error_Log_Event__e event : Trigger.new) {
        logs.add(new Error_Log__c(
            Error_Message__c = event.Error_Message__c,
            Stack_Trace__c = event.Stack_Trace__c,
            Source__c = event.Source__c,
            Object_Type__c = event.Object_Type__c,
            Record_Id__c = event.Record_Id__c,
            Severity__c = event.Severity__c,
            Context__c = event.Context__c
        ));
    }

    try {
        insert logs;
    } catch (Exception e) {
        System.debug(LoggingLevel.ERROR, 'ErrorLogEventTrigger failed to insert Error_Log__c records: ' + e.getMessage());
    }
}
