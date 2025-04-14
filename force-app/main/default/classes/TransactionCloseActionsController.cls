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
     * @param toAddress - Email address to send receipt to
     * @return 'success'
     */
    @AuraEnabled(cacheable=false)
    public static String sendReceipt(String recordId, String toAddress) {
        try {
            return ReceiptSender.send(recordId, toAddress);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}