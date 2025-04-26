/*
 * MIT License
 * Copyright (c) 2025 Asphalt Green, Inc.
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
/***********************************************************************
 * @description Called by trigger action, after insert.
 *  Fire a receipt event platform event when a content document link is inserted.
 * @date 2025
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