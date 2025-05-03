/***********************************************************************
 * @license
 * MIT License
 * Copyright (c) 2025 Asphalt Green, Inc.
 * See the LICENSE file in the project root for full license text.
 * 
 * @description 
 * Called by trigger action, after insert.
 * Fire a receipt event platform event when a content document link is inserted.
 * 
 * @date 2025
 * @author
 * Asphalt Green Data and Information Systems
 ***********************************************************************/
@NamespaceAccessible
public with sharing class TA_CDL_PublishReceiptEventAI implements agrec.TriggerAction.AfterInsert {

    private static final String EVENT_TYPE_RECEIPT = 'Receipt';

    @TestVisible
    private List<Database.SaveResult> saveResults = new List<Database.SaveResult>();
    private Map<Id, Transaction_Close_Event__e> closeEventsByTransactionId;

    private List<ContentDocumentLink> newList;
    
    @NamespaceAccessible
    public void afterInsert(List<ContentDocumentLink> newList) {
        this.newList = newList;
        saveResults = EventBus.publish( buildEvents().values() );
    }

    private Map<Id, Transaction_Close_Event__e> buildEvents() {
        closeEventsByTransactionId = new Map<Id, Transaction_Close_Event__e>();
        for (ContentDocumentLink cdl : newList) {
            closeEventsByTransactionId.put(cdl.LinkedEntityId, createReceiptEvent(cdl.LinkedEntityId));
        }
        return closeEventsByTransactionId;
    }

    private static Transaction_Close_Event__e createReceiptEvent(Id transactionId) {
        Transaction_Close_Event__e event = new Transaction_Close_Event__e();
        event.Record_ID__c = transactionId;
        event.Type__c = EVENT_TYPE_RECEIPT;
        return event;
    }

}