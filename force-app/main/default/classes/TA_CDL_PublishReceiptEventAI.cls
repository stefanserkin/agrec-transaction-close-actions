@NamespaceAccessible
public with sharing class TA_CDL_PublishReceiptEventAI implements agrec.TriggerAction.AfterInsert {

    @TestVisible
    private List<Database.SaveResult> saveResults;
    
    public void afterInsert(List<ContentDocumentLink> newList) {
        List<Transaction_Close_Event__e> events = new List<Transaction_Close_Event__e>();
        for (ContentDocumentLink cdl : newList) {
            Transaction_Close_Event__e event = new Transaction_Close_Event__e();
            event.Record_ID__c = cdl.LinkedEntityId;
            event.Type__c = 'Receipt';
            events.add(event);
        }
        saveResults = EventBus.publish(events);
    }

}