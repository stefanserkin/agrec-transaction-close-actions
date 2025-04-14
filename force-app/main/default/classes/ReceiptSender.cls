public inherited sharing class ReceiptSender {

    private static final String RECEIPT_EMAIL_TEMPLATE_NAME = 'Transaction Receipt Email';

    private static Traction_Rec_Receipt_Setting__mdt receiptSettings;
    private static EmailTemplate receiptEmailTemplate;
    private static OrgWideEmailAddress fromAddress;

    private Id recordId;
    private TREX1__Transaction__c trx;

    public ReceiptSender(Id recordId) {
        this.recordId = recordId;
        this.trx = TransactionCloseActionsSelector.getTransaction(recordId);
    }

    /**
     * Send an email with the receipt as an attachment for a given transaction
     * @return 'success'
     */
    public String send() {
        try {
            if (recordId == null || trx == null || getReceiptSettings() == null) {
                throw new TransactionCloseActionsException('Invalid parameters');
            }

            if (trx.ContentDocumentLinks.isEmpty()) {
                throw new TransactionCloseActionsException('No receipt found.');
            }

            Messaging.SingleEmailMessage email = constructEmailMessage();
            email.setFileAttachments( constructEmailAttachments() );
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });

            return 'success';
        } catch (Exception e) {
            throw new TransactionCloseActionsException(e.getMessage());
        }
    }

    private Messaging.SingleEmailMessage constructEmailMessage() {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setTemplateId( getReceiptEmailTemplateId() );
        email.setTargetObjectId(trx.TREX1__Contact__c);
        email.setWhatId(trx.Id);
        email.setSaveAsActivity(true);
        email.setUseSignature(false);
        if (getFromAddress() != null) {
            email.setOrgWideEmailAddressId( getFromAddress().Id );
        }
        return email;
    }

    private List<Messaging.EmailFileAttachment> constructEmailAttachments() {
        if (trx.ContentDocumentLinks.isEmpty()) {
            throw new TransactionCloseActionsException('No receipt found.');
        }
        ContentDocumentLink cdl = trx.ContentDocumentLinks[0];

        List<ContentVersion> contentVersions = [
            SELECT VersionData, FileExtension, ContentDocument.Title
              FROM ContentVersion 
             WHERE ContentDocumentId = :cdl.ContentDocumentId
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