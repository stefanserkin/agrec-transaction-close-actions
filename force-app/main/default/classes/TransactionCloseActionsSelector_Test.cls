@IsTest
private class TransactionCloseActionsSelector_Test {
    
    @IsTest
    static void testGetTransaction() {
        Contact ct = agrec.TestDataFactory.createContacts(1).get(0);
        insert ct;

        TREX1__Transaction__c trx = agrec.TestDataFactory.createTransaction(ct.Id);
        insert trx;

        Test.startTest();
        TREX1__Transaction__c result = TransactionCloseActionsSelector.getTransaction(trx.Id);
        Test.stopTest();

        System.Assert.areEqual(trx.Id, result.Id, 'Should have received the original transaction');
    }

    @IsTest
    static void testTransactionNotFound() {
        Id invalidId = agrec.TriggerTestUtility.getFakeId(TREX1__Transaction__c.SObjectType);
        Test.startTest();
        try {
            TREX1__Transaction__c result = TransactionCloseActionsSelector.getTransaction(invalidId);
            System.Assert.fail('Should have received an exception for no transaction found');
        } catch (Exception e) {
            String exceptionMessage = 'No transaction found with Id ';
            System.Assert.isTrue(e.getMessage().startsWith(exceptionMessage), 'Received unexpected exception');
            System.Assert.isTrue(e.getMessage().contains(String.valueOf(invalidId)), 'Exception should include the record id');
        }
        Test.stopTest();
    }

}