public with sharing class TA_TRX_PublishCloseEventAU implements agrec.TriggerAction.AfterUpdate {

    private static final String STATUS_CLOSE = 'Close';
    private static final String EVENT_TYPE_CLOSE = 'Close';

    @TestVisible
    private List<Database.SaveResult> saveResults = new List<Database.SaveResult>();

    private List<TREX1__Transaction__c> newList;
    private Map<Id, TREX1__Transaction__c> oldMap;
    private Map<Id, TREX1__Transaction__c> filteredTransactions;
    private Map<Id, Transaction_Close_Event__e> closeEventsByTransactionId;
    
    public void afterUpdate(List<TREX1__Transaction__c> newList, List<TREX1__Transaction__c> oldList) {
        this.newList = newList;
        this.oldMap = new Map<Id, TREX1__Transaction__c>(oldList);

        filterToClosedTransactions();

        if (!filteredTransactions.isEmpty()) {
            buildEvents();
            saveResults = EventBus.publish( closeEventsByTransactionId.values() );
        }
    }

    private void filterToClosedTransactions() {
        filteredTransactions = new Map<Id, TREX1__Transaction__c>();
        for (TREX1__Transaction__c trx : newList) {
            if (trx.TREX1__Status__c == STATUS_CLOSE && oldMap.get(trx.Id).TREX1__Status__c != STATUS_CLOSE) {
                filteredTransactions.add(trx.Id, trx);
            }
        }
        return filteredTransactions;
    }

    private void buildEvents() {
        closeEventsByTransactionId = new Map<Id, Transaction_Close_Event__e>();
        for (TREX1__Transaction__c trx : filteredTransactions) {
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