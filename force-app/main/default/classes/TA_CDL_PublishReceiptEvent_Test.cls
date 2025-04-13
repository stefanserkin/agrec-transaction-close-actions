@IsTest
private class TA_CDL_PublishReceiptEvent_Test {
    
    @IsTest
    static void testPublishReceiptEvent() {
        TA_CDL_PublishReceiptEventAI ta = new TA_CDL_PublishReceiptEventAI();
        ta.afterInsert(new List<ContentDocumentLink>());
    }

}