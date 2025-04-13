@IsTest
private class TA_CDL_PublishReceiptEvent_Test {
    
    @IsTest
    static void testPublishReceiptEvent() {
        Id fakeAccountId = agrec.TriggerTestUtility.getFakeId(Account.SObjectType);
        ContentDocumentLink cdl = getContentDocumentLink(fakeAccountId);

        TA_CDL_PublishReceiptEventAI ta = new TA_CDL_PublishReceiptEventAI();
        Test.startTest();
        ta.afterInsert( new List<ContentDocumentLink>{cdl} );
        Test.stopTest();

        List<Database.SaveResult> saveResults = ta.saveResults;
        System.Assert.areEqual(1, saveResults.size(), 'Should have received a single save result');
        System.Assert.isTrue(saveResults[0].isSuccess(), 'Should have successfully published the event');
    }

    private static ContentDocumentLink getContentDocumentLink(Id linkedEntityId) {
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = linkedEntityId;
        cdl.ShareType = 'I';
        cdl.ContentDocumentId = agrec.TriggerTestUtility.getFakeId(ContentDocument.SObjectType);
        cdl.Visibility = 'AllUsers';
        return cdl;
    }

}