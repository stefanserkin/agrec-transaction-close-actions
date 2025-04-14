public with sharing class ReceiptSender {

    private static final String RECEIPT_EMAIL_TEMPLATE_NAME = 'Transaction Receipt Email';

    private static Traction_Rec_Receipt_Setting__mdt receiptSettings;
    private static EmailTemplate receiptEmailTemplate;
    private static OrgWideEmailAddress fromAddress;

    /**
     * Send an email with the receipt as an attachment for a given transaction
     * @param recordId - Transaction record id
     * @param toAddress - Email address to send receipt to
     * @return 'success'
     */
    @AuraEnabled(cacheable=false)
    public static String send(Id recordId, String toAddress) {
        try {
            if (recordId == null || toAddress == null || getReceiptSettings() == null) {
                throw new AuraHandledException('Invalid parameters');
            }

            TREX1__Transaction__c trx = TransactionCloseActionsSelector.getTransaction(recordId);

            if (trx.ContentDocumentLinks.isEmpty()) {
                throw new AuraHandledException('No receipt found.');
            }

            ContentDocumentLink cdl = trx.ContentDocumentLinks[0];

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ toAddress });
            email.setTemplateId( getReceiptEmailTemplateId() );
            email.setTargetObjectId(trx.TREX1__Contact__c);
            email.setWhatId(trx.Id);
            email.setSaveAsActivity(true);
            email.setUseSignature(false);
            email.setFileAttachments( constructEmailAttachments(cdl.ContentDocumentId) );

            if (getFromAddress() != null) {
                email.setOrgWideEmailAddressId( getFromAddress().Id );
            }

            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });

            return 'success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static List<Messaging.EmailFileAttachment> constructEmailAttachments(Id contentDocumentId) {
        List<ContentVersion> contentVersions = [
            SELECT VersionData, FileExtension, ContentDocument.Title
              FROM ContentVersion 
             WHERE ContentDocumentId = :contentDocumentId
               AND IsLatest = true
              WITH USER_MODE
        ];

        if (contentVersions.isEmpty()) {
            throw new AuraHandledException('No receipt found.');
        }

        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        String fileName = !String.isBlank(getReceiptSettings().File_Name__c)
                          ? getReceiptSettings().File_Name__c + '.' + contentVersions[0].FileExtension
                          : contentVersions[0].ContentDocument.Title;
        attach.setFilename(fileName);
        attach.setBody(contentVersions[0].VersionData);
        return new List<Messaging.EmailFileAttachment>{attach};
    }

    private static Traction_Rec_Receipt_Setting__mdt getReceiptSettings() {
        if (receiptSettings == null) {
            receiptSettings = Traction_Rec_Receipt_Setting__mdt.getAll()?.values().get(0);
        }
        return receiptSettings;
    }

    private static OrgWideEmailAddress getFromAddress() {
        String emailAddress = getReceiptSettings().From_Address__c;
        if (String.isBlank(emailAddress)) {
            return new OrgWideEmailAddress();
        }

        if (fromAddress == null) {
            List<OrgWideEmailAddress> addresses = [
                SELECT Id 
                  FROM OrgWideEmailAddress 
                 WHERE Address = :emailAddress
                  WITH USER_MODE
                 LIMIT 1
            ];
            if (!addresses.isEmpty()) {
                fromAddress = addresses[0];
            }
        }
        return fromAddress;
    }

    private static Id getReceiptEmailTemplateId() {
        String emailTemplateName = getReceiptSettings().Email_Template_Name__c;
        if (receiptEmailTemplate == null) {
            receiptEmailTemplate = [
                SELECT Id, Subject, HtmlValue 
                  FROM EmailTemplate 
                 WHERE Name = :emailTemplateName
                  WITH SYSTEM_MODE
                 LIMIT 1
            ];
        }
        return receiptEmailTemplate.Id;
    }

}