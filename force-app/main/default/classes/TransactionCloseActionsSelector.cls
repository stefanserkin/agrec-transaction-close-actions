public with sharing class TransactionCloseActionsSelector {

    private static final String RECEIPT_PREFIX = 'receipt-%';
    
    public static TREX1__Transaction__c getTransaction(String transactionId) {
        List<TREX1__Transaction__c> trxs = [
            SELECT Id, TREX1__Status__c, TREX1__Payment_Complete__c, TREX1__Account__c, TREX1__Contact__c, TREX1__Contact__r.Email,
                   (SELECT ContentDocumentId 
                      FROM ContentDocumentLinks
                     WHERE ContentDocument.Title LIKE :RECEIPT_PREFIX)
              FROM TREX1__Transaction__c
             WHERE Id = :transactionId
              WITH USER_MODE
             LIMIT 1
        ];

        if (trxs.isEmpty()) {
            throw new TransactionCloseActionsException('No transaction found with Id ' + transactionId);
        }

        return trxs[0];
    }

}