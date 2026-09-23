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

    private static void insertLogs(List<Error_Log__c> logs) {
        try {
            insert logs;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ErrorLogger failed to insert Error_Log__c records: ' + e.getMessage());
        }
    }
}
