public with sharing class TA_CDL_PublishReceiptEventAI implements agrec.TriggerAction.AfterInsert {
    
    public void afterInsert(List<ContentDocumentLink> newList) {
        System.debug('::::: WE HAVE CONNECTION!!!!!');
    }

}