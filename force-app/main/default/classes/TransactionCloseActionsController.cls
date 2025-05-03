/***********************************************************************
 * @license
 * MIT License
 * Copyright (c) 2025 Asphalt Green, Inc.
 * See the LICENSE file in the project root for full license text.
 * 
 * @description 
 * Controller for the payment page transaction close actions component.
 * 
 * @date 2025
 * @author
 * Asphalt Green Data and Information Systems
 ***********************************************************************/
public with sharing class TransactionCloseActionsController {
    
    /**
     * Get transaction information with related receipt
     * @param recordId - Transaction record id
     * @return Transaction record
     */
    @AuraEnabled(cacheable=true)
    public static TREX1__Transaction__c getTransaction(String recordId) {
        try {
            return TransactionCloseActionsSelector.getTransaction(recordId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Send an email with the receipt as an attachment for a given transaction
     * @param recordId - Transaction record id
     * @return 'success'
     */
    @AuraEnabled(cacheable=false)
    public static String sendReceipt(String recordId) {
        try {
            ReceiptSender sender = new ReceiptSender(recordId);
            return sender.send();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}