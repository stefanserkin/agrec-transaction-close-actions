@NamespaceAccessible
public with sharing class TA_TRX_PublishCloseEventAU implements agrec.TriggerAction.AfterUpdate {

    private static final String EVENT_TYPE_CLOSE = 'Close';

    @TestVisible
    private List<Database.SaveResult> saveResults = new List<Database.SaveResult>();
    private Map<Id, Transaction_Close_Event__e> closeEventsByTransactionId;

    private List<TREX1__Transaction__c> newList;
    
    @NamespaceAccessible
    public void afterUpdate(List<TREX1__Transaction__c> newList, List<TREX1__Transaction__c> oldList) {
        System.debug(':::: fired TA_TRX_PublishCloseEventAU');
        this.newList = newList;
        saveResults = EventBus.publish( buildEvents().values() );
        System.debug('eventMap --> ' + closeEventsByTransactionId);
    }

    private Map<Id, Transaction_Close_Event__e> buildEvents() {
        closeEventsByTransactionId = new Map<Id, Transaction_Close_Event__e>();
        for (TREX1__Transaction__c trx : newList) {
            closeEventsByTransactionId.put(trx.Id, createCloseEvent(trx.Id));
        }
        return closeEventsByTransactionId;
    }

    private static Transaction_Close_Event__e createCloseEvent(Id transactionId) {
        Transaction_Close_Event__e event = new Transaction_Close_Event__e();
        event.Record_ID__c = transactionId;
        event.Type__c = EVENT_TYPE_CLOSE;
        return event;
    }

}