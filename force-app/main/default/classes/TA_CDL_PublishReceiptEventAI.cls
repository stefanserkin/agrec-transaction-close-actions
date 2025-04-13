public with sharing class TA_CDL_PublishReceiptEventAI implements agrec.TriggerAction.AfterInsert {
    
    public void afterInsert(List<ContentDocumentLink> newList) {
        Account acc = new Account();
        acc.Name = 'WOAH IT WORKS!';
        insert acc;
    }

}