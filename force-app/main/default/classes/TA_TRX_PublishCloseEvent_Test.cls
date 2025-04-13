@IsTest
private class TA_TRX_PublishCloseEvent_Test {
    
    @IsTest
    static void testPublishCloseEvent() {
        Id contactId = agrec.TriggerTestUtility.getFakeId(Contact.SObjectType);
        Id transactionId = agrec.TriggerTestUtility.getFakeId(TREX1__Transaction__c.SObjectType);

        TREX1__Transaction__c trx = agrec.TestDataFactory.createTransaction(contactId);
        trx.Id = transactionId;

        TA_TRX_PublishCloseEventAU ta = new TA_TRX_PublishCloseEventAU();
        Test.startTest();
        ta.afterUpdate( new List<TREX1__Transaction__c>{trx}, new List<TREX1__Transaction__c>{trx} );
        Test.stopTest();

        List<Database.SaveResult> saveResults = ta.saveResults;
        System.Assert.areEqual(1, saveResults.size(), 'Should have received a single save result');
        System.Assert.isTrue(saveResults[0].isSuccess(), 'Should have successfully published the event');
    }

}