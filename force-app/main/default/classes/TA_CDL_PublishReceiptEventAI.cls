@NamespaceAccessible
public with sharing class TA_CDL_PublishReceiptEventAI implements agrec.TriggerAction.AfterInsert {

    @TestVisible
    private List<Database.SaveResult> saveResults;

    private Map<Id, Transaction_Close_Event__e> closeEventsByTransactionId;
    
    public void afterInsert(List<ContentDocumentLink> newList) {
        closeEventsByTransactionId = new Map<Id, Transaction_Close_Event__e>();

        List<Transaction_Close_Event__e> events = new List<Transaction_Close_Event__e>();
        for (ContentDocumentLink cdl : newList) {
            closeEventsByTransactionId.put(cdl.LinkedEntityId, createReceiptEvent(cdl.LinkedEntityId));
        }
        saveResults = EventBus.publish(closeEventsByTransactionId.values());
    }

    private static Transaction_Close_Event__e createReceiptEvent(Id transactionId) {
        Transaction_Close_Event__e event = new Transaction_Close_Event__e();
        event.Record_ID__c = transactionId;
        event.Type__c = 'Receipt';
        return event;
    }

}