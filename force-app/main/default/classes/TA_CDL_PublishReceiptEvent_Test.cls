@IsTest
private class TA_CDL_PublishReceiptEvent_Test {
    
    @IsTest
    static void testPublishReceiptEvent() {
        Id accountId = agrec.TriggerTestUtility.getFakeId(Account.SObjectType);
        Id contentDocumentId = agrec.TriggerTestUtility.getFakeId(ContentDocument.SObjectType);

        ContentDocumentLink cdl = agrec.TestDataFactory.createContentDocumentLink(
            accountId,
            contentDocumentId
        );

        TA_CDL_PublishReceiptEventAI ta = new TA_CDL_PublishReceiptEventAI();
        Test.startTest();
        ta.afterInsert( new List<ContentDocumentLink>{cdl} );
        Test.stopTest();

        List<Database.SaveResult> saveResults = ta.saveResults;
        System.Assert.areEqual(1, saveResults.size(), 'Should have received a single save result');
        System.Assert.isTrue(saveResults[0].isSuccess(), 'Should have successfully published the event');
    }

}