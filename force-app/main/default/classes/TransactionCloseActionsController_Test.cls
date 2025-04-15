@IsTest
private class TransactionCloseActionsController_Test {
    
    @IsTest
    static void testGetTransaction() {
        Contact ct = agrec.TestDataFactory.createContacts(1).get(0);
        insert ct;

        TREX1__Transaction__c trx = agrec.TestDataFactory.createTransaction(ct.Id);
        insert trx;

        Test.startTest();
        TREX1__Transaction__c result = TransactionCloseActionsController.getTransaction(trx.Id);
        Test.stopTest();

        System.Assert.areEqual(trx.Id, result.Id, 'Should have received the original transaction');
    }

    @IsTest
    static void testTransactionNotFound() {
        Id invalidId = agrec.TriggerTestUtility.getFakeId(TREX1__Transaction__c.SObjectType);
        Test.startTest();
        try {
            TREX1__Transaction__c result = TransactionCloseActionsController.getTransaction(invalidId);
            System.Assert.fail('Should have received an exception for no transaction found');
        } catch (Exception e) {
            System.Assert.isNotNull(e.getMessage(), 'Should have received an exception message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testSendReceipt() {
        Contact ct = agrec.TestDataFactory.createContacts(1).get(0);
        insert ct;

        TREX1__Transaction__c trx = agrec.TestDataFactory.createTransaction(ct.Id);
        insert trx;

        List<ContentDocumentLink> cdls = agrec.TestDataFactory.createReceipts(new List<SObject>{trx});
        insert cdls;

        Test.startTest();
        String result = TransactionCloseActionsController.sendReceipt(trx.Id);
        System.Assert.areEqual('success', result, 'Should have received a successful send result');
        Test.stopTest();
    }

    @IsTest
    static void testSendReceiptWithException() {
        Id fakeId = agrec.TriggerTestUtility.getFakeId(TREX1__Transaction__c.SObjectType);

        Test.startTest();
        try {
            String result = TransactionCloseActionsController.sendReceipt(fakeId);
            System.Assert.fail('Should have received an exception for no transaction found');
        } catch (Exception e) {
            System.Assert.isNotNull(e.getMessage(), 'Should have received an exception message');
        }
        Test.stopTest();
    }

}