public without sharing class ErrorLogger {

    public class LogRequest {
        @InvocableVariable(label='Error Message' required=true)
        public String errorMessage;

        @InvocableVariable(label='Source')
        public String source;

        @InvocableVariable(label='Object Type')
        public String objectType;

        @InvocableVariable(label='Record Id')
        public String recordId;

        @InvocableVariable(label='Severity')
        public String severity;

        @InvocableVariable(label='Context')
        public String context;

        @InvocableVariable(label='Stack Trace')
        public String stackTrace;
    }

    @InvocableMethod(label='Log Error' description='Creates an Error Log record. Callable from Flow.')
    public static void logErrorFromFlow(List<LogRequest> requests) {
        List<Error_Log__c> logs = new List<Error_Log__c>();
        for (LogRequest req : requests) {
            logs.add(buildLog(req.errorMessage, req.stackTrace, req.source, req.objectType, req.recordId, req.severity, req.context));
        }
        insertLogs(logs);
    }

    public static void logError(String errorMessage, String stackTrace, String source, String objectType, String recordId, String severity, String context) {
        insertLogs(new List<Error_Log__c>{ buildLog(errorMessage, stackTrace, source, objectType, recordId, severity, context) });
    }

    public static void logError(Exception ex, String source) {
        logError(ex.getMessage(), ex.getStackTraceString(), source, null, null, 'High', null);
    }

    private static Error_Log__c buildLog(String errorMessage, String stackTrace, String source, String objectType,
            String recordId, String severity, String context) {
        return new Error_Log__c(
            Error_Message__c = errorMessage,
            Stack_Trace__c = stackTrace,
            Source__c = source,
            Object_Type__c = objectType,
            Record_Id__c = recordId,
            Severity__c = String.isBlank(severity) ? 'Medium' : severity,
            Context__c = context
        );
    }

    // Published as a Platform Event instead of inserted directly. An @AuraEnabled method
    // that throws an exception back to a Lightning/LWC caller makes Salesforce roll back
    // ALL DML performed during that transaction - including an Error_Log__c we just inserted
    // right before the throw. Platform Events are the documented exception to that rollback:
    // once published, they survive even if the rest of the transaction later fails.
    // A subscriber trigger (ErrorLogEventTrigger) does the actual Error_Log__c insert.
    private static void insertLogs(List<Error_Log__c> logs) {
        if (logs.isEmpty()) {
            return;
        }
        List<Error_Log_Event__e> events = new List<Error_Log_Event__e>();
        for (Error_Log__c logRecord : logs) {
            events.add(new Error_Log_Event__e(
                Error_Message__c = logRecord.Error_Message__c,
                Stack_Trace__c = logRecord.Stack_Trace__c,
                Source__c = logRecord.Source__c,
                Object_Type__c = logRecord.Object_Type__c,
                Record_Id__c = logRecord.Record_Id__c,
                Severity__c = logRecord.Severity__c,
                Context__c = logRecord.Context__c
            ));
        }

        List<Database.SaveResult> results = EventBus.publish(events);
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                System.debug(LoggingLevel.ERROR, 'ErrorLogger failed to publish Error_Log_Event__e: ' + result.getErrors());
            }
        }
    }
}
