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